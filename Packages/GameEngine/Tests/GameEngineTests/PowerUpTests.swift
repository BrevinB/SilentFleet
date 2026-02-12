import XCTest
@testable import GameEngine

final class PowerUpTests: XCTestCase {

    // MARK: - PowerUpKit Tests

    func testRankedKitCounts() {
        let kit = PowerUpKit.rankedKit

        XCTAssertEqual(kit.sonarPingRemaining, 1)
        XCTAssertEqual(kit.rowScanRemaining, 1)
        XCTAssertEqual(kit.totalRemaining, 2)
    }

    func testCasualKitCounts() {
        let kit = PowerUpKit.casualMaxKit

        XCTAssertEqual(kit.sonarPingRemaining, 2)
        XCTAssertEqual(kit.rowScanRemaining, 2)
        XCTAssertEqual(kit.totalRemaining, 4)
    }

    func testForMode() {
        let rankedKit = PowerUpKit.forMode(.ranked)
        let casualKit = PowerUpKit.forMode(.casual)

        XCTAssertEqual(rankedKit, PowerUpKit.rankedKit)
        XCTAssertEqual(casualKit, PowerUpKit.casualMaxKit)
    }

    func testIsAvailable() {
        var kit = PowerUpKit(sonarPingRemaining: 1, rowScanRemaining: 0)

        XCTAssertTrue(kit.isAvailable(.sonarPing))
        XCTAssertFalse(kit.isAvailable(.rowScan))

        kit.sonarPingRemaining = 0
        XCTAssertFalse(kit.isAvailable(.sonarPing))
    }

    func testConsume() {
        var kit = PowerUpKit(sonarPingRemaining: 2, rowScanRemaining: 1)

        XCTAssertTrue(kit.consume(.sonarPing))
        XCTAssertEqual(kit.sonarPingRemaining, 1)

        XCTAssertTrue(kit.consume(.sonarPing))
        XCTAssertEqual(kit.sonarPingRemaining, 0)

        XCTAssertFalse(kit.consume(.sonarPing))
        XCTAssertEqual(kit.sonarPingRemaining, 0)
    }

    func testAvailableTypes() {
        var kit = PowerUpKit(sonarPingRemaining: 1, rowScanRemaining: 1)

        XCTAssertEqual(Set(kit.availableTypes), Set([.sonarPing, .rowScan]))

        kit.consume(.sonarPing)
        XCTAssertEqual(kit.availableTypes, [.rowScan])

        kit.consume(.rowScan)
        XCTAssertEqual(kit.availableTypes, [])
    }

    // MARK: - PowerUpAction Tests

    func testSonarPingAffectedCoordinates() {
        let action = PowerUpAction.sonarPing(center: Coordinate(row: 5, col: 5))
        let affected = action.affectedCoordinates

        XCTAssertEqual(affected.count, 9)

        // Check all 9 coordinates in 3x3 grid
        for dr in -1...1 {
            for dc in -1...1 {
                XCTAssertTrue(affected.contains(Coordinate(row: 5 + dr, col: 5 + dc)))
            }
        }
    }

    func testSonarPingAtCorner() {
        let action = PowerUpAction.sonarPing(center: Coordinate(row: 0, col: 0))
        let affected = action.affectedCoordinates

        // Only 4 valid coordinates in corner
        XCTAssertEqual(affected.count, 4)
        XCTAssertTrue(affected.contains(Coordinate(row: 0, col: 0)))
        XCTAssertTrue(affected.contains(Coordinate(row: 0, col: 1)))
        XCTAssertTrue(affected.contains(Coordinate(row: 1, col: 0)))
        XCTAssertTrue(affected.contains(Coordinate(row: 1, col: 1)))
    }

    func testSonarPingAtEdge() {
        let action = PowerUpAction.sonarPing(center: Coordinate(row: 0, col: 5))
        let affected = action.affectedCoordinates

        // 6 valid coordinates at edge
        XCTAssertEqual(affected.count, 6)
    }

    func testRowScanAffectedCoordinates() {
        let action = PowerUpAction.rowScan(row: 3)
        let affected = action.affectedCoordinates

        XCTAssertEqual(affected.count, 10)
        for col in 0..<10 {
            XCTAssertTrue(affected.contains(Coordinate(row: 3, col: col)))
        }
    }

    func testPowerUpType() {
        let sonarAction = PowerUpAction.sonarPing(center: Coordinate(row: 5, col: 5))
        let rowAction = PowerUpAction.rowScan(row: 5)

        XCTAssertEqual(sonarAction.type, .sonarPing)
        XCTAssertEqual(rowAction.type, .rowScan)
    }

    // MARK: - PowerUpResult Tests

    func testPowerUpResultCodable() throws {
        let result = PowerUpResult(
            action: .sonarPing(center: Coordinate(row: 5, col: 5)),
            detected: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(result)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PowerUpResult.self, from: data)

        XCTAssertEqual(result, decoded)
    }

    // MARK: - Mode Limits Enforcement

    func testRankedModeEnforcesLimits() {
        var kit = PowerUpKit.forMode(.ranked)

        // Can use once
        XCTAssertTrue(kit.consume(.sonarPing))
        XCTAssertTrue(kit.consume(.rowScan))

        // Cannot exceed
        XCTAssertFalse(kit.consume(.sonarPing))
        XCTAssertFalse(kit.consume(.rowScan))
    }

    func testCasualModeEnforcesLimits() {
        var kit = PowerUpKit.forMode(.casual)

        // Can use twice
        XCTAssertTrue(kit.consume(.sonarPing))
        XCTAssertTrue(kit.consume(.sonarPing))
        XCTAssertTrue(kit.consume(.rowScan))
        XCTAssertTrue(kit.consume(.rowScan))

        // Cannot exceed cap of 2
        XCTAssertFalse(kit.consume(.sonarPing))
        XCTAssertFalse(kit.consume(.rowScan))
    }
}
