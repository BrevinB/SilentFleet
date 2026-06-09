import Foundation
import GameEngine

// MARK: - Synced match payload (public information only)

/// A single action taken by a player against the opponent. The *defender*
/// (the player being shot at / scanned) resolves the move on their turn and
/// fills in the result, because only the defender knows their own fleet.
///
/// Crucially this payload — the only thing written to the shared Game Center
/// match data — never contains either player's ship positions. Ships live
/// privately on each device in `OnlineFleetStore`. The opponent's device can
/// only ever learn what its own shots and power-ups revealed.
struct OnlineMove: Codable, Equatable {
    enum Kind: Codable, Equatable {
        case shot(Coordinate)
        case sonar(center: Coordinate)
        case rowScan(row: Int)
    }

    let id: UUID
    let attackerSlot: Int
    let kind: Kind

    /// Whether the defender has adjudicated this move yet.
    var resolved: Bool

    // Filled by the defender when `kind == .shot`.
    var shotResult: ShotResult?
    /// Casual-only: the cells of a ship that was just sunk, so the attacker can
    /// render the whole hull. Omitted in ranked so ship size stays hidden.
    var sunkShipCoordinates: [Coordinate]?

    // Filled by the defender when `kind` is a power-up.
    var detected: Bool?
    var detectedCoordinates: [Coordinate]?

    init(id: UUID = UUID(), attackerSlot: Int, kind: Kind) {
        self.id = id
        self.attackerSlot = attackerSlot
        self.kind = kind
        self.resolved = false
    }

    var isShot: Bool {
        if case .shot = kind { return true }
        return false
    }

    var isPowerUp: Bool {
        switch kind {
        case .sonar, .rowScan: return true
        case .shot: return false
        }
    }
}

/// The complete shared state of an online match. Contains no ship positions.
struct OnlineMatchState: Codable, Equatable {
    static let currentVersion = 2

    var version: Int
    let mode: GameMode
    let gridSize: GridSize
    let split: BoardSplit?

    /// Reuses the engine's phase enum (`.coinFlip` is unused online).
    var phase: MatchPhase
    /// Index 0 / 1: whether each slot has committed its placement.
    var placementDone: [Bool]
    var firstPlayerIndex: Int?
    /// The slot whose turn it is per game logic; kept in sync with Game Center's
    /// `currentParticipant`.
    var currentSlot: Int
    var winnerSlot: Int?
    /// Append-only log of every move by both players.
    var moves: [OnlineMove]

    init(mode: GameMode, gridSize: GridSize, split: BoardSplit?) {
        self.version = Self.currentVersion
        self.mode = mode
        self.gridSize = gridSize
        self.split = split
        self.phase = .placement
        self.placementDone = [false, false]
        self.firstPlayerIndex = nil
        self.currentSlot = 0
        self.winnerSlot = nil
        self.moves = []
    }
}

// MARK: - Serialization

extension OnlineMatchState {
    func encoded() throws -> Data {
        try JSONEncoder().encode(self)
    }

    static func decoded(from data: Data) throws -> OnlineMatchState {
        try JSONDecoder().decode(OnlineMatchState.self, from: data)
    }
}

// MARK: - Pure queries

extension OnlineMatchState {
    var boardSize: Int { gridSize.boardSize }
    var shipCount: Int { gridSize.fleetSizes.count }

    /// Coordinates this slot has already fired at (resolved or pending), so the
    /// UI can prevent duplicate shots.
    func shotsTaken(by slot: Int) -> Set<Coordinate> {
        var taken = Set<Coordinate>()
        for move in moves where move.attackerSlot == slot {
            if case .shot(let coord) = move.kind { taken.insert(coord) }
        }
        return taken
    }

    private func powerUpsUsed(by slot: Int) -> (sonar: Int, rowScan: Int) {
        var sonar = 0
        var rowScan = 0
        for move in moves where move.attackerSlot == slot {
            switch move.kind {
            case .sonar: sonar += 1
            case .rowScan: rowScan += 1
            case .shot: break
            }
        }
        return (sonar, rowScan)
    }

    /// Power-ups this slot has left, derived from the move log (so it can't be
    /// tampered with independently of the moves themselves).
    func remainingKit(for slot: Int) -> PowerUpKit {
        let base = PowerUpKit.forMode(mode)
        let used = powerUpsUsed(by: slot)
        return PowerUpKit(
            sonarPingRemaining: max(0, base.sonarPingRemaining - used.sonar),
            rowScanRemaining: max(0, base.rowScanRemaining - used.rowScan)
        )
    }

    /// Number of opponent ships `slot` has sunk (from its own resolved shots).
    func shipsSunk(by slot: Int) -> Int {
        var count = 0
        for move in moves where move.attackerSlot == slot {
            if move.isShot, move.resolved, let result = move.shotResult, result.isSunk {
                count += 1
            }
        }
        return count
    }

    /// True if `slot` has an unresolved move waiting for the opponent to adjudicate.
    func hasPendingMove(by slot: Int) -> Bool {
        moves.contains { $0.attackerSlot == slot && !$0.resolved }
    }
}

// MARK: - Defender adjudication

extension OnlineMatchState {
    /// Resolve every pending move by `attacker` against the local player's
    /// private `defenderFleet`. Fills in results on the moves and returns the
    /// reconstructed defender board plus whether the defender has now lost.
    ///
    /// Idempotent: rebuilding the board from the fleet each call and only
    /// touching unresolved moves means re-running on an already-resolved state
    /// is a no-op.
    mutating func resolvePendingMoves(
        attacker: Int,
        defenderFleet: [Ship]
    ) -> (board: Board, defenderAllSunk: Bool) {
        var board = Board(ships: defenderFleet, boardSize: boardSize)

        // Replay already-resolved shots so prior damage is reflected.
        for move in moves where move.attackerSlot == attacker {
            if case .shot(let coord) = move.kind, move.resolved {
                _ = board.receiveShot(at: coord)
            }
        }

        // Adjudicate the unresolved ones against the live board.
        for index in moves.indices where moves[index].attackerSlot == attacker && !moves[index].resolved {
            switch moves[index].kind {
            case .shot(let coord):
                let outcome = board.receiveShot(at: coord)
                if outcome.sunk, let ship = outcome.ship {
                    // Ranked hides ship size, so don't reveal the hull.
                    moves[index].shotResult = .sunk(shipSize: mode == .ranked ? nil : ship.size)
                    if mode == .casual {
                        moves[index].sunkShipCoordinates = ship.coordinates
                    }
                } else if outcome.hit {
                    moves[index].shotResult = .hit
                } else {
                    moves[index].shotResult = .miss
                }

            case .sonar(let center):
                let area = PowerUpAction.sonarPing(center: center).affectedCoordinates(boardSize: boardSize)
                let found = area.filter { board.hasShip(at: $0) }
                moves[index].detected = !found.isEmpty
                moves[index].detectedCoordinates = found

            case .rowScan(let row):
                let area = PowerUpAction.rowScan(row: row).affectedCoordinates(boardSize: boardSize)
                moves[index].detected = board.hasShipInAny(of: area)
                moves[index].detectedCoordinates = []
            }
            moves[index].resolved = true
        }

        let allSunk = !board.ships.isEmpty && board.isAllSunk()
        return (board, allSunk)
    }

    /// Reconstruct the local player's own board (ships + damage taken so far)
    /// from their private fleet and the opponent's resolved shots.
    func reconstructBoard(forSlot slot: Int, fleet: [Ship]) -> Board {
        var board = Board(ships: fleet, boardSize: boardSize)
        let attacker = 1 - slot
        for move in moves where move.attackerSlot == attacker {
            if case .shot(let coord) = move.kind, move.resolved {
                _ = board.receiveShot(at: coord)
            }
        }
        return board
    }
}

// MARK: - Private per-device fleet storage

/// Stores each device's own ship layout locally, keyed by Game Center match ID.
/// This never leaves the device, which is what keeps the opponent from learning
/// ship positions.
enum OnlineFleetStore {
    private static func key(_ matchID: String) -> String { "online_fleet_\(matchID)" }

    static func save(_ ships: [Ship], matchID: String) {
        guard let data = try? JSONEncoder().encode(ships) else { return }
        UserDefaults.standard.set(data, forKey: key(matchID))
    }

    static func load(matchID: String) -> [Ship]? {
        guard let data = UserDefaults.standard.data(forKey: key(matchID)),
              let ships = try? JSONDecoder().decode([Ship].self, from: data) else {
            return nil
        }
        return ships
    }

    static func clear(matchID: String) {
        UserDefaults.standard.removeObject(forKey: key(matchID))
    }
}

/// Tracks which finished matches have already been recorded into career stats,
/// so a match counts exactly once even though both clients observe the finish.
enum OnlineRecordKeeper {
    private static let storeKey = "online_recorded_match_ids"

    static func hasRecorded(matchID: String) -> Bool {
        let ids = UserDefaults.standard.stringArray(forKey: storeKey) ?? []
        return ids.contains(matchID)
    }

    static func markRecorded(matchID: String) {
        var ids = UserDefaults.standard.stringArray(forKey: storeKey) ?? []
        guard !ids.contains(matchID) else { return }
        ids.append(matchID)
        // Keep the list from growing without bound.
        if ids.count > 200 { ids.removeFirst(ids.count - 200) }
        UserDefaults.standard.set(ids, forKey: storeKey)
    }
}
