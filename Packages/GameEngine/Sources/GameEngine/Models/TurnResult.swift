import Foundation

/// Result of a shot
public enum ShotResult: Codable, Equatable, Sendable {
    case miss
    case hit
    case sunk(shipSize: Int?)  // nil in Ranked mode (don't reveal ship type)

    /// Whether the shot hit a ship
    public var isHit: Bool {
        switch self {
        case .miss: return false
        case .hit, .sunk: return true
        }
    }

    /// Whether a ship was sunk
    public var isSunk: Bool {
        if case .sunk = self { return true }
        return false
    }
}

/// Complete result of a turn including power-up and shot results
public struct TurnResult: Codable, Equatable, Sendable {
    /// Result of power-up if one was used
    public let powerUpResult: PowerUpResult?

    /// Coordinate that was shot
    public let shotCoordinate: Coordinate

    /// Result of the shot
    public let shotResult: ShotResult

    /// Which player took this turn
    public let playerID: UUID

    /// Turn number when this occurred
    public let turnNumber: Int

    public init(
        powerUpResult: PowerUpResult?,
        shotCoordinate: Coordinate,
        shotResult: ShotResult,
        playerID: UUID,
        turnNumber: Int
    ) {
        self.powerUpResult = powerUpResult
        self.shotCoordinate = shotCoordinate
        self.shotResult = shotResult
        self.playerID = playerID
        self.turnNumber = turnNumber
    }
}
