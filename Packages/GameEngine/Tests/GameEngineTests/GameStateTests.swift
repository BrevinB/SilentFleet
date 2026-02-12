import XCTest
@testable import GameEngine

final class GameStateTests: XCTestCase {

    // MARK: - Initialization Tests

    func testSoloGameInitialization() {
        let state = GameState.soloGame(mode: .casual, aiDifficulty: .medium)

        XCTAssertEqual(state.mode, .casual)
        XCTAssertEqual(state.aiDifficulty, .medium)
        XCTAssertTrue(state.player1.isHuman)
        XCTAssertFalse(state.player2.isHuman)
        XCTAssertEqual(state.phase, .placement)
        XCTAssertEqual(state.turnNumber, 1)
        XCTAssertNil(state.winner)
        XCTAssertTrue(state.turnHistory.isEmpty)
    }

    func testRankedGameHasCorrectPowerUps() {
        let state = GameState.soloGame(mode: .ranked, aiDifficulty: .hard)

        XCTAssertEqual(state.player1.powerUpKit.sonarPingRemaining, 1)
        XCTAssertEqual(state.player1.powerUpKit.rowScanRemaining, 1)
        XCTAssertEqual(state.player2.powerUpKit.sonarPingRemaining, 1)
        XCTAssertEqual(state.player2.powerUpKit.rowScanRemaining, 1)
    }

    func testCasualGameHasCorrectPowerUps() {
        let state = GameState.soloGame(mode: .casual, aiDifficulty: .easy)

        XCTAssertEqual(state.player1.powerUpKit.sonarPingRemaining, 2)
        XCTAssertEqual(state.player1.powerUpKit.rowScanRemaining, 2)
        XCTAssertEqual(state.player2.powerUpKit.sonarPingRemaining, 2)
        XCTAssertEqual(state.player2.powerUpKit.rowScanRemaining, 2)
    }

    // MARK: - Player Access Tests

    func testCurrentPlayerAndOpponent() {
        var state = GameState.soloGame(mode: .casual, aiDifficulty: .easy)
        state.currentPlayerIndex = 0

        XCTAssertEqual(state.currentPlayer.id, state.player1.id)
        XCTAssertEqual(state.opponent.id, state.player2.id)

        state.currentPlayerIndex = 1

        XCTAssertEqual(state.currentPlayer.id, state.player2.id)
        XCTAssertEqual(state.opponent.id, state.player1.id)
    }

    func testPlayerByIndex() {
        let state = GameState.soloGame(mode: .casual, aiDifficulty: .easy)

        XCTAssertEqual(state.player(at: 0).id, state.player1.id)
        XCTAssertEqual(state.player(at: 1).id, state.player2.id)
    }

    func testPlayerByID() {
        let state = GameState.soloGame(mode: .casual, aiDifficulty: .easy)

        XCTAssertEqual(state.player(withID: state.player1.id)?.id, state.player1.id)
        XCTAssertEqual(state.player(withID: state.player2.id)?.id, state.player2.id)
        XCTAssertNil(state.player(withID: UUID()))
    }

    func testPlayerIndex() {
        let state = GameState.soloGame(mode: .casual, aiDifficulty: .easy)

        XCTAssertEqual(state.playerIndex(for: state.player1.id), 0)
        XCTAssertEqual(state.playerIndex(for: state.player2.id), 1)
        XCTAssertNil(state.playerIndex(for: UUID()))
    }

    // MARK: - Turn Management Tests

    func testAdvanceTurn() {
        var state = GameState.soloGame(mode: .casual, aiDifficulty: .easy)
        state.currentPlayerIndex = 0
        state.turnNumber = 1

        state.advanceTurn()
        XCTAssertEqual(state.currentPlayerIndex, 1)
        XCTAssertEqual(state.turnNumber, 1)  // Turn number stays same until back to player 0

        state.advanceTurn()
        XCTAssertEqual(state.currentPlayerIndex, 0)
        XCTAssertEqual(state.turnNumber, 2)  // Now increments

        state.advanceTurn()
        XCTAssertEqual(state.currentPlayerIndex, 1)
        XCTAssertEqual(state.turnNumber, 2)
    }

    func testSetPlayer() {
        var state = GameState.soloGame(mode: .casual, aiDifficulty: .easy)
        var modifiedPlayer = state.player1
        modifiedPlayer.powerUpKit.sonarPingRemaining = 0

        state.setPlayer(modifiedPlayer, at: 0)

        XCTAssertEqual(state.player1.powerUpKit.sonarPingRemaining, 0)
    }

    // MARK: - Ranked First Turn Restriction Tests

    func testIsFirstPlayerFirstTurn() {
        var state = GameState.soloGame(mode: .ranked, aiDifficulty: .easy)
        state.phase = .inProgress
        state.firstPlayerIndex = 0
        state.currentPlayerIndex = 0
        state.turnNumber = 1

        XCTAssertTrue(state.isFirstPlayerFirstTurn)
        XCTAssertFalse(state.currentPlayerCanUsePowerUps)

        // Second player's turn
        state.currentPlayerIndex = 1
        XCTAssertFalse(state.isFirstPlayerFirstTurn)
        XCTAssertTrue(state.currentPlayerCanUsePowerUps)

        // First player's second turn
        state.currentPlayerIndex = 0
        state.turnNumber = 2
        XCTAssertFalse(state.isFirstPlayerFirstTurn)
        XCTAssertTrue(state.currentPlayerCanUsePowerUps)
    }

    func testCasualModeNoPowerUpRestriction() {
        var state = GameState.soloGame(mode: .casual, aiDifficulty: .easy)
        state.phase = .inProgress
        state.firstPlayerIndex = 0
        state.currentPlayerIndex = 0
        state.turnNumber = 1

        XCTAssertFalse(state.isFirstPlayerFirstTurn)  // Only applies to ranked
        XCTAssertTrue(state.currentPlayerCanUsePowerUps)
    }

    // MARK: - Win Condition Tests

    func testSetWinner() {
        var state = GameState.soloGame(mode: .casual, aiDifficulty: .easy)
        state.phase = .inProgress

        state.setWinner(state.player1.id)

        XCTAssertEqual(state.winner, state.player1.id)
        XCTAssertEqual(state.phase, .finished)
        XCTAssertTrue(state.isGameOver)
    }

    // MARK: - History Tests

    func testRecordTurn() {
        var state = GameState.soloGame(mode: .casual, aiDifficulty: .easy)
        XCTAssertTrue(state.turnHistory.isEmpty)

        let turnResult = TurnResult(
            powerUpResult: nil,
            shotCoordinate: Coordinate(row: 5, col: 5),
            shotResult: .miss,
            playerID: state.player1.id,
            turnNumber: 1
        )

        state.recordTurn(turnResult)

        XCTAssertEqual(state.turnHistory.count, 1)
        XCTAssertEqual(state.turnHistory[0].shotCoordinate, Coordinate(row: 5, col: 5))
    }

    // MARK: - Serialization Tests

    func testEncodeDecode() throws {
        var state = GameState.soloGame(
            mode: .ranked,
            aiDifficulty: .hard,
            rankedSplitOrientation: .topBottom
        )
        state.phase = .inProgress
        state.turnNumber = 5
        state.currentPlayerIndex = 1
        state.firstPlayerIndex = 0

        // Add a ship
        let ship = Ship(size: 3, origin: Coordinate(row: 0, col: 0), orientation: .horizontal)
        state.player1.board.addShip(ship)

        let data = try state.encode()
        let decoded = try GameState.decode(from: data)

        XCTAssertEqual(state.id, decoded.id)
        XCTAssertEqual(state.mode, decoded.mode)
        XCTAssertEqual(state.aiDifficulty, decoded.aiDifficulty)
        XCTAssertEqual(state.phase, decoded.phase)
        XCTAssertEqual(state.turnNumber, decoded.turnNumber)
        XCTAssertEqual(state.currentPlayerIndex, decoded.currentPlayerIndex)
        XCTAssertEqual(state.firstPlayerIndex, decoded.firstPlayerIndex)
        XCTAssertEqual(state.rankedSplitOrientation, decoded.rankedSplitOrientation)
        XCTAssertEqual(state.player1.board.ships.count, decoded.player1.board.ships.count)
    }

    func testSerializationRoundTrip() throws {
        // Create a game with some history
        var state = GameState.soloGame(mode: .casual, aiDifficulty: .medium)
        state.phase = .inProgress
        state.firstPlayerIndex = 0

        let turnResult = TurnResult(
            powerUpResult: PowerUpResult(
                action: .sonarPing(center: Coordinate(row: 5, col: 5)),
                detected: true
            ),
            shotCoordinate: Coordinate(row: 3, col: 7),
            shotResult: .hit,
            playerID: state.player1.id,
            turnNumber: 1
        )
        state.recordTurn(turnResult)

        let data = try state.encode()
        let decoded = try GameState.decode(from: data)

        XCTAssertEqual(decoded.turnHistory.count, 1)
        XCTAssertEqual(decoded.turnHistory[0].shotCoordinate, Coordinate(row: 3, col: 7))
        XCTAssertNotNil(decoded.turnHistory[0].powerUpResult)
        XCTAssertTrue(decoded.turnHistory[0].powerUpResult!.detected)
    }

    // MARK: - Board Split Tests

    func testBoardSplitTopBottom() {
        let split = BoardSplit.topBottom

        // Top half
        XCTAssertTrue(split.isInFirstHalf(Coordinate(row: 0, col: 5)))
        XCTAssertTrue(split.isInFirstHalf(Coordinate(row: 4, col: 5)))

        // Bottom half
        XCTAssertTrue(split.isInSecondHalf(Coordinate(row: 5, col: 5)))
        XCTAssertTrue(split.isInSecondHalf(Coordinate(row: 9, col: 5)))

        XCTAssertEqual(split.firstHalfName, "top")
        XCTAssertEqual(split.secondHalfName, "bottom")
    }

    func testBoardSplitLeftRight() {
        let split = BoardSplit.leftRight

        // Left half
        XCTAssertTrue(split.isInFirstHalf(Coordinate(row: 5, col: 0)))
        XCTAssertTrue(split.isInFirstHalf(Coordinate(row: 5, col: 4)))

        // Right half
        XCTAssertTrue(split.isInSecondHalf(Coordinate(row: 5, col: 5)))
        XCTAssertTrue(split.isInSecondHalf(Coordinate(row: 5, col: 9)))

        XCTAssertEqual(split.firstHalfName, "left")
        XCTAssertEqual(split.secondHalfName, "right")
    }
}
