import Foundation

/// Current phase of the match
public enum MatchPhase: String, Codable, Sendable {
    case placement      // Players are placing ships
    case coinFlip       // Ranked: waiting for coin flip to determine first player
    case inProgress     // Active gameplay
    case finished       // Game over
}

/// Complete game state, fully serializable for persistence and future network play
public struct GameState: Codable, Equatable, Sendable, Identifiable {
    // MARK: - Identity & Configuration

    public let id: UUID
    public let mode: GameMode
    public let aiDifficulty: AIDifficulty?
    public let gridSize: GridSize
    public let createdAt: Date

    // MARK: - Players

    public var player1: Player  // Always human in solo mode
    public var player2: Player  // AI in solo mode, human in multiplayer

    // MARK: - Game Progress

    public var phase: MatchPhase
    public var currentPlayerIndex: Int  // 0 = player1, 1 = player2
    public var turnNumber: Int

    // MARK: - Ranked-specific

    /// Index of the player who goes first (set after coin flip in ranked)
    public var firstPlayerIndex: Int?

    /// Board split orientation for ranked placement constraint
    public var rankedSplitOrientation: BoardSplit?

    // MARK: - History & Result

    public var turnHistory: [TurnResult]
    public var winner: UUID?

    // MARK: - Computed Board Config

    /// The board dimensions for this game
    public var boardDimension: Int {
        gridSize.boardSize
    }

    /// The fleet sizes for this game
    public var fleetSizes: [Int] {
        gridSize.fleetSizes
    }

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        mode: GameMode,
        aiDifficulty: AIDifficulty?,
        gridSize: GridSize = .large,
        player1: Player,
        player2: Player,
        rankedSplitOrientation: BoardSplit? = nil
    ) {
        self.id = id
        self.mode = mode
        self.aiDifficulty = aiDifficulty
        self.gridSize = gridSize
        self.createdAt = Date()
        self.player1 = player1
        self.player2 = player2
        self.phase = .placement
        self.currentPlayerIndex = 0
        self.turnNumber = 1
        self.firstPlayerIndex = nil
        self.rankedSplitOrientation = rankedSplitOrientation
        self.turnHistory = []
        self.winner = nil
    }

    /// Convenience initializer for solo game against AI
    public static func soloGame(
        mode: GameMode,
        aiDifficulty: AIDifficulty,
        gridSize: GridSize = .large,
        rankedSplitOrientation: BoardSplit? = nil
    ) -> GameState {
        let boardSize = gridSize.boardSize
        GameState(
            mode: mode,
            aiDifficulty: aiDifficulty,
            gridSize: gridSize,
            player1: .human(mode: mode, boardSize: boardSize),
            player2: .ai(mode: mode, boardSize: boardSize),
            rankedSplitOrientation: rankedSplitOrientation
        )
    }

    // MARK: - Computed Properties

    /// The player whose turn it is
    public var currentPlayer: Player {
        currentPlayerIndex == 0 ? player1 : player2
    }

    /// The opponent of the current player
    public var opponent: Player {
        currentPlayerIndex == 0 ? player2 : player1
    }

    /// Get player by index (0 or 1)
    public func player(at index: Int) -> Player {
        index == 0 ? player1 : player2
    }

    /// Get player by ID
    public func player(withID id: UUID) -> Player? {
        if player1.id == id { return player1 }
        if player2.id == id { return player2 }
        return nil
    }

    /// Index of player with given ID
    public func playerIndex(for id: UUID) -> Int? {
        if player1.id == id { return 0 }
        if player2.id == id { return 1 }
        return nil
    }

    /// Whether the game is over
    public var isGameOver: Bool {
        phase == .finished
    }

    /// Whether it's currently the first player's first turn (for ranked power-up restriction)
    public var isFirstPlayerFirstTurn: Bool {
        guard mode == .ranked,
              let firstIdx = firstPlayerIndex,
              currentPlayerIndex == firstIdx,
              turnNumber == 1 else {
            return false
        }
        return true
    }

    /// Whether the current player can use power-ups this turn
    public var currentPlayerCanUsePowerUps: Bool {
        // In ranked, first player cannot use power-ups on turn 1
        if isFirstPlayerFirstTurn {
            return false
        }
        return true
    }

    // MARK: - Mutations

    /// Update player at index
    public mutating func setPlayer(_ player: Player, at index: Int) {
        if index == 0 {
            player1 = player
        } else {
            player2 = player
        }
    }

    /// Advance to next player's turn
    public mutating func advanceTurn() {
        currentPlayerIndex = 1 - currentPlayerIndex
        // Increment turn number when player 1 starts their turn (after both have gone)
        if currentPlayerIndex == 0 {
            turnNumber += 1
        }
    }

    /// Record turn result in history
    public mutating func recordTurn(_ result: TurnResult) {
        turnHistory.append(result)
    }

    /// Set the winner and end the game
    public mutating func setWinner(_ playerID: UUID) {
        winner = playerID
        phase = .finished
    }
}

// MARK: - Custom Decodable for backward compatibility

extension GameState {
    private enum CodingKeys: String, CodingKey {
        case id, mode, aiDifficulty, gridSize, createdAt
        case player1, player2, phase, currentPlayerIndex, turnNumber
        case firstPlayerIndex, rankedSplitOrientation, turnHistory, winner
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        mode = try container.decode(GameMode.self, forKey: .mode)
        aiDifficulty = try container.decodeIfPresent(AIDifficulty.self, forKey: .aiDifficulty)
        gridSize = try container.decodeIfPresent(GridSize.self, forKey: .gridSize) ?? .large
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        player1 = try container.decode(Player.self, forKey: .player1)
        player2 = try container.decode(Player.self, forKey: .player2)
        phase = try container.decode(MatchPhase.self, forKey: .phase)
        currentPlayerIndex = try container.decode(Int.self, forKey: .currentPlayerIndex)
        turnNumber = try container.decode(Int.self, forKey: .turnNumber)
        firstPlayerIndex = try container.decodeIfPresent(Int.self, forKey: .firstPlayerIndex)
        rankedSplitOrientation = try container.decodeIfPresent(BoardSplit.self, forKey: .rankedSplitOrientation)
        turnHistory = try container.decode([TurnResult].self, forKey: .turnHistory)
        winner = try container.decodeIfPresent(UUID.self, forKey: .winner)
    }
}

// MARK: - Codable Serialization Helpers

extension GameState {
    /// Encode to JSON data
    public func encode() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    /// Decode from JSON data
    public static func decode(from data: Data) throws -> GameState {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(GameState.self, from: data)
    }
}
