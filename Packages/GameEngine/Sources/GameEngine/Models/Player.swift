import Foundation

/// Represents a player in the game (human or AI)
public struct Player: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let isHuman: Bool
    public var board: Board
    public var powerUpKit: PowerUpKit

    public init(
        id: UUID = UUID(),
        isHuman: Bool,
        board: Board = Board(),
        powerUpKit: PowerUpKit
    ) {
        self.id = id
        self.isHuman = isHuman
        self.board = board
        self.powerUpKit = powerUpKit
    }

    /// Create a human player with the appropriate power-up kit for the game mode
    public static func human(mode: GameMode, boardSize: Int = Board.size) -> Player {
        Player(
            isHuman: true,
            board: Board(boardSize: boardSize),
            powerUpKit: .forMode(mode)
        )
    }

    /// Create an AI player with the appropriate power-up kit for the game mode
    public static func ai(mode: GameMode, boardSize: Int = Board.size) -> Player {
        Player(
            isHuman: false,
            board: Board(boardSize: boardSize),
            powerUpKit: .forMode(mode)
        )
    }

    /// Check if this player has lost (all ships sunk)
    public var hasLost: Bool {
        board.isAllSunk() && !board.ships.isEmpty
    }

    /// Check if placement is complete for a given grid size
    public func hasCompletedPlacement(for gridSize: GridSize) -> Bool {
        board.ships.count == gridSize.fleetSizes.count
    }

    /// Check if placement is complete (classic 10x10)
    public var hasCompletedPlacement: Bool {
        board.ships.count == Board.fleetSizes.count
    }
}
