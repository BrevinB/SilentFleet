import Foundation

/// Types of power-ups available in the game
public enum PowerUpType: String, Codable, CaseIterable, Sendable {
    case sonarPing  // 3x3 area presence check
    case rowScan    // Single row presence check
}

/// A power-up action with its parameters
public enum PowerUpAction: Codable, Equatable, Sendable {
    /// Sonar ping centered on a coordinate, checks 3x3 area for ship presence
    case sonarPing(center: Coordinate)

    /// Row scan checks if any ship occupies a tile in the specified row
    case rowScan(row: Int)

    public var type: PowerUpType {
        switch self {
        case .sonarPing: return .sonarPing
        case .rowScan: return .rowScan
        }
    }

    /// Returns all coordinates affected by this power-up action
    public var affectedCoordinates: [Coordinate] {
        switch self {
        case .sonarPing(let center):
            var coords: [Coordinate] = []
            for dr in -1...1 {
                for dc in -1...1 {
                    let coord = Coordinate(row: center.row + dr, col: center.col + dc)
                    if coord.isValid {
                        coords.append(coord)
                    }
                }
            }
            return coords
        case .rowScan(let row):
            return (0..<Board.size).map { Coordinate(row: row, col: $0) }
        }
    }
}

/// Result of using a power-up
public struct PowerUpResult: Codable, Equatable, Sendable {
    public let action: PowerUpAction
    public let detected: Bool  // YES = at least one ship tile present, NO = no ships
    public let detectedCoordinates: [Coordinate]  // For sonar: actual ship positions found

    public init(action: PowerUpAction, detected: Bool, detectedCoordinates: [Coordinate] = []) {
        self.action = action
        self.detected = detected
        self.detectedCoordinates = detectedCoordinates
    }
}
