import Foundation

/// Processes turns and manages game flow
public struct TurnEngine: Sendable {

    // MARK: - Turn Validation

    /// Validate a turn action before execution
    public static func validateTurn(
        action: TurnAction,
        state: GameState,
        forPlayerIndex playerIndex: Int
    ) -> Result<Void, TurnError> {
        // Check game phase
        guard state.phase == .inProgress else {
            if state.phase == .finished {
                return .failure(.gameAlreadyOver)
            }
            return .failure(.gameNotInProgress)
        }

        // Check if it's the player's turn
        guard state.currentPlayerIndex == playerIndex else {
            return .failure(.notYourTurn)
        }

        // Validate power-up if used
        if let powerUp = action.powerUp {
            if let error = validatePowerUp(powerUp, state: state, playerIndex: playerIndex) {
                return .failure(error)
            }
        }

        // Validate shot coordinate
        let boardSize = state.boardDimension
        guard action.shot.isValid(forBoardSize: boardSize) else {
            return .failure(.invalidCoordinate(action.shot))
        }

        // Check if already shot here
        let opponent = state.player(at: 1 - playerIndex)
        if opponent.board.hasBeenShot(at: action.shot) {
            return .failure(.alreadyShotHere(action.shot))
        }

        return .success(())
    }

    /// Validate a power-up action
    private static func validatePowerUp(
        _ action: PowerUpAction,
        state: GameState,
        playerIndex: Int
    ) -> TurnError? {
        let player = state.player(at: playerIndex)
        let boardSize = state.boardDimension

        // Check ranked first turn restriction
        if state.isFirstPlayerFirstTurn && playerIndex == state.firstPlayerIndex {
            return .powerUpForbiddenFirstTurn
        }

        // Check if power-up is available
        let type = action.type
        guard player.powerUpKit.isAvailable(type) else {
            return .powerUpNotAvailable(type)
        }

        // Validate power-up parameters
        switch action {
        case .sonarPing(let center):
            if !center.isValid(forBoardSize: boardSize) {
                return .invalidCoordinate(center)
            }
        case .rowScan(let row):
            if row < 0 || row >= boardSize {
                return .invalidRow(row)
            }
        }

        return nil
    }

    // MARK: - Turn Execution

    /// Execute a turn and update game state
    /// - Parameters:
    ///   - action: The turn action to execute
    ///   - state: The game state (will be modified)
    /// - Returns: The result of the turn, or an error
    public static func processTurn(
        action: TurnAction,
        state: inout GameState
    ) -> Result<TurnResult, TurnError> {
        let playerIndex = state.currentPlayerIndex

        // Validate the turn
        if case .failure(let error) = validateTurn(action: action, state: state, forPlayerIndex: playerIndex) {
            return .failure(error)
        }

        let playerID = state.currentPlayer.id
        var powerUpResult: PowerUpResult?

        // Process power-up if used
        if let powerUpAction = action.powerUp {
            powerUpResult = executePowerUp(powerUpAction, state: &state, playerIndex: playerIndex)
        }

        // Process shot
        let shotResult = executeShot(action.shot, state: &state, playerIndex: playerIndex)

        // Create turn result
        let turnResult = TurnResult(
            powerUpResult: powerUpResult,
            shotCoordinate: action.shot,
            shotResult: shotResult,
            playerID: playerID,
            turnNumber: state.turnNumber
        )

        // Record in history
        state.recordTurn(turnResult)

        // Check for win condition
        let opponentIndex = 1 - playerIndex
        let opponent = state.player(at: opponentIndex)
        if opponent.board.isAllSunk() {
            state.setWinner(playerID)
        } else {
            // Advance to next turn (no extra turn on hit)
            state.advanceTurn()
        }

        return .success(turnResult)
    }

    // MARK: - Power-Up Execution

    private static func executePowerUp(
        _ action: PowerUpAction,
        state: inout GameState,
        playerIndex: Int
    ) -> PowerUpResult {
        let boardSize = state.boardDimension

        // Consume the power-up from player's kit
        var player = state.player(at: playerIndex)
        player.powerUpKit.consume(action.type)
        state.setPlayer(player, at: playerIndex)

        // Get opponent's board
        let opponentIndex = 1 - playerIndex
        let opponent = state.player(at: opponentIndex)

        // Check for ship presence in affected area
        let affectedCoords = action.affectedCoordinates(boardSize: boardSize)
        let detected = opponent.board.hasShipInAny(of: affectedCoords)

        // For sonar, find actual ship coordinates (for visual pulse)
        var detectedCoordinates: [Coordinate] = []
        if case .sonarPing = action {
            detectedCoordinates = affectedCoords.filter { opponent.board.hasShip(at: $0) }
        }
        // Row scan only returns detected bool, not specific coordinates

        return PowerUpResult(action: action, detected: detected, detectedCoordinates: detectedCoordinates)
    }

    // MARK: - Shot Execution

    private static func executeShot(
        _ coordinate: Coordinate,
        state: inout GameState,
        playerIndex: Int
    ) -> ShotResult {
        let opponentIndex = 1 - playerIndex
        var opponent = state.player(at: opponentIndex)

        let (hit, ship, sunk) = opponent.board.receiveShot(at: coordinate)
        state.setPlayer(opponent, at: opponentIndex)

        if sunk, let sunkShip = ship {
            // In ranked mode, don't reveal ship size
            let revealedSize: Int? = state.mode == .ranked ? nil : sunkShip.size
            return .sunk(shipSize: revealedSize)
        } else if hit {
            return .hit
        } else {
            return .miss
        }
    }

    // MARK: - Query Methods

    /// Check if a specific power-up type can be used by the current player
    public static func canUsePowerUp(
        type: PowerUpType,
        in state: GameState
    ) -> Bool {
        // Check if power-ups are allowed this turn
        guard state.currentPlayerCanUsePowerUps else {
            return false
        }

        // Check if player has any remaining
        return state.currentPlayer.powerUpKit.isAvailable(type)
    }

    /// Get all available power-up types for the current player
    public static func availablePowerUps(in state: GameState) -> [PowerUpType] {
        guard state.currentPlayerCanUsePowerUps else {
            return []
        }
        return state.currentPlayer.powerUpKit.availableTypes
    }

    /// Get all valid shot coordinates for the current player
    public static func validShotCoordinates(in state: GameState) -> [Coordinate] {
        let boardSize = state.boardDimension
        let opponentIndex = 1 - state.currentPlayerIndex
        let opponent = state.player(at: opponentIndex)

        var valid: [Coordinate] = []
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                let coord = Coordinate(row: row, col: col)
                if !opponent.board.hasBeenShot(at: coord) {
                    valid.append(coord)
                }
            }
        }
        return valid
    }

    // MARK: - Coin Flip (Ranked)

    /// Perform coin flip to determine first player in ranked mode
    /// - Returns: Index of the player who goes first (0 or 1)
    public static func performCoinFlip(state: inout GameState) -> Int {
        let firstPlayer = Int.random(in: 0...1)
        state.firstPlayerIndex = firstPlayer
        state.currentPlayerIndex = firstPlayer
        state.phase = .inProgress
        return firstPlayer
    }

    // MARK: - Phase Transitions

    /// Transition from placement to coin flip (ranked) or in progress (casual)
    public static func finishPlacement(state: inout GameState) {
        switch state.mode {
        case .ranked:
            state.phase = .coinFlip
        case .casual:
            // In casual, player 1 (human) always goes first
            state.firstPlayerIndex = 0
            state.currentPlayerIndex = 0
            state.phase = .inProgress
        }
    }
}
