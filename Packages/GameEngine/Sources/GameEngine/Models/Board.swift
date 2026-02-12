import Foundation

/// Represents a player's 10x10 game board with ships and shot history
public struct Board: Codable, Equatable, Sendable {
    /// Board dimensions
    public static let size = 10

    /// Standard fleet configuration: total 23 tiles
    /// [Carrier(5), Battleship(4), Cruiser(3), Submarine(3), Destroyer(2), Destroyer(2), Patrol(1), Patrol(1), Patrol(1)]
    public static let fleetSizes = [5, 4, 3, 3, 2, 2, 1, 1, 1]

    /// Total number of tiles occupied by all ships
    public static let totalFleetTiles = fleetSizes.reduce(0, +)  // 23

    /// Ships placed on this board
    public private(set) var ships: [Ship]

    /// Coordinates that have been shot at (opponent's view of incoming fire)
    public private(set) var incomingShots: Set<Coordinate>

    public init(ships: [Ship] = [], incomingShots: Set<Coordinate> = []) {
        self.ships = ships
        self.incomingShots = incomingShots
    }

    /// Find the ship at a given coordinate, if any
    public func ship(at coord: Coordinate) -> Ship? {
        ships.first { $0.occupies(coord) }
    }

    /// Check if a coordinate has a ship on it
    public func hasShip(at coord: Coordinate) -> Bool {
        ship(at: coord) != nil
    }

    /// Check if a coordinate has been shot at
    public func hasBeenShot(at coord: Coordinate) -> Bool {
        incomingShots.contains(coord)
    }

    /// Check if all ships have been sunk
    public func isAllSunk() -> Bool {
        ships.allSatisfy { $0.isSunk }
    }

    /// Count of ships that have been sunk
    public var sunkCount: Int {
        ships.filter { $0.isSunk }.count
    }

    /// Count of ships still afloat
    public var remainingCount: Int {
        ships.count - sunkCount
    }

    /// Ship status info for UI display (size and whether sunk), sorted by size descending
    public var shipStatuses: [(size: Int, isSunk: Bool)] {
        ships.map { (size: $0.size, isSunk: $0.isSunk) }
            .sorted { $0.size > $1.size }
    }

    /// All coordinates occupied by ships
    public var occupiedCoordinates: Set<Coordinate> {
        Set(ships.flatMap { $0.coordinates })
    }

    /// All coordinates adjacent to ships (for no-touch validation)
    public var adjacentToShipsCoordinates: Set<Coordinate> {
        var adjacent = Set<Coordinate>()
        for ship in ships {
            adjacent.formUnion(ship.adjacentCoordinates)
        }
        return adjacent.subtracting(occupiedCoordinates)
    }

    /// Record an incoming shot and return the result
    public mutating func receiveShot(at coord: Coordinate) -> (hit: Bool, ship: Ship?, sunk: Bool) {
        incomingShots.insert(coord)

        guard let shipIndex = ships.firstIndex(where: { $0.occupies(coord) }) else {
            return (hit: false, ship: nil, sunk: false)
        }

        _ = ships[shipIndex].recordHit(at: coord)
        let ship = ships[shipIndex]
        return (hit: true, ship: ship, sunk: ship.isSunk)
    }

    /// Add a ship to the board (used during placement)
    public mutating func addShip(_ ship: Ship) {
        ships.append(ship)
    }

    /// Clear all ships (reset for placement)
    public mutating func clearShips() {
        ships.removeAll()
    }

    /// Check if any ship occupies any of the given coordinates
    public func hasShipInAny(of coordinates: [Coordinate]) -> Bool {
        coordinates.contains { hasShip(at: $0) }
    }
}
