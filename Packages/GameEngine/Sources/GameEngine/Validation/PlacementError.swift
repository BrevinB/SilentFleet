import Foundation

/// Errors that can occur during ship placement validation
public enum PlacementError: Error, Equatable, Sendable {
    /// Ship extends outside the 10x10 board
    case outOfBounds(ship: Ship)

    /// Ship overlaps with another ship
    case overlap(ship: Ship, existingShip: Ship, at: Coordinate)

    /// Ship is adjacent to another ship (orthogonally or diagonally)
    case adjacentToShip(ship: Ship, existingShip: Ship, at: Coordinate)

    /// Invalid ship size (not in the fleet configuration)
    case invalidShipSize(size: Int)

    /// Fleet doesn't have the correct number/sizes of ships
    case fleetIncomplete(expected: [Int], got: [Int])

    /// Ranked mode: constraint that each half must have at least one ship of size >= 3
    case rankedHalfConstraintViolation(half: String, message: String)

    /// Duplicate ship ID
    case duplicateShipID(id: UUID)
}

extension PlacementError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .outOfBounds(let ship):
            return "Ship of size \(ship.size) at \(ship.origin) extends outside the board"
        case .overlap(let ship, let existing, let at):
            return "Ship of size \(ship.size) overlaps with ship of size \(existing.size) at \(at)"
        case .adjacentToShip(let ship, let existing, let at):
            return "Ship of size \(ship.size) is adjacent to ship of size \(existing.size) at \(at)"
        case .invalidShipSize(let size):
            return "Invalid ship size: \(size)"
        case .fleetIncomplete(let expected, let got):
            return "Fleet incomplete. Expected sizes \(expected), got \(got)"
        case .rankedHalfConstraintViolation(let half, let message):
            return "Ranked constraint violation in \(half) half: \(message)"
        case .duplicateShipID(let id):
            return "Duplicate ship ID: \(id)"
        }
    }
}
