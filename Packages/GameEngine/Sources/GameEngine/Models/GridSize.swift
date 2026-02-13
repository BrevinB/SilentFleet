import Foundation

/// Grid size determines the board dimensions and fleet composition
/// Smaller grids create quicker games
public enum GridSize: String, Codable, CaseIterable, Sendable {
    /// 6x6 grid with 5 ships — quick games
    case small

    /// 8x8 grid with 6 ships — medium-length games
    case medium

    /// 10x10 grid with 9 ships — classic full-length games
    case large

    /// Board dimensions (square grid)
    public var boardSize: Int {
        switch self {
        case .small: return 6
        case .medium: return 8
        case .large: return 10
        }
    }

    /// Fleet configuration (ship sizes) for this grid size
    public var fleetSizes: [Int] {
        switch self {
        case .small:
            // Frigate(3), Corvette(2), Corvette(2), Patrol(1), Patrol(1)
            return [3, 2, 2, 1, 1]
        case .medium:
            // Battleship(4), Cruiser(3), Submarine(3), Destroyer(2), Patrol(1), Patrol(1)
            return [4, 3, 3, 2, 1, 1]
        case .large:
            // Carrier(5), Battleship(4), Cruiser(3), Submarine(3), Destroyer(2), Destroyer(2), Patrol(1), Patrol(1), Patrol(1)
            return [5, 4, 3, 3, 2, 2, 1, 1, 1]
        }
    }

    /// Total tiles occupied by all ships
    public var totalFleetTiles: Int {
        fleetSizes.reduce(0, +)
    }

    /// Number of ships in the fleet
    public var shipCount: Int {
        fleetSizes.count
    }

    /// Display name for UI
    public var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }

    /// Grid description for UI (e.g. "6×6")
    public var gridDescription: String {
        "\(boardSize)×\(boardSize)"
    }
}
