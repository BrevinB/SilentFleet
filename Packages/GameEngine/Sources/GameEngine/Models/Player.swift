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
    public static func human(mode: GameMode) -> Player {
        Player(
            isHuman: true,
            powerUpKit: .forMode(mode)
        )
    }

    /// Create an AI player with the appropriate power-up kit for the game mode
    public static func ai(mode: GameMode) -> Player {
        Player(
            isHuman: false,
            powerUpKit: .forMode(mode)
        )
    }

    /// Check if this player has lost (all ships sunk)
    public var hasLost: Bool {
        board.isAllSunk() && !board.ships.isEmpty
    }

    /// Check if placement is complete
    public var hasCompletedPlacement: Bool {
        board.ships.count == Board.fleetSizes.count
    }
}
