import XCTest
@testable import GameEngine

final class TurnEngineTests: XCTestCase {

    // MARK: - Setup

    private func createGameInProgress(mode: GameMode = .casual) -> GameState {
        var state = GameState.soloGame(mode: mode, aiDifficulty: .easy)

        // Set up player 1 board with ships
        let p1Ships = [
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
        state.player1.board = Board(ships: p1Ships)

        // Set up player 2 board with ships
        let p2Ships = [
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
        state.player2.board = Board(ships: p2Ships)

        state.phase = .inProgress
        state.firstPlayerIndex = 0
        state.currentPlayerIndex = 0

        return state
    }

    // MARK: - Basic Shot Tests

    func testShotMiss() {
        var state = createGameInProgress()
        let action = TurnAction.shotOnly(Coordinate(row: 9, col: 9))

        let result = TurnEngine.processTurn(action: action, state: &state)

        if case .success(let turnResult) = result {
            XCTAssertEqual(turnResult.shotResult, .miss)
            XCTAssertEqual(turnResult.shotCoordinate, Coordinate(row: 9, col: 9))
            XCTAssertNil(turnResult.powerUpResult)
        } else {
            XCTFail("Expected successful turn")
        }
    }

    func testShotHit() {
        var state = createGameInProgress()
        // Player 2's ship is at (0, 0)
        let action = TurnAction.shotOnly(Coordinate(row: 0, col: 0))

        let result = TurnEngine.processTurn(action: action, state: &state)

        if case .success(let turnResult) = result {
            XCTAssertTrue(turnResult.shotResult.isHit)
        } else {
            XCTFail("Expected successful turn")
        }
    }

    func testShotSunk() {
        var state = createGameInProgress()
        // Sink the size-1 ship at (0, 8)
        let action = TurnAction.shotOnly(Coordinate(row: 0, col: 8))

        let result = TurnEngine.processTurn(action: action, state: &state)

        if case .success(let turnResult) = result {
            XCTAssertTrue(turnResult.shotResult.isSunk)
            // Casual mode reveals ship size
            if case .sunk(let size) = turnResult.shotResult {
                XCTAssertEqual(size, 1)
            }
        } else {
            XCTFail("Expected successful turn")
        }
    }

    func testShotSunkRankedHidesSize() {
        var state = createGameInProgress(mode: .ranked)
        state.firstPlayerIndex = 0
        // Skip first turn restriction by setting turn > 1
        state.turnNumber = 2

        let action = TurnAction.shotOnly(Coordinate(row: 0, col: 8))

        let result = TurnEngine.processTurn(action: action, state: &state)

        if case .success(let turnResult) = result {
            XCTAssertTrue(turnResult.shotResult.isSunk)
            // Ranked mode hides ship size
            if case .sunk(let size) = turnResult.shotResult {
                XCTAssertNil(size)
            }
        } else {
            XCTFail("Expected successful turn")
        }
    }

    // MARK: - Turn Switching Tests

    func testNoExtraTurnOnHit() {
        var state = createGameInProgress()
        XCTAssertEqual(state.currentPlayerIndex, 0)

        // Hit
        let action = TurnAction.shotOnly(Coordinate(row: 0, col: 0))
        _ = TurnEngine.processTurn(action: action, state: &state)

        // Turn should switch even on hit
        XCTAssertEqual(state.currentPlayerIndex, 1)
    }

    func testTurnSwitchesOnMiss() {
        var state = createGameInProgress()
        XCTAssertEqual(state.currentPlayerIndex, 0)

        let action = TurnAction.shotOnly(Coordinate(row: 9, col: 9))
        _ = TurnEngine.processTurn(action: action, state: &state)

        XCTAssertEqual(state.currentPlayerIndex, 1)
    }

    // MARK: - Error Cases

    func testCannotShootSameSpotTwice() {
        var state = createGameInProgress()

        // First shot
        let action1 = TurnAction.shotOnly(Coordinate(row: 5, col: 5))
        _ = TurnEngine.processTurn(action: action1, state: &state)

        // Player 2's turn
        let action2 = TurnAction.shotOnly(Coordinate(row: 5, col: 5))
        _ = TurnEngine.processTurn(action: action2, state: &state)

        // Player 1 tries to shoot same spot
        let action3 = TurnAction.shotOnly(Coordinate(row: 5, col: 5))
        let result = TurnEngine.processTurn(action: action3, state: &state)

        if case .failure(.alreadyShotHere) = result {
            // Expected
        } else {
            XCTFail("Expected alreadyShotHere error")
        }
    }

    func testCannotShootWhenNotYourTurn() {
        var state = createGameInProgress()
        state.currentPlayerIndex = 1

        // Validate as player 0 (not their turn)
        let action = TurnAction.shotOnly(Coordinate(row: 5, col: 5))
        let result = TurnEngine.validateTurn(action: action, state: state, forPlayerIndex: 0)

        if case .failure(.notYourTurn) = result {
            // Expected
        } else {
            XCTFail("Expected notYourTurn error")
        }
    }

    func testCannotShootInvalidCoordinate() {
        var state = createGameInProgress()

        let action = TurnAction.shotOnly(Coordinate(row: -1, col: 5))
        let result = TurnEngine.processTurn(action: action, state: &state)

        if case .failure(.invalidCoordinate) = result {
            // Expected
        } else {
            XCTFail("Expected invalidCoordinate error")
        }
    }

    func testCannotPlayWhenGameNotInProgress() {
        var state = createGameInProgress()
        state.phase = .placement

        let action = TurnAction.shotOnly(Coordinate(row: 5, col: 5))
        let result = TurnEngine.processTurn(action: action, state: &state)

        if case .failure(.gameNotInProgress) = result {
            // Expected
        } else {
            XCTFail("Expected gameNotInProgress error")
        }
    }

    // MARK: - Power-Up Tests

    func testSonarPingDetectsShip() {
        var state = createGameInProgress()

        // Sonar centered at (0, 1) should detect ship at (0, 0)
        let action = TurnAction.withSonar(center: Coordinate(row: 0, col: 1), shot: Coordinate(row: 9, col: 9))
        let result = TurnEngine.processTurn(action: action, state: &state)

        if case .success(let turnResult) = result {
            XCTAssertNotNil(turnResult.powerUpResult)
            XCTAssertTrue(turnResult.powerUpResult!.detected)
        } else {
            XCTFail("Expected successful turn")
        }
    }

    func testSonarPingNoDetection() {
        var state = createGameInProgress()

        // Sonar centered at (9, 9) - no ships there
        let action = TurnAction.withSonar(center: Coordinate(row: 9, col: 9), shot: Coordinate(row: 5, col: 5))
        let result = TurnEngine.processTurn(action: action, state: &state)

        if case .success(let turnResult) = result {
            XCTAssertNotNil(turnResult.powerUpResult)
            XCTAssertFalse(turnResult.powerUpResult!.detected)
        } else {
            XCTFail("Expected successful turn")
        }
    }

    func testRowScanDetectsShip() {
        var state = createGameInProgress()

        // Scan row 0 - has ships
        let action = TurnAction.withRowScan(row: 0, shot: Coordinate(row: 9, col: 9))
        let result = TurnEngine.processTurn(action: action, state: &state)

        if case .success(let turnResult) = result {
            XCTAssertNotNil(turnResult.powerUpResult)
            XCTAssertTrue(turnResult.powerUpResult!.detected)
        } else {
            XCTFail("Expected successful turn")
        }
    }

    func testRowScanNoDetection() {
        var state = createGameInProgress()

        // Scan row 9 - no ships in test setup
        let action = TurnAction.withRowScan(row: 9, shot: Coordinate(row: 5, col: 5))
        let result = TurnEngine.processTurn(action: action, state: &state)

        if case .success(let turnResult) = result {
            XCTAssertNotNil(turnResult.powerUpResult)
            XCTAssertFalse(turnResult.powerUpResult!.detected)
        } else {
            XCTFail("Expected successful turn")
        }
    }

    func testPowerUpConsumed() {
        var state = createGameInProgress()
        let initialSonar = state.player1.powerUpKit.sonarPingRemaining

        let action = TurnAction.withSonar(center: Coordinate(row: 5, col: 5), shot: Coordinate(row: 9, col: 9))
        _ = TurnEngine.processTurn(action: action, state: &state)

        XCTAssertEqual(state.player1.powerUpKit.sonarPingRemaining, initialSonar - 1)
    }

    func testCannotUsePowerUpWhenNoneRemaining() {
        var state = createGameInProgress()
        state.player1.powerUpKit.sonarPingRemaining = 0

        let action = TurnAction.withSonar(center: Coordinate(row: 5, col: 5), shot: Coordinate(row: 9, col: 9))
        let result = TurnEngine.processTurn(action: action, state: &state)

        if case .failure(.powerUpNotAvailable) = result {
            // Expected
        } else {
            XCTFail("Expected powerUpNotAvailable error")
        }
    }

    // MARK: - Ranked First Turn Restriction

    func testRankedFirstPlayerCannotUsePowerUpOnFirstTurn() {
        var state = createGameInProgress(mode: .ranked)
        state.firstPlayerIndex = 0
        state.currentPlayerIndex = 0
        state.turnNumber = 1

        let action = TurnAction.withSonar(center: Coordinate(row: 5, col: 5), shot: Coordinate(row: 9, col: 9))
        let result = TurnEngine.processTurn(action: action, state: &state)

        if case .failure(.powerUpForbiddenFirstTurn) = result {
            // Expected
        } else {
            XCTFail("Expected powerUpForbiddenFirstTurn error, got \(result)")
        }
    }

    func testRankedSecondPlayerCanUsePowerUpOnFirstTurn() {
        var state = createGameInProgress(mode: .ranked)
        state.firstPlayerIndex = 0
        state.currentPlayerIndex = 1  // Second player
        state.turnNumber = 1

        let action = TurnAction.withSonar(center: Coordinate(row: 5, col: 5), shot: Coordinate(row: 9, col: 9))
        let result = TurnEngine.processTurn(action: action, state: &state)

        if case .success = result {
            // Expected - second player CAN use power-up
        } else {
            XCTFail("Second player should be able to use power-up on first turn")
        }
    }

    func testRankedFirstPlayerCanUsePowerUpOnSecondTurn() {
        var state = createGameInProgress(mode: .ranked)
        state.firstPlayerIndex = 0
        state.currentPlayerIndex = 0
        state.turnNumber = 2  // Second round

        let action = TurnAction.withSonar(center: Coordinate(row: 5, col: 5), shot: Coordinate(row: 9, col: 9))
        let result = TurnEngine.processTurn(action: action, state: &state)

        if case .success = result {
            // Expected - first player CAN use power-up after first turn
        } else {
            XCTFail("First player should be able to use power-up after first turn")
        }
    }

    // MARK: - Win Condition

    func testWinCondition() {
        var state = createGameInProgress()

        // Sink all of player 2's ships
        // We'll create a state where player 2 has only one 1-tile ship remaining
        state.player2.board = Board(ships: [
            Ship(size: 1, origin: Coordinate(row: 5, col: 5), orientation: .horizontal)
        ])

        let action = TurnAction.shotOnly(Coordinate(row: 5, col: 5))
        let result = TurnEngine.processTurn(action: action, state: &state)

        if case .success = result {
            XCTAssertTrue(state.isGameOver)
            XCTAssertEqual(state.winner, state.player1.id)
            XCTAssertEqual(state.phase, .finished)
        } else {
            XCTFail("Expected successful turn")
        }
    }

    // MARK: - Coin Flip Tests

    func testCoinFlip() {
        var state = createGameInProgress(mode: .ranked)
        state.phase = .coinFlip

        let firstPlayer = TurnEngine.performCoinFlip(state: &state)

        XCTAssertTrue(firstPlayer == 0 || firstPlayer == 1)
        XCTAssertEqual(state.firstPlayerIndex, firstPlayer)
        XCTAssertEqual(state.currentPlayerIndex, firstPlayer)
        XCTAssertEqual(state.phase, .inProgress)
    }

    // MARK: - History Tests

    func testTurnRecordedInHistory() {
        var state = createGameInProgress()
        XCTAssertEqual(state.turnHistory.count, 0)

        let action = TurnAction.shotOnly(Coordinate(row: 5, col: 5))
        _ = TurnEngine.processTurn(action: action, state: &state)

        XCTAssertEqual(state.turnHistory.count, 1)
        XCTAssertEqual(state.turnHistory[0].shotCoordinate, Coordinate(row: 5, col: 5))
    }

    // MARK: - Query Methods

    func testCanUsePowerUp() {
        let state = createGameInProgress()

        XCTAssertTrue(TurnEngine.canUsePowerUp(type: .sonarPing, in: state))
        XCTAssertTrue(TurnEngine.canUsePowerUp(type: .rowScan, in: state))
    }

    func testCannotUsePowerUpWhenEmpty() {
        var state = createGameInProgress()
        state.player1.powerUpKit.sonarPingRemaining = 0

        XCTAssertFalse(TurnEngine.canUsePowerUp(type: .sonarPing, in: state))
        XCTAssertTrue(TurnEngine.canUsePowerUp(type: .rowScan, in: state))
    }

    func testAvailablePowerUps() {
        var state = createGameInProgress()

        var available = TurnEngine.availablePowerUps(in: state)
        XCTAssertEqual(Set(available), Set([.sonarPing, .rowScan]))

        state.player1.powerUpKit.sonarPingRemaining = 0
        available = TurnEngine.availablePowerUps(in: state)
        XCTAssertEqual(available, [.rowScan])
    }

    func testValidShotCoordinates() {
        var state = createGameInProgress()

        var valid = TurnEngine.validShotCoordinates(in: state)
        XCTAssertEqual(valid.count, 100)  // All 100 tiles

        // Take a shot
        let action = TurnAction.shotOnly(Coordinate(row: 5, col: 5))
        _ = TurnEngine.processTurn(action: action, state: &state)

        // Player 2's turn now, check their valid shots against player 1's board
        valid = TurnEngine.validShotCoordinates(in: state)
        XCTAssertEqual(valid.count, 100)  // Still all 100 for player 2
    }
}
