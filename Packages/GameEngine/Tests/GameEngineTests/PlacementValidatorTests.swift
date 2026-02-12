import XCTest
@testable import GameEngine

final class PlacementValidatorTests: XCTestCase {

    // MARK: - Helper for Result<Void, Error> assertions

    private func assertSuccess(_ result: Result<Void, PlacementError>, _ message: String = "") {
        if case .failure(let error) = result {
            XCTFail("Expected success but got failure: \(error). \(message)")
        }
    }

    // MARK: - Single Ship Validation

    func testCanPlaceShipOnEmptyBoard() {
        let ship = Ship(size: 3, origin: Coordinate(row: 0, col: 0), orientation: .horizontal)
        let result = PlacementValidator.canPlace(ship: ship, on: [])

        assertSuccess(result)
    }

    func testCannotPlaceShipOutOfBounds() {
        let ship = Ship(size: 5, origin: Coordinate(row: 0, col: 7), orientation: .horizontal)
        let result = PlacementValidator.canPlace(ship: ship, on: [])

        if case .failure(.outOfBounds) = result {
            // Expected
        } else {
            XCTFail("Expected outOfBounds error")
        }
    }

    func testCannotPlaceOverlappingShips() {
        let ship1 = Ship(size: 3, origin: Coordinate(row: 5, col: 3), orientation: .horizontal)
        let ship2 = Ship(size: 3, origin: Coordinate(row: 5, col: 4), orientation: .horizontal)

        let result = PlacementValidator.canPlace(ship: ship2, on: [ship1])

        if case .failure(.overlap) = result {
            // Expected
        } else {
            XCTFail("Expected overlap error")
        }
    }

    func testCannotPlaceAdjacentShipsOrthogonally() {
        // Ship at row 5, cols 3-5
        let ship1 = Ship(size: 3, origin: Coordinate(row: 5, col: 3), orientation: .horizontal)
        // Ship directly above at row 4, cols 3-5
        let ship2 = Ship(size: 3, origin: Coordinate(row: 4, col: 3), orientation: .horizontal)

        let result = PlacementValidator.canPlace(ship: ship2, on: [ship1])

        if case .failure(.adjacentToShip) = result {
            // Expected
        } else {
            XCTFail("Expected adjacentToShip error, got \(result)")
        }
    }

    func testCannotPlaceAdjacentShipsDiagonally() {
        // Ship at row 5, cols 3-5
        let ship1 = Ship(size: 3, origin: Coordinate(row: 5, col: 3), orientation: .horizontal)
        // Ship diagonally at row 4, cols 6-8 (touches corner at (4,6) diagonal to (5,5))
        let ship2 = Ship(size: 3, origin: Coordinate(row: 4, col: 6), orientation: .horizontal)

        let result = PlacementValidator.canPlace(ship: ship2, on: [ship1])

        if case .failure(.adjacentToShip) = result {
            // Expected
        } else {
            XCTFail("Expected adjacentToShip error, got \(result)")
        }
    }

    func testCanPlaceShipsWithGap() {
        // Ship at row 5, cols 3-5
        let ship1 = Ship(size: 3, origin: Coordinate(row: 5, col: 3), orientation: .horizontal)
        // Ship with gap at row 3, cols 3-5 (row 4 is empty between them)
        let ship2 = Ship(size: 3, origin: Coordinate(row: 3, col: 3), orientation: .horizontal)

        let result = PlacementValidator.canPlace(ship: ship2, on: [ship1])

        assertSuccess(result)
    }

    // MARK: - Full Fleet Validation

    func testValidFleetPlacement() {
        let ships = createValidFleet()
        let result = PlacementValidator.validate(ships: ships, mode: .casual)

        assertSuccess(result)
    }

    func testIncompleteFleet() {
        // Only place a few ships
        let ships = [
            Ship(size: 5, origin: Coordinate(row: 0, col: 0), orientation: .horizontal),
            Ship(size: 4, origin: Coordinate(row: 2, col: 0), orientation: .horizontal)
        ]

        let result = PlacementValidator.validate(ships: ships, mode: .casual)

        if case .failure(.fleetIncomplete) = result {
            // Expected
        } else {
            XCTFail("Expected fleetIncomplete error")
        }
    }

    func testDuplicateShipID() {
        let sharedID = UUID()
        let ships = [
            Ship(id: sharedID, size: 5, origin: Coordinate(row: 0, col: 0), orientation: .horizontal),
            Ship(id: sharedID, size: 4, origin: Coordinate(row: 2, col: 0), orientation: .horizontal)
        ]

        let result = PlacementValidator.validate(ships: ships, mode: .casual)

        if case .failure(.duplicateShipID) = result {
            // Expected
        } else {
            XCTFail("Expected duplicateShipID error")
        }
    }

    // MARK: - Ranked Half-Board Constraint

    func testRankedTopBottomConstraintValid() {
        // Fleet with large ships in both halves
        let ships = [
            // Large ship in top half (rows 0-4)
            Ship(size: 5, origin: Coordinate(row: 0, col: 0), orientation: .horizontal),
            // Large ship in bottom half (rows 5-9)
            Ship(size: 4, origin: Coordinate(row: 6, col: 0), orientation: .horizontal),
            Ship(size: 3, origin: Coordinate(row: 2, col: 0), orientation: .vertical),
            Ship(size: 3, origin: Coordinate(row: 8, col: 5), orientation: .horizontal),
            Ship(size: 2, origin: Coordinate(row: 0, col: 8), orientation: .vertical),
            Ship(size: 2, origin: Coordinate(row: 4, col: 6), orientation: .horizontal),
            Ship(size: 1, origin: Coordinate(row: 9, col: 9), orientation: .horizontal),
            Ship(size: 1, origin: Coordinate(row: 5, col: 9), orientation: .horizontal),
            Ship(size: 1, origin: Coordinate(row: 3, col: 9), orientation: .horizontal)
        ]

        let result = PlacementValidator.validate(ships: ships, mode: .ranked, splitOrientation: .topBottom)

        assertSuccess(result, "Expected valid ranked placement")
    }

    func testRankedTopBottomConstraintInvalid_AllLargeInTop() {
        // All large ships (size >= 3) in top half only
        let ships = [
            Ship(size: 5, origin: Coordinate(row: 0, col: 0), orientation: .horizontal),
            Ship(size: 4, origin: Coordinate(row: 2, col: 0), orientation: .horizontal),
            Ship(size: 3, origin: Coordinate(row: 0, col: 6), orientation: .vertical),
            Ship(size: 3, origin: Coordinate(row: 4, col: 0), orientation: .horizontal),
            // Small ships can be anywhere
            Ship(size: 2, origin: Coordinate(row: 6, col: 0), orientation: .horizontal),
            Ship(size: 2, origin: Coordinate(row: 8, col: 0), orientation: .horizontal),
            Ship(size: 1, origin: Coordinate(row: 6, col: 5), orientation: .horizontal),
            Ship(size: 1, origin: Coordinate(row: 8, col: 5), orientation: .horizontal),
            Ship(size: 1, origin: Coordinate(row: 6, col: 9), orientation: .horizontal)
        ]

        let result = PlacementValidator.validate(ships: ships, mode: .ranked, splitOrientation: .topBottom)

        if case .failure(.rankedHalfConstraintViolation(let half, _)) = result {
            XCTAssertEqual(half, "bottom")
        } else {
            XCTFail("Expected rankedHalfConstraintViolation for bottom half, got \(result)")
        }
    }

    func testRankedLeftRightConstraintValid() {
        // Fleet with large ships in both halves (left cols 0-4, right cols 5-9)
        let ships = [
            // Large ship spanning into left half
            Ship(size: 5, origin: Coordinate(row: 0, col: 0), orientation: .horizontal),
            // Large ship in right half
            Ship(size: 4, origin: Coordinate(row: 2, col: 6), orientation: .horizontal),
            Ship(size: 3, origin: Coordinate(row: 4, col: 0), orientation: .horizontal),
            Ship(size: 3, origin: Coordinate(row: 6, col: 7), orientation: .horizontal),
            Ship(size: 2, origin: Coordinate(row: 8, col: 0), orientation: .horizontal),
            Ship(size: 2, origin: Coordinate(row: 8, col: 5), orientation: .horizontal),
            Ship(size: 1, origin: Coordinate(row: 6, col: 0), orientation: .horizontal),
            Ship(size: 1, origin: Coordinate(row: 6, col: 4), orientation: .horizontal),
            Ship(size: 1, origin: Coordinate(row: 4, col: 4), orientation: .horizontal)
        ]

        let result = PlacementValidator.validate(ships: ships, mode: .ranked, splitOrientation: .leftRight)

        assertSuccess(result)
    }

    func testRankedConstraintShipSpanningBothHalves() {
        // A single large ship spanning both halves should satisfy both
        let ships = [
            // This 5-size ship at col 3 spans cols 3-7, covering both left (3,4) and right (5,6,7)
            Ship(size: 5, origin: Coordinate(row: 0, col: 3), orientation: .horizontal),
            Ship(size: 4, origin: Coordinate(row: 2, col: 0), orientation: .horizontal),
            Ship(size: 3, origin: Coordinate(row: 4, col: 0), orientation: .horizontal),
            Ship(size: 3, origin: Coordinate(row: 6, col: 0), orientation: .horizontal),
            Ship(size: 2, origin: Coordinate(row: 8, col: 0), orientation: .horizontal),
            Ship(size: 2, origin: Coordinate(row: 8, col: 5), orientation: .horizontal),
            Ship(size: 1, origin: Coordinate(row: 2, col: 9), orientation: .horizontal),
            Ship(size: 1, origin: Coordinate(row: 4, col: 9), orientation: .horizontal),
            Ship(size: 1, origin: Coordinate(row: 6, col: 9), orientation: .horizontal)
        ]

        let result = PlacementValidator.validate(ships: ships, mode: .ranked, splitOrientation: .leftRight)

        assertSuccess(result)
    }

    // MARK: - Helper Methods

    func testValidPlacements() {
        let existingShips = [
            Ship(size: 3, origin: Coordinate(row: 5, col: 5), orientation: .horizontal)
        ]

        let validPlacements = PlacementValidator.validPlacements(
            forShipOfSize: 2,
            existingShips: existingShips
        )

        // Should have many valid placements
        XCTAssertGreaterThan(validPlacements.count, 0)

        // None should be adjacent to the existing ship
        for placement in validPlacements {
            let result = PlacementValidator.canPlace(ship: placement, on: existingShips)
            assertSuccess(result)
        }
    }

    func testIsSafeCoordinate() {
        let existingShips = [
            Ship(size: 3, origin: Coordinate(row: 5, col: 5), orientation: .horizontal)
        ]

        // Ship occupies (5,5), (5,6), (5,7)

        // Occupied coordinates are not safe
        XCTAssertFalse(PlacementValidator.isSafeCoordinate(Coordinate(row: 5, col: 5), existingShips: existingShips))
        XCTAssertFalse(PlacementValidator.isSafeCoordinate(Coordinate(row: 5, col: 6), existingShips: existingShips))

        // Adjacent coordinates are not safe
        XCTAssertFalse(PlacementValidator.isSafeCoordinate(Coordinate(row: 4, col: 5), existingShips: existingShips))
        XCTAssertFalse(PlacementValidator.isSafeCoordinate(Coordinate(row: 5, col: 4), existingShips: existingShips))
        XCTAssertFalse(PlacementValidator.isSafeCoordinate(Coordinate(row: 4, col: 4), existingShips: existingShips)) // diagonal

        // Far coordinates are safe
        XCTAssertTrue(PlacementValidator.isSafeCoordinate(Coordinate(row: 0, col: 0), existingShips: existingShips))
        XCTAssertTrue(PlacementValidator.isSafeCoordinate(Coordinate(row: 3, col: 5), existingShips: existingShips))
    }

    // MARK: - Helper

    private func createValidFleet() -> [Ship] {
        // Create a valid fleet that doesn't touch
        return [
            Ship(size: 5, origin: Coordinate(row: 0, col: 0), orientation: .horizontal),
            Ship(size: 4, origin: Coordinate(row: 2, col: 0), orientation: .horizontal),
            Ship(size: 3, origin: Coordinate(row: 4, col: 0), orientation: .horizontal),
            Ship(size: 3, origin: Coordinate(row: 6, col: 0), orientation: .horizontal),
            Ship(size: 2, origin: Coordinate(row: 8, col: 0), orientation: .horizontal),
            Ship(size: 2, origin: Coordinate(row: 0, col: 6), orientation: .vertical),
            Ship(size: 1, origin: Coordinate(row: 0, col: 8), orientation: .horizontal),
            Ship(size: 1, origin: Coordinate(row: 2, col: 8), orientation: .horizontal),
            Ship(size: 1, origin: Coordinate(row: 4, col: 8), orientation: .horizontal)
        ]
    }
}
