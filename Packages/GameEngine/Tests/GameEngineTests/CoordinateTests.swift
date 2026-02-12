import XCTest
@testable import GameEngine

final class CoordinateTests: XCTestCase {

    // MARK: - Validity Tests

    func testValidCoordinates() {
        for row in 0..<10 {
            for col in 0..<10 {
                let coord = Coordinate(row: row, col: col)
                XCTAssertTrue(coord.isValid, "Coordinate (\(row), \(col)) should be valid")
            }
        }
    }

    func testInvalidCoordinates() {
        let invalidCoords = [
            Coordinate(row: -1, col: 0),
            Coordinate(row: 0, col: -1),
            Coordinate(row: 10, col: 0),
            Coordinate(row: 0, col: 10),
            Coordinate(row: -5, col: -5),
            Coordinate(row: 15, col: 15)
        ]

        for coord in invalidCoords {
            XCTAssertFalse(coord.isValid, "Coordinate \(coord) should be invalid")
        }
    }

    // MARK: - Neighbor Tests

    func testOrthogonalNeighborsCenter() {
        let center = Coordinate(row: 5, col: 5)
        let neighbors = center.orthogonalNeighbors

        XCTAssertEqual(neighbors.count, 4)
        XCTAssertTrue(neighbors.contains(Coordinate(row: 4, col: 5)))
        XCTAssertTrue(neighbors.contains(Coordinate(row: 6, col: 5)))
        XCTAssertTrue(neighbors.contains(Coordinate(row: 5, col: 4)))
        XCTAssertTrue(neighbors.contains(Coordinate(row: 5, col: 6)))
    }

    func testOrthogonalNeighborsCorner() {
        let corner = Coordinate(row: 0, col: 0)
        let neighbors = corner.orthogonalNeighbors

        XCTAssertEqual(neighbors.count, 2)
        XCTAssertTrue(neighbors.contains(Coordinate(row: 1, col: 0)))
        XCTAssertTrue(neighbors.contains(Coordinate(row: 0, col: 1)))
    }

    func testOrthogonalNeighborsEdge() {
        let edge = Coordinate(row: 0, col: 5)
        let neighbors = edge.orthogonalNeighbors

        XCTAssertEqual(neighbors.count, 3)
        XCTAssertTrue(neighbors.contains(Coordinate(row: 1, col: 5)))
        XCTAssertTrue(neighbors.contains(Coordinate(row: 0, col: 4)))
        XCTAssertTrue(neighbors.contains(Coordinate(row: 0, col: 6)))
    }

    func testDiagonalNeighborsCenter() {
        let center = Coordinate(row: 5, col: 5)
        let neighbors = center.diagonalNeighbors

        XCTAssertEqual(neighbors.count, 4)
        XCTAssertTrue(neighbors.contains(Coordinate(row: 4, col: 4)))
        XCTAssertTrue(neighbors.contains(Coordinate(row: 4, col: 6)))
        XCTAssertTrue(neighbors.contains(Coordinate(row: 6, col: 4)))
        XCTAssertTrue(neighbors.contains(Coordinate(row: 6, col: 6)))
    }

    func testDiagonalNeighborsCorner() {
        let corner = Coordinate(row: 0, col: 0)
        let neighbors = corner.diagonalNeighbors

        XCTAssertEqual(neighbors.count, 1)
        XCTAssertTrue(neighbors.contains(Coordinate(row: 1, col: 1)))
    }

    func testAllNeighborsCenter() {
        let center = Coordinate(row: 5, col: 5)
        let neighbors = center.allNeighbors

        XCTAssertEqual(neighbors.count, 8)
    }

    func testAllNeighborsCorner() {
        let corner = Coordinate(row: 0, col: 0)
        let neighbors = corner.allNeighbors

        XCTAssertEqual(neighbors.count, 3)
    }

    // MARK: - Equality Tests

    func testEquality() {
        let coord1 = Coordinate(row: 3, col: 7)
        let coord2 = Coordinate(row: 3, col: 7)
        let coord3 = Coordinate(row: 3, col: 8)

        XCTAssertEqual(coord1, coord2)
        XCTAssertNotEqual(coord1, coord3)
    }

    // MARK: - Hashable Tests

    func testHashable() {
        var set = Set<Coordinate>()
        set.insert(Coordinate(row: 0, col: 0))
        set.insert(Coordinate(row: 0, col: 0))
        set.insert(Coordinate(row: 1, col: 1))

        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Codable Tests

    func testCodable() throws {
        let coord = Coordinate(row: 5, col: 7)
        let encoder = JSONEncoder()
        let data = try encoder.encode(coord)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Coordinate.self, from: data)

        XCTAssertEqual(coord, decoded)
    }
}
