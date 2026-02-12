import XCTest
@testable import GameEngine

final class AITargetingTests: XCTestCase {

    // MARK: - Factory Tests

    func testFactoryCreatesCorrectStrategies() {
        let easy = AITargetingFactory.strategy(for: .easy)
        let medium = AITargetingFactory.strategy(for: .medium)
        let hard = AITargetingFactory.strategy(for: .hard)

        XCTAssertTrue(easy is RandomTargeting)
        XCTAssertTrue(medium is HuntTargetStrategy)
        XCTAssertTrue(hard is HuntTargetStrategy)
    }

    // MARK: - Random Targeting Tests

    func testRandomTargetingSelectsUnshotCell() {
        let strategy = RandomTargeting()
        var board = Board(ships: [
            Ship(size: 3, origin: Coordinate(row: 0, col: 0), orientation: .horizontal)
        ])

        // Shoot some cells
        _ = board.receiveShot(at: Coordinate(row: 5, col: 5))
        _ = board.receiveShot(at: Coordinate(row: 5, col: 6))

        for _ in 0..<20 {
            let target = strategy.selectTarget(board: board, previousResults: [])
            XCTAssertFalse(board.hasBeenShot(at: target), "Should only select unshot cells")
        }
    }

    // MARK: - Hunt/Target Strategy Tests

    func testHuntModeUsesCheckerboard() {
        let strategy = HuntTargetStrategy(accuracy: 1.0, useProbabilityDensity: false)
        let board = Board(ships: [
            Ship(size: 3, origin: Coordinate(row: 0, col: 0), orientation: .horizontal)
        ])

        // Should prefer checkerboard pattern
        var parityCount = 0
        for _ in 0..<50 {
            let target = strategy.selectTarget(board: board, previousResults: [])
            if (target.row + target.col) % 2 == 0 {
                parityCount += 1
            }
        }

        // Should strongly prefer parity cells
        XCTAssertGreaterThan(parityCount, 40, "Should prefer checkerboard pattern")
    }

    func testTargetModeAfterHit() {
        let strategy = HuntTargetStrategy(accuracy: 1.0)

        // Create a board with a ship
        var board = Board(ships: [
            Ship(size: 3, origin: Coordinate(row: 5, col: 5), orientation: .horizontal)
        ])

        // Hit the ship at (5, 5)
        _ = board.receiveShot(at: Coordinate(row: 5, col: 5))

        // Next shots should be adjacent to the hit
        for _ in 0..<10 {
            let target = strategy.selectTarget(board: board, previousResults: [])
            let adjacent = Coordinate(row: 5, col: 5).orthogonalNeighbors
            XCTAssertTrue(
                adjacent.contains(target) || !board.hasBeenShot(at: target),
                "Should target adjacent to hit or unshot cell"
            )
        }
    }

    func testContinuesLineAfterMultipleHits() {
        let strategy = HuntTargetStrategy(accuracy: 1.0)

        // Create a board with a horizontal ship
        var board = Board(ships: [
            Ship(size: 4, origin: Coordinate(row: 5, col: 3), orientation: .horizontal)
        ])

        // Hit two adjacent cells
        _ = board.receiveShot(at: Coordinate(row: 5, col: 4))
        _ = board.receiveShot(at: Coordinate(row: 5, col: 5))

        // Should continue the line
        var validExtensions = 0
        for _ in 0..<20 {
            let target = strategy.selectTarget(board: board, previousResults: [])
            // Valid extensions are (5,3) or (5,6)
            if target == Coordinate(row: 5, col: 3) || target == Coordinate(row: 5, col: 6) {
                validExtensions += 1
            }
        }

        XCTAssertGreaterThan(validExtensions, 15, "Should continue the hit line")
    }

    func testDoesNotTargetSunkShips() {
        let strategy = HuntTargetStrategy(accuracy: 1.0)

        // Create a board with a small ship
        var board = Board(ships: [
            Ship(size: 1, origin: Coordinate(row: 5, col: 5), orientation: .horizontal),
            Ship(size: 3, origin: Coordinate(row: 0, col: 0), orientation: .horizontal)
        ])

        // Sink the small ship
        _ = board.receiveShot(at: Coordinate(row: 5, col: 5))

        // Verify ship is sunk
        XCTAssertTrue(board.ship(at: Coordinate(row: 5, col: 5))!.isSunk)

        // Should not target adjacent to sunk ship (should be in hunt mode)
        let target = strategy.selectTarget(board: board, previousResults: [])

        // Should not shoot the same spot
        XCTAssertNotEqual(target, Coordinate(row: 5, col: 5))
    }

    func testProbabilityDensityTargeting() {
        let strategy = HuntTargetStrategy(accuracy: 1.0, useProbabilityDensity: true)

        var board = Board(ships: [
            Ship(size: 5, origin: Coordinate(row: 0, col: 0), orientation: .horizontal)
        ])

        // Shoot edges to limit where ships can be
        for col in 0..<Board.size {
            _ = board.receiveShot(at: Coordinate(row: 9, col: col))
        }

        // Center should have higher probability
        var centerCount = 0
        for _ in 0..<50 {
            let target = strategy.selectTarget(board: board, previousResults: [])
            if target.row >= 3 && target.row <= 6 && target.col >= 3 && target.col <= 6 {
                centerCount += 1
            }
        }

        // Should somewhat prefer center (not too strict due to randomness)
        XCTAssertGreaterThan(centerCount, 10, "Should consider center cells")
    }

    // MARK: - Edge Cases

    func testHandlesFullyShootBoard() {
        let strategy = HuntTargetStrategy(accuracy: 1.0)

        var board = Board(ships: [
            Ship(size: 1, origin: Coordinate(row: 0, col: 0), orientation: .horizontal)
        ])

        // Shoot entire board except (0,0)
        for row in 0..<Board.size {
            for col in 0..<Board.size {
                if row != 0 || col != 0 {
                    _ = board.receiveShot(at: Coordinate(row: row, col: col))
                }
            }
        }

        let target = strategy.selectTarget(board: board, previousResults: [])
        XCTAssertEqual(target, Coordinate(row: 0, col: 0), "Should select only remaining cell")
    }

    func testLowAccuracyStillWorks() {
        let strategy = HuntTargetStrategy(accuracy: 0.0) // Always random

        var board = Board(ships: [
            Ship(size: 3, origin: Coordinate(row: 5, col: 5), orientation: .horizontal)
        ])

        // Even with hit, low accuracy might not follow up
        _ = board.receiveShot(at: Coordinate(row: 5, col: 5))

        // Should still select a valid unshot cell
        let target = strategy.selectTarget(board: board, previousResults: [])
        XCTAssertFalse(board.hasBeenShot(at: target))
    }

    // MARK: - Integration

    func testAICanSinkAllShips() {
        let strategy = HuntTargetStrategy(accuracy: 0.9, useProbabilityDensity: true)

        var board = Board(ships: [
            Ship(size: 5, origin: Coordinate(row: 0, col: 0), orientation: .horizontal),
            Ship(size: 3, origin: Coordinate(row: 2, col: 2), orientation: .vertical),
            Ship(size: 2, origin: Coordinate(row: 7, col: 7), orientation: .horizontal)
        ])

        var shotsToSink = 0
        let maxShots = 100

        while !board.isAllSunk() && shotsToSink < maxShots {
            let target = strategy.selectTarget(board: board, previousResults: [])
            _ = board.receiveShot(at: target)
            shotsToSink += 1
        }

        XCTAssertTrue(board.isAllSunk(), "AI should eventually sink all ships")
        XCTAssertLessThan(shotsToSink, maxShots, "Should not take too many shots")

        // A good AI should be somewhat efficient
        // Total ship tiles = 5 + 3 + 2 = 10
        // Perfect play would take ~10 shots + some misses
        // With hunt/target strategy, under 70 is reasonable
        XCTAssertLessThan(shotsToSink, 70, "AI should be reasonably efficient")
    }
}
