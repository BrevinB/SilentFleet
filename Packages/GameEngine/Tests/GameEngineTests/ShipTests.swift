import XCTest
@testable import GameEngine

final class ShipTests: XCTestCase {

    // MARK: - Coordinate Tests

    func testHorizontalShipCoordinates() {
        let ship = Ship(size: 3, origin: Coordinate(row: 2, col: 4), orientation: .horizontal)
        let coords = ship.coordinates

        XCTAssertEqual(coords.count, 3)
        XCTAssertEqual(coords[0], Coordinate(row: 2, col: 4))
        XCTAssertEqual(coords[1], Coordinate(row: 2, col: 5))
        XCTAssertEqual(coords[2], Coordinate(row: 2, col: 6))
    }

    func testVerticalShipCoordinates() {
        let ship = Ship(size: 4, origin: Coordinate(row: 1, col: 3), orientation: .vertical)
        let coords = ship.coordinates

        XCTAssertEqual(coords.count, 4)
        XCTAssertEqual(coords[0], Coordinate(row: 1, col: 3))
        XCTAssertEqual(coords[1], Coordinate(row: 2, col: 3))
        XCTAssertEqual(coords[2], Coordinate(row: 3, col: 3))
        XCTAssertEqual(coords[3], Coordinate(row: 4, col: 3))
    }

    func testSingleTileShip() {
        let ship = Ship(size: 1, origin: Coordinate(row: 5, col: 5), orientation: .horizontal)
        let coords = ship.coordinates

        XCTAssertEqual(coords.count, 1)
        XCTAssertEqual(coords[0], Coordinate(row: 5, col: 5))
    }

    // MARK: - Bounds Tests

    func testShipWithinBounds() {
        let validShips = [
            Ship(size: 5, origin: Coordinate(row: 0, col: 0), orientation: .horizontal),
            Ship(size: 5, origin: Coordinate(row: 0, col: 5), orientation: .horizontal),
            Ship(size: 5, origin: Coordinate(row: 0, col: 0), orientation: .vertical),
            Ship(size: 5, origin: Coordinate(row: 5, col: 0), orientation: .vertical),
            Ship(size: 1, origin: Coordinate(row: 9, col: 9), orientation: .horizontal)
        ]

        for ship in validShips {
            XCTAssertTrue(ship.isWithinBounds, "Ship at \(ship.origin) should be within bounds")
        }
    }

    func testShipOutOfBounds() {
        let invalidShips = [
            Ship(size: 5, origin: Coordinate(row: 0, col: 6), orientation: .horizontal),  // extends past col 9
            Ship(size: 5, origin: Coordinate(row: 6, col: 0), orientation: .vertical),    // extends past row 9
            Ship(size: 3, origin: Coordinate(row: -1, col: 0), orientation: .horizontal), // starts before row 0
            Ship(size: 3, origin: Coordinate(row: 0, col: -1), orientation: .horizontal)  // starts before col 0
        ]

        for ship in invalidShips {
            XCTAssertFalse(ship.isWithinBounds, "Ship at \(ship.origin) size \(ship.size) should be out of bounds")
        }
    }

    // MARK: - Hit Tests

    func testRecordHit() {
        var ship = Ship(size: 3, origin: Coordinate(row: 0, col: 0), orientation: .horizontal)

        XCTAssertFalse(ship.isSunk)
        XCTAssertEqual(ship.hitCount, 0)

        // Hit first segment
        let hit1 = ship.recordHit(at: Coordinate(row: 0, col: 0))
        XCTAssertTrue(hit1)
        XCTAssertEqual(ship.hitCount, 1)
        XCTAssertFalse(ship.isSunk)

        // Hit middle segment
        let hit2 = ship.recordHit(at: Coordinate(row: 0, col: 1))
        XCTAssertTrue(hit2)
        XCTAssertEqual(ship.hitCount, 2)
        XCTAssertFalse(ship.isSunk)

        // Hit last segment - ship sinks
        let hit3 = ship.recordHit(at: Coordinate(row: 0, col: 2))
        XCTAssertTrue(hit3)
        XCTAssertEqual(ship.hitCount, 3)
        XCTAssertTrue(ship.isSunk)
    }

    func testRecordHitMiss() {
        var ship = Ship(size: 3, origin: Coordinate(row: 0, col: 0), orientation: .horizontal)

        // Try to hit a coordinate not on the ship
        let miss = ship.recordHit(at: Coordinate(row: 1, col: 0))
        XCTAssertFalse(miss)
        XCTAssertEqual(ship.hitCount, 0)
    }

    func testRecordHitDuplicate() {
        var ship = Ship(size: 3, origin: Coordinate(row: 0, col: 0), orientation: .horizontal)

        // First hit
        let hit1 = ship.recordHit(at: Coordinate(row: 0, col: 0))
        XCTAssertTrue(hit1)

        // Duplicate hit
        let hit2 = ship.recordHit(at: Coordinate(row: 0, col: 0))
        XCTAssertFalse(hit2)
        XCTAssertEqual(ship.hitCount, 1)
    }

    // MARK: - Occupies Tests

    func testOccupies() {
        let ship = Ship(size: 3, origin: Coordinate(row: 2, col: 4), orientation: .horizontal)

        XCTAssertTrue(ship.occupies(Coordinate(row: 2, col: 4)))
        XCTAssertTrue(ship.occupies(Coordinate(row: 2, col: 5)))
        XCTAssertTrue(ship.occupies(Coordinate(row: 2, col: 6)))

        XCTAssertFalse(ship.occupies(Coordinate(row: 2, col: 3)))
        XCTAssertFalse(ship.occupies(Coordinate(row: 2, col: 7)))
        XCTAssertFalse(ship.occupies(Coordinate(row: 1, col: 4)))
        XCTAssertFalse(ship.occupies(Coordinate(row: 3, col: 4)))
    }

    // MARK: - Adjacent Coordinates Tests

    func testAdjacentCoordinatesHorizontal() {
        let ship = Ship(size: 2, origin: Coordinate(row: 5, col: 5), orientation: .horizontal)
        let adjacent = ship.adjacentCoordinates

        // Ship occupies (5,5) and (5,6)
        // Adjacent should include all 8 neighbors minus ship tiles

        // Should include orthogonal
        XCTAssertTrue(adjacent.contains(Coordinate(row: 4, col: 5)))
        XCTAssertTrue(adjacent.contains(Coordinate(row: 6, col: 5)))
        XCTAssertTrue(adjacent.contains(Coordinate(row: 4, col: 6)))
        XCTAssertTrue(adjacent.contains(Coordinate(row: 6, col: 6)))
        XCTAssertTrue(adjacent.contains(Coordinate(row: 5, col: 4)))
        XCTAssertTrue(adjacent.contains(Coordinate(row: 5, col: 7)))

        // Should include diagonal
        XCTAssertTrue(adjacent.contains(Coordinate(row: 4, col: 4)))
        XCTAssertTrue(adjacent.contains(Coordinate(row: 4, col: 7)))
        XCTAssertTrue(adjacent.contains(Coordinate(row: 6, col: 4)))
        XCTAssertTrue(adjacent.contains(Coordinate(row: 6, col: 7)))

        // Should NOT include ship tiles
        XCTAssertFalse(adjacent.contains(Coordinate(row: 5, col: 5)))
        XCTAssertFalse(adjacent.contains(Coordinate(row: 5, col: 6)))
    }

    // MARK: - Codable Tests

    func testCodable() throws {
        var ship = Ship(size: 4, origin: Coordinate(row: 3, col: 2), orientation: .vertical)
        _ = ship.recordHit(at: Coordinate(row: 3, col: 2))
        _ = ship.recordHit(at: Coordinate(row: 4, col: 2))

        let encoder = JSONEncoder()
        let data = try encoder.encode(ship)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Ship.self, from: data)

        XCTAssertEqual(ship.id, decoded.id)
        XCTAssertEqual(ship.size, decoded.size)
        XCTAssertEqual(ship.origin, decoded.origin)
        XCTAssertEqual(ship.orientation, decoded.orientation)
        XCTAssertEqual(ship.hitMask, decoded.hitMask)
        XCTAssertEqual(ship.hitCount, decoded.hitCount)
    }
}
