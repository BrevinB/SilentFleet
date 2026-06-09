import SwiftUI
import GameKit
import GameEngine
import Combine

/// View model for a Game Center turn-based match using the private-board
/// protocol. Mirrors enough of `GameViewModel`'s surface to drive the shared
/// placement view, plus an online-specific play surface.
///
/// Turn model (necessary for hidden information): each device keeps its fleet
/// private and the *defender* resolves incoming shots/power-ups on their turn.
/// One consequence is that a shot's result, and a power-up's reading, arrive on
/// the player's *next* turn rather than instantly — so a turn is either a shot
/// **or** a power-up, never both.
@MainActor
final class OnlineGameViewModel: ObservableObject {
    enum Status: Equatable {
        case loading
        case placement
        case waitingForOpponent
        case yourTurn
        case finished
        case error(String)
    }

    @Published private(set) var status: Status = .loading
    @Published private(set) var matchState: OnlineMatchState?
    @Published private(set) var localSlot: Int = 0

    // PlacementHost surface
    @Published var placedShips: [Ship] = []
    @Published var selectedShip: Ship?
    @Published var placementOrientation: Orientation = .horizontal
    @Published var remainingFleetSizes: [Int] = []
    @Published var errorMessage: String?

    // Play surface
    @Published private(set) var localBoard: Board = Board(boardSize: GridSize.large.boardSize)
    @Published private(set) var opponentCellStates: [Coordinate: CellState] = [:]
    @Published var selectedPowerUp: PowerUpType?

    // Result feedback (deferred by one turn under the private-board model)
    @Published var lastTurnResult: TurnResult?
    @Published var lastOpponentTurnResult: TurnResult?
    @Published var lastPowerUpResult: PowerUpResult?
    @Published var showingPowerUpResult: Bool = false
    @Published var sonarPulseCoordinates: Set<Coordinate> = []
    @Published var sonarScanArea: Set<Coordinate> = []
    @Published var showingSonarPulse: Bool = false
    @Published var rowScanHighlight: Int?

    // Endgame
    @Published var coinReward: CoinReward?
    @Published var newlyUnlockedAchievements: [Achievement] = []

    var gameMode: GameMode = .casual
    var boardSplit: BoardSplit?
    var gridSize: GridSize = .large
    var currentBoardSize: Int { gridSize.boardSize }

    private var session: OnlineMatchSession?
    private var eventTask: Task<Void, Never>?
    private var creationDefaults: OnlineMatchPreferences?

    private var forfeitedLocally = false
    private var didRecord = false
    private let bannerPlayerID = UUID()
    private var lastShownMyShotID: UUID?
    private var lastShownOpponentShotID: UUID?
    private var lastShownPowerUpID: UUID?

    deinit {
        eventTask?.cancel()
    }

    // MARK: - Lifecycle

    func prepareForCreation(_ prefs: OnlineMatchPreferences) {
        creationDefaults = prefs
        gameMode = prefs.mode
        gridSize = prefs.gridSize
        boardSplit = prefs.split
        remainingFleetSizes = prefs.gridSize.fleetSizes
        placedShips = []
        selectedShip = nil
    }

    func load(match: GKTurnBasedMatch) async {
        status = .loading
        do {
            let session = try await OnlineMatchSession.load(match: match, creationDefaults: creationDefaults)
            self.session = session
            syncFromSession()
            subscribeToTurnEvents()
            await processIncomingAndFinish()
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    private func subscribeToTurnEvents() {
        eventTask?.cancel()
        let stream = GameCenterManager.shared.turnEventStream()
        eventTask = Task { [weak self] in
            for await event in stream {
                guard let self else { return }
                guard let session = self.session, event.match.matchID == session.match.matchID else { continue }
                await self.refresh(from: event.match)
            }
        }
    }

    private func refresh(from match: GKTurnBasedMatch) async {
        do {
            let session = try await OnlineMatchSession.load(match: match, creationDefaults: nil)
            self.session = session
            syncFromSession()
            await processIncomingAndFinish()
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    /// On receiving the turn, resolve the opponent's pending move(s) against our
    /// private fleet, end the match if it killed us, and refresh banners.
    private func processIncomingAndFinish() async {
        guard let session else { return }
        if session.state.phase == .inProgress, session.isLocalTurn, session.state.winnerSlot == nil {
            if session.opponentQuit {
                try? await session.finalizeOpponentQuit()
                syncFromSession()
            } else {
                let iLost = session.adjudicateIncoming()
                syncFromSession()
                if iLost {
                    try? await session.finalizeAsLoss()
                    syncFromSession()
                }
            }
        }
        updateResultBanners()
        recomputeStatus()
        if status == .finished { recordResultIfNeeded() }
    }

    // MARK: - Syncing published state

    private func syncFromSession() {
        guard let session else { return }
        let state = session.state
        matchState = state
        localSlot = session.localSlot
        gameMode = state.mode
        gridSize = state.gridSize
        boardSplit = state.split
        localBoard = session.localBoard
        opponentCellStates = computeOpponentCellStates(state, slot: session.localSlot)

        if state.placementDone[session.localSlot] {
            placedShips = session.myFleet
            remainingFleetSizes = []
        } else if placedShips.isEmpty {
            remainingFleetSizes = state.gridSize.fleetSizes
        }
    }

    private func computeOpponentCellStates(_ state: OnlineMatchState, slot: Int) -> [Coordinate: CellState] {
        var states: [Coordinate: CellState] = [:]
        for move in state.moves where move.attackerSlot == slot {
            guard case .shot(let coord) = move.kind, move.resolved, let result = move.shotResult else { continue }
            if result.isSunk {
                states[coord] = .sunk
                for sunkCoord in (move.sunkShipCoordinates ?? []) { states[sunkCoord] = .sunk }
            } else if result.isHit {
                states[coord] = .hit
            } else {
                states[coord] = .miss
            }
        }
        return states
    }

    private func recomputeStatus() {
        guard let session, let state = matchState else { status = .loading; return }
        if forfeitedLocally || state.phase == .finished || state.winnerSlot != nil {
            status = .finished
            return
        }
        if !state.placementDone[session.localSlot] {
            status = session.isLocalTurn ? .placement : .waitingForOpponent
            return
        }
        status = session.isLocalTurn ? .yourTurn : .waitingForOpponent
    }

    // MARK: - Result banners (deferred feedback)

    private func updateResultBanners() {
        guard let session, let state = matchState else { return }
        let me = session.localSlot
        let opp = 1 - me

        if let move = state.moves.last(where: { $0.attackerSlot == me && $0.isShot && $0.resolved }),
           case .shot(let coord) = move.kind, let result = move.shotResult {
            lastTurnResult = TurnResult(powerUpResult: nil, shotCoordinate: coord, shotResult: result, playerID: bannerPlayerID, turnNumber: 0)
            if move.id != lastShownMyShotID {
                lastShownMyShotID = move.id
                triggerShotHaptic(for: result)
            }
        }

        if let move = state.moves.last(where: { $0.attackerSlot == opp && $0.isShot && $0.resolved }),
           case .shot(let coord) = move.kind, let result = move.shotResult {
            lastOpponentTurnResult = TurnResult(powerUpResult: nil, shotCoordinate: coord, shotResult: result, playerID: bannerPlayerID, turnNumber: 0)
            if move.id != lastShownOpponentShotID {
                lastShownOpponentShotID = move.id
                triggerIncomingHaptic(for: result)
            }
        }

        if let move = state.moves.last(where: { $0.attackerSlot == me && $0.isPowerUp && $0.resolved }),
           move.id != lastShownPowerUpID {
            lastShownPowerUpID = move.id
            presentPowerUpResult(for: move)
        }
    }

    private func presentPowerUpResult(for move: OnlineMove) {
        let action: PowerUpAction
        switch move.kind {
        case .sonar(let center): action = .sonarPing(center: center)
        case .rowScan(let row): action = .rowScan(row: row)
        case .shot: return
        }
        let result = PowerUpResult(
            action: action,
            detected: move.detected ?? false,
            detectedCoordinates: move.detectedCoordinates ?? []
        )
        lastPowerUpResult = result

        switch action {
        case .sonarPing:
            sonarScanArea = Set(action.affectedCoordinates(boardSize: currentBoardSize))
            sonarPulseCoordinates = Set(result.detectedCoordinates)
            showingSonarPulse = true
            HapticManager.shared.sonarPing()
            SoundManager.shared.sonarPing()
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(2.5))
                self?.showingSonarPulse = false
                self?.sonarPulseCoordinates = []
                self?.sonarScanArea = []
            }
        case .rowScan(let row):
            rowScanHighlight = row
            showingPowerUpResult = true
            HapticManager.shared.sonarPing()
            SoundManager.shared.rowScan()
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(3))
                self?.rowScanHighlight = nil
            }
        }
    }

    // MARK: - Computed views

    var winnerLabel: String? {
        if forfeitedLocally { return "You Forfeited" }
        guard let state = matchState, let winner = state.winnerSlot else { return nil }
        return winner == localSlot ? "You Win!" : "Opponent Wins"
    }

    var didWinMatch: Bool {
        guard !forfeitedLocally, let state = matchState, let winner = state.winnerSlot else { return false }
        return winner == localSlot
    }

    var opponentDisplayName: String {
        session?.opponentDisplayName ?? "Opponent"
    }

    var availablePowerUps: [PowerUpType] {
        guard status == .yourTurn, let state = matchState else { return [] }
        return state.remainingKit(for: localSlot).availableTypes
    }

    var remainingKit: PowerUpKit? {
        matchState?.remainingKit(for: localSlot)
    }

    var opponentShipsSunk: Int { matchState?.shipsSunk(by: localSlot) ?? 0 }
    var totalShips: Int { matchState?.shipCount ?? gridSize.fleetSizes.count }

    /// True while our shot/power-up is sent but the opponent hasn't adjudicated yet.
    var awaitingResult: Bool {
        guard status == .waitingForOpponent, let state = matchState, state.phase == .inProgress else { return false }
        return state.hasPendingMove(by: localSlot)
    }

    // MARK: - Placement (PlacementHost)

    func selectShipSize(_ size: Int) {
        guard remainingFleetSizes.contains(size) else { return }
        selectedShip = Ship(size: size, origin: Coordinate(row: 0, col: 0), orientation: placementOrientation)
    }

    func toggleOrientation() {
        placementOrientation = placementOrientation == .horizontal ? .vertical : .horizontal
        if let ship = selectedShip {
            selectedShip = Ship(size: ship.size, origin: ship.origin, orientation: placementOrientation)
        }
    }

    func canPlaceShip(at coordinate: Coordinate) -> Bool {
        guard let selected = selectedShip else { return false }
        let test = Ship(size: selected.size, origin: coordinate, orientation: placementOrientation)
        guard test.isWithinBounds(boardSize: currentBoardSize) else { return false }
        if case .success = PlacementValidator.canPlace(ship: test, on: placedShips, boardSize: currentBoardSize) {
            return true
        }
        return false
    }

    func placeShip(at coordinate: Coordinate) -> Bool {
        guard let selected = selectedShip else { return false }
        let newShip = Ship(size: selected.size, origin: coordinate, orientation: placementOrientation)
        let result = PlacementValidator.canPlace(ship: newShip, on: placedShips, boardSize: currentBoardSize)
        switch result {
        case .success:
            placedShips.append(newShip)
            if let index = remainingFleetSizes.firstIndex(of: newShip.size) {
                remainingFleetSizes.remove(at: index)
            }
            HapticManager.shared.shipPlaced()
            SoundManager.shared.shipPlaced()
            selectedShip = nil
            return true
        case .failure(let error):
            HapticManager.shared.invalidPlacement()
            SoundManager.shared.invalidPlacement()
            errorMessage = error.localizedDescription
            return false
        }
    }

    func removeShip(_ ship: Ship) {
        placedShips.removeAll { $0.id == ship.id }
        remainingFleetSizes.append(ship.size)
        remainingFleetSizes.sort(by: >)
    }

    func autoPopulateShips() {
        let ships = RandomPlacement().generatePlacement(
            for: gridSize.fleetSizes,
            mode: gameMode,
            splitOrientation: boardSplit,
            boardSize: gridSize.boardSize
        )
        placedShips = ships
        remainingFleetSizes = []
        selectedShip = nil
        HapticManager.shared.shipPlaced()
        SoundManager.shared.shipPlaced()
    }

    @discardableResult
    func commitPlacement() async -> Bool {
        guard let session else { return false }
        let validation = PlacementValidator.validate(
            ships: placedShips,
            mode: gameMode,
            splitOrientation: boardSplit,
            gridSize: gridSize
        )
        if case .failure(let error) = validation {
            errorMessage = error.localizedDescription
            return false
        }
        do {
            try await session.commitPlacement(fleet: placedShips)
            syncFromSession()
            recomputeStatus()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Play actions (each is one turn)

    func fireShot(at coordinate: Coordinate) async {
        guard let session, status == .yourTurn else { return }
        guard !session.state.shotsTaken(by: localSlot).contains(coordinate) else { return }
        SoundManager.shared.shotFired()
        do {
            try await session.makeShot(at: coordinate)
            syncFromSession()
            recomputeStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func usePowerUp(_ type: PowerUpType, at coordinate: Coordinate) async {
        guard let session, status == .yourTurn else { return }
        guard session.state.remainingKit(for: localSlot).isAvailable(type) else {
            errorMessage = "No \(type == .sonarPing ? "Sonar" : "Row Scan") remaining"
            return
        }
        do {
            switch type {
            case .sonarPing: try await session.makeSonar(center: coordinate)
            case .rowScan: try await session.makeRowScan(row: coordinate.row)
            }
            selectedPowerUp = nil
            syncFromSession()
            recomputeStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectPowerUp(_ type: PowerUpType?) {
        selectedPowerUp = type
    }

    func forfeit() async {
        guard let session else { return }
        let wasMyTurn = session.isLocalTurn
        do {
            try await session.forfeit()
            if !wasMyTurn { forfeitedLocally = true }
            syncFromSession()
            recomputeStatus()
            if status == .finished { recordResultIfNeeded() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Result recording

    private func recordResultIfNeeded() {
        guard let session, let state = matchState, !didRecord else { return }
        let didWin: Bool
        if forfeitedLocally {
            didWin = false
        } else if let winner = state.winnerSlot {
            didWin = (winner == localSlot)
        } else {
            return
        }

        // Count this match exactly once across both clients / relaunches.
        if OnlineRecordKeeper.hasRecorded(matchID: session.match.matchID) {
            didRecord = true
            OnlineFleetStore.clear(matchID: session.match.matchID)
            return
        }
        didRecord = true
        OnlineRecordKeeper.markRecorded(matchID: session.match.matchID)

        let recording = buildRecordingState(state: state, fleet: session.myFleet, didWin: didWin)
        newlyUnlockedAchievements = PlayerStats.shared.recordGame(recording)
        let streak = PlayerStats.shared.currentWinStreak
        coinReward = CoinManager.awardCoins(for: recording, streak: streak)

        if didWin {
            HapticManager.shared.gameWon()
            SoundManager.shared.gameWon()
        } else {
            HapticManager.shared.gameLost()
            SoundManager.shared.gameLost()
        }
        OnlineFleetStore.clear(matchID: session.match.matchID)
    }

    /// Build a solo-shaped `GameState` from the local perspective so the
    /// existing `PlayerStats.recordGame` / `CoinManager` paths apply unchanged.
    private func buildRecordingState(state: OnlineMatchState, fleet: [Ship], didWin: Bool) -> GameState {
        let boardSize = state.boardSize
        let myBoard = state.reconstructBoard(forSlot: localSlot, fleet: fleet)
        let myKit = state.remainingKit(for: localSlot)
        let me = Player(isHuman: true, board: myBoard, powerUpKit: myKit)

        // Synthesize the opponent's board so its sunk count matches what we sank.
        let sunkByMe = state.shipsSunk(by: localSlot)
        let shipCount = state.shipCount
        var oppShips: [Ship] = []
        for index in 0..<shipCount {
            oppShips.append(Ship(size: 1, origin: Coordinate(row: index % boardSize, col: 0), orientation: .horizontal))
        }
        var oppBoard = Board(ships: oppShips, boardSize: boardSize)
        for index in 0..<min(sunkByMe, shipCount) {
            _ = oppBoard.receiveShot(at: Coordinate(row: index % boardSize, col: 0))
        }
        let opponent = Player(isHuman: false, board: oppBoard, powerUpKit: .forMode(state.mode))

        var recording = GameState(
            mode: state.mode,
            aiDifficulty: nil,
            gridSize: state.gridSize,
            player1: me,
            player2: opponent,
            rankedSplitOrientation: state.split
        )

        var history: [TurnResult] = []
        var turn = 1
        for move in state.moves where move.attackerSlot == localSlot {
            if case .shot(let coord) = move.kind, move.resolved, let result = move.shotResult {
                history.append(TurnResult(
                    powerUpResult: nil,
                    shotCoordinate: coord,
                    shotResult: result,
                    playerID: me.id,
                    turnNumber: turn
                ))
                turn += 1
            }
        }
        recording.turnHistory = history
        recording.setWinner(didWin ? me.id : opponent.id)
        return recording
    }

    // MARK: - Haptics

    private func triggerShotHaptic(for result: ShotResult) {
        switch result {
        case .miss: HapticManager.shared.miss(); SoundManager.shared.miss()
        case .hit: HapticManager.shared.hit(); SoundManager.shared.hit()
        case .sunk: HapticManager.shared.sunk(); SoundManager.shared.sunk()
        }
    }

    private func triggerIncomingHaptic(for result: ShotResult) {
        switch result {
        case .miss: SoundManager.shared.miss()
        case .hit: HapticManager.shared.hit(); SoundManager.shared.hit()
        case .sunk: HapticManager.shared.sunk(); SoundManager.shared.sunk()
        }
    }

    // MARK: - Helpers

    func dismissError() { errorMessage = nil }
    func dismissPowerUpResult() { showingPowerUpResult = false }
}

extension OnlineGameViewModel: PlacementHost {}

/// Captured before matchmaker presentation, used to seed a freshly-created match.
struct OnlineMatchPreferences: Equatable {
    var mode: GameMode = .casual
    var gridSize: GridSize = .large
    var split: BoardSplit? = nil
}
