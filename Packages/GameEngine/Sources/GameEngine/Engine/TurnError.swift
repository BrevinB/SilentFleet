import Foundation

/// Errors that can occur during turn execution
public enum TurnError: Error, Equatable, Sendable {
    /// It's not this player's turn
    case notYourTurn

    /// Game is not in the playing phase
    case gameNotInProgress

    /// This coordinate has already been shot
    case alreadyShotHere(Coordinate)

    /// The requested power-up is not available (none remaining)
    case powerUpNotAvailable(PowerUpType)

    /// First player in ranked mode cannot use power-ups on their first turn
    case powerUpForbiddenFirstTurn

    /// The coordinate is outside the board
    case invalidCoordinate(Coordinate)

    /// The row number is invalid for row scan
    case invalidRow(Int)

    /// Game is already over
    case gameAlreadyOver
}

extension TurnError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notYourTurn:
            return "It's not your turn"
        case .gameNotInProgress:
            return "Game is not in progress"
        case .alreadyShotHere(let coord):
            return "Already shot at \(coord)"
        case .powerUpNotAvailable(let type):
            return "Power-up \(type.rawValue) is not available"
        case .powerUpForbiddenFirstTurn:
            return "First player cannot use power-ups on their first turn in ranked mode"
        case .invalidCoordinate(let coord):
            return "Invalid coordinate: \(coord)"
        case .invalidRow(let row):
            return "Invalid row: \(row)"
        case .gameAlreadyOver:
            return "Game is already over"
        }
    }
}
