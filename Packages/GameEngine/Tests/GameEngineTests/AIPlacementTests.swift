import XCTest
@testable import GameEngine

final class AIPlacementTests: XCTestCase {

    // MARK: - Helper for Result<Void, Error> assertions

    private func assertSuccess(_ result: Result<Void, PlacementError>, _ message: String = "") {
        if case .failure(let error) = result {
            XCTFail("Expected success but got failure: \(error). \(message)")
        }
    }

    // MARK: - Factory Tests

    func testFactoryCreatesCorrectStrategies() {
        let easy = AIPlacementFactory.strategy(for: .easy)
        let medium = AIPlacementFactory.strategy(for: .medium)
        let hard = AIPlacementFactory.strategy(for: .hard)

        XCTAssertTrue(easy is RandomPlacement)
        XCTAssertTrue(medium is HeatAvoidancePlacement)
        XCTAssertTrue(hard is InvertedHeatPlacement)
    }

    // MARK: - Random Placement Tests (Easy)

    func testRandomPlacementGeneratesValidFleet() {
        let strategy = RandomPlacement()

        for _ in 0..<10 {  // Run multiple times for randomness
            let ships = strategy.generatePlacement(
                for: Board.fleetSizes,
                mode: .casual,
                splitOrientation: nil
            )

            // Verify correct number of ships
            XCTAssertEqual(ships.count, Board.fleetSizes.count)

            // Verify correct sizes
            let sizes = ships.map { $0.size }.sorted()
            XCTAssertEqual(sizes, Board.fleetSizes.sorted())

            // Verify valid placement
            let result = PlacementValidator.validate(ships: ships, mode: .casual)
            assertSuccess(result, "Random placement should be valid")
        }
    }

    func testRandomPlacementRespectsNoTouchRule() {
        let strategy = RandomPlacement()

        for _ in 0..<10 {
            let ships = strategy.generatePlacement(
                for: Board.fleetSizes,
                mode: .casual,
                splitOrientation: nil
            )

            // Check no ships touch
            for (i, ship1) in ships.enumerated() {
                for ship2 in ships[(i+1)...] {
                    let ship1Coords = Set(ship1.coordinates)
                    let ship2Coords = Set(ship2.coordinates)
                    let ship1Adjacent = ship1.adjacentCoordinates

                    // No overlap
                    XCTAssertTrue(ship1Coords.isDisjoint(with: ship2Coords))
                    // No adjacency
                    XCTAssertTrue(ship1Adjacent.isDisjoint(with: ship2Coords))
                }
            }
        }
    }

    func testRandomPlacementRankedConstraint() {
        let strategy = RandomPlacement()

        for split in BoardSplit.allCases {
            for _ in 0..<5 {
                let ships = strategy.generatePlacement(
                    for: Board.fleetSizes,
                    mode: .ranked,
                    splitOrientation: split
                )

                let result = PlacementValidator.validate(
                    ships: ships,
                    mode: .ranked,
                    splitOrientation: split
                )

                assertSuccess(result, "Ranked placement should satisfy \(split) constraint")
            }
        }
    }

    // MARK: - Heat Avoidance Placement Tests (Medium)

    func testHeatAvoidancePlacementGeneratesValidFleet() {
        let strategy = HeatAvoidancePlacement()

        for _ in 0..<10 {
            let ships = strategy.generatePlacement(
                for: Board.fleetSizes,
                mode: .casual,
                splitOrientation: nil
            )

            XCTAssertEqual(ships.count, Board.fleetSizes.count)

            let result = PlacementValidator.validate(ships: ships, mode: .casual)
            assertSuccess(result)
        }
    }

    func testHeatAvoidancePlacementRankedConstraint() {
        let strategy = HeatAvoidancePlacement()

        for split in BoardSplit.allCases {
            for _ in 0..<5 {
                let ships = strategy.generatePlacement(
                    for: Board.fleetSizes,
                    mode: .ranked,
                    splitOrientation: split
                )

                let result = PlacementValidator.validate(
                    ships: ships,
                    mode: .ranked,
                    splitOrientation: split
                )

                assertSuccess(result)
            }
        }
    }

    // MARK: - Inverted Heat Placement Tests (Hard)

    func testInvertedHeatPlacementGeneratesValidFleet() {
        let strategy = InvertedHeatPlacement()

        for _ in 0..<10 {
            let ships = strategy.generatePlacement(
                for: Board.fleetSizes,
                mode: .casual,
                splitOrientation: nil
            )

            XCTAssertEqual(ships.count, Board.fleetSizes.count)

            let result = PlacementValidator.validate(ships: ships, mode: .casual)
            assertSuccess(result)
        }
    }

    func testInvertedHeatPlacementRankedConstraint() {
        let strategy = InvertedHeatPlacement()

        for split in BoardSplit.allCases {
            for _ in 0..<5 {
                let ships = strategy.generatePlacement(
                    for: Board.fleetSizes,
                    mode: .ranked,
                    splitOrientation: split
                )

                let result = PlacementValidator.validate(
                    ships: ships,
                    mode: .ranked,
                    splitOrientation: split
                )

                assertSuccess(result)
            }
        }
    }

    // MARK: - Variety Tests

    func testHardAIProducesVariety() {
        let strategy = InvertedHeatPlacement()
        var placements: [Set<Coordinate>] = []

        for _ in 0..<10 {
            let ships = strategy.generatePlacement(
                for: Board.fleetSizes,
                mode: .casual,
                splitOrientation: nil
            )

            let coords = Set(ships.flatMap { $0.coordinates })
            placements.append(coords)
        }

        // At least some placements should be different
        let uniquePlacements = Set(placements.map { Array($0).sorted { ($0.row, $0.col) < ($1.row, $1.col) }.description })
        XCTAssertGreaterThan(uniquePlacements.count, 1, "Hard AI should produce varied placements")
    }

    // MARK: - All Ships Within Bounds

    func testAllPlacementsWithinBounds() {
        let strategies: [(String, AIPlacementStrategy)] = [
            ("Easy", RandomPlacement()),
            ("Medium", HeatAvoidancePlacement()),
            ("Hard", InvertedHeatPlacement())
        ]

        for (name, strategy) in strategies {
            for _ in 0..<5 {
                let ships = strategy.generatePlacement(
                    for: Board.fleetSizes,
                    mode: .casual,
                    splitOrientation: nil
                )

                for ship in ships {
                    XCTAssertTrue(ship.isWithinBounds, "\(name) AI placed ship out of bounds: \(ship)")
                }
            }
        }
    }

    // MARK: - Correct Ship Sizes

    func testAllPlacementsHaveCorrectSizes() {
        let strategies: [(String, AIPlacementStrategy)] = [
            ("Easy", RandomPlacement()),
            ("Medium", HeatAvoidancePlacement()),
            ("Hard", InvertedHeatPlacement())
        ]

        for (name, strategy) in strategies {
            let ships = strategy.generatePlacement(
                for: Board.fleetSizes,
                mode: .casual,
                splitOrientation: nil
            )

            let sizes = ships.map { $0.size }.sorted()
            XCTAssertEqual(sizes, Board.fleetSizes.sorted(), "\(name) AI should produce correct fleet sizes")
        }
    }

    // MARK: - Performance

    func testPlacementPerformance() {
        let strategy = InvertedHeatPlacement()

        measure {
            for _ in 0..<10 {
                _ = strategy.generatePlacement(
                    for: Board.fleetSizes,
                    mode: .ranked,
                    splitOrientation: .topBottom
                )
            }
        }
    }
}
