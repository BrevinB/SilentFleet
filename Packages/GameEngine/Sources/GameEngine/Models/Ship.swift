import Foundation

/// Represents a ship on the board with its position, orientation, and hit state
public struct Ship: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let size: Int
    public let origin: Coordinate
    public let orientation: Orientation

    /// Tracks which segments of the ship have been hit (index 0 = origin)
    public private(set) var hitMask: [Bool]

    public init(
        id: UUID = UUID(),
        size: Int,
        origin: Coordinate,
        orientation: Orientation
    ) {
        self.id = id
        self.size = size
        self.origin = origin
        self.orientation = orientation
        self.hitMask = Array(repeating: false, count: size)
    }

    /// All coordinates occupied by this ship
    public var coordinates: [Coordinate] {
        (0..<size).map { index in
            switch orientation {
            case .horizontal:
                return Coordinate(row: origin.row, col: origin.col + index)
            case .vertical:
                return Coordinate(row: origin.row + index, col: origin.col)
            }
        }
    }

    /// Whether all segments of the ship have been hit
    public var isSunk: Bool {
        hitMask.allSatisfy { $0 }
    }

    /// Number of hits on this ship
    public var hitCount: Int {
        hitMask.filter { $0 }.count
    }

    /// Records a hit at the given coordinate
    /// - Returns: true if hit was recorded, false if coordinate not part of ship or already hit
    public mutating func recordHit(at coord: Coordinate) -> Bool {
        guard let index = coordinates.firstIndex(of: coord) else {
            return false
        }
        guard !hitMask[index] else {
            return false
        }
        hitMask[index] = true
        return true
    }

    /// Check if this ship occupies the given coordinate
    public func occupies(_ coord: Coordinate) -> Bool {
        coordinates.contains(coord)
    }

    /// Check if all coordinates are within board bounds
    public var isWithinBounds: Bool {
        coordinates.allSatisfy { $0.isValid }
    }

    /// Returns all coordinates adjacent to this ship (for no-touch validation)
    public var adjacentCoordinates: Set<Coordinate> {
        var adjacent = Set<Coordinate>()
        for coord in coordinates {
            for neighbor in coord.allNeighbors {
                if !coordinates.contains(neighbor) {
                    adjacent.insert(neighbor)
                }
            }
        }
        return adjacent
    }
}

extension Ship: CustomStringConvertible {
    public var description: String {
        "Ship(size: \(size), origin: \(origin), orientation: \(orientation), sunk: \(isSunk))"
    }
}
