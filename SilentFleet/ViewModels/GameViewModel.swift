import SwiftUI
import GameEngine
import Combine

/// Main view model for managing game state and UI interactions
@MainActor
final class GameViewModel: ObservableObject {
    // MARK: - Published State

    @Published private(set) var gameState: GameState?
    @Published var selectedShip: Ship?
    @Published var placementOrientation: Orientation = .horizontal
    @Published var placedShips: [Ship] = []
    @Published var selectedPowerUp: PowerUpType?
    @Published var powerUpTarget: Coordinate?
    @Published var lastTurnResult: TurnResult?
    @Published var lastAITurnResult: TurnResult?
    @Published var showingPowerUpResult: Bool = false
    @Published var sonarPulseCoordinates: Set<Coordinate> = []  // Cells with detected ships (green pulse)
    @Published var sonarScanArea: Set<Coordinate> = []  // Full scanned area (blue outline)
    @Published var showingSonarPulse: Bool = false
    @Published var rowScanHighlight: Int? = nil  // Row being scanned
    @Published var errorMessage: String?
    @Published var isAIThinking: Bool = false
    @Published var showingAIResult: Bool = false
    @Published var showingPlayerBoardForAI: Bool = false  // Switch to player board before AI fires

    // MARK: - Configuration

    private(set) var gameMode: GameMode = .casual
    private(set) var aiDifficulty: AIDifficulty = .medium
    private(set) var boardSplit: BoardSplit?

    // AI targeting strategy
    private var aiTargetingStrategy: AITargetingStrategy?

    // Match store for persistence
    private let matchStore = LocalMatchStore()

    // Fleet sizes remaining to place
    @Published var remainingFleetSizes: [Int] = Board.fleetSizes

    // MARK: - Computed Properties

    var isPlacementPhase: Bool {
        gameState?.phase == .placement
    }

    var isGameInProgress: Bool {
        gameState?.phase == .inProgress
    }

    var isGameOver: Bool {
        gameState?.phase == .finished
    }

    var isPlayerTurn: Bool {
        guard let state = gameState else { return false }
        return state.currentPlayerIndex == 0 && state.phase == .inProgress && !isAIThinking
    }

    var canUsePowerUp: Bool {
        guard let state = gameState else { return false }
        return state.currentPlayerCanUsePowerUps && !state.currentPlayer.powerUpKit.availableTypes.isEmpty
    }

    var availablePowerUps: [PowerUpType] {
        guard let state = gameState else { return [] }
        return TurnEngine.availablePowerUps(in: state)
    }

    var playerBoard: Board? {
        gameState?.player1.board
    }

    var opponentBoard: Board? {
        gameState?.player2.board
    }

    var winner: String? {
        guard let state = gameState, let winnerId = state.winner else { return nil }
        if winnerId == state.player1.id {
            return "You Win!"
        } else {
            return "AI Wins!"
        }
    }

    var turnCount: Int {
        gameState?.turnNumber ?? 0
    }

    // MARK: - Game Setup

    func startNewGame(mode: GameMode, difficulty: AIDifficulty, split: BoardSplit? = nil) {
        gameMode = mode
        aiDifficulty = difficulty
        boardSplit = mode == .ranked ? (split ?? .topBottom) : nil

        // Create AI targeting strategy
        aiTargetingStrategy = AITargetingFactory.strategy(for: difficulty)

        gameState = GameState.soloGame(
            mode: mode,
            aiDifficulty: difficulty,
            rankedSplitOrientation: boardSplit
        )

        // Reset placement state
        placedShips = []
        remainingFleetSizes = Board.fleetSizes
        selectedShip = nil
        selectedPowerUp = nil
        lastTurnResult = nil
        lastAITurnResult = nil
        errorMessage = nil
        isAIThinking = false
        showingAIResult = false
    }

    // MARK: - Ship Placement

    func selectShipSize(_ size: Int) {
        guard remainingFleetSizes.contains(size) else { return }

        // Create a temporary ship for preview
        selectedShip = Ship(
            size: size,
            origin: Coordinate(row: 0, col: 0),
            orientation: placementOrientation
        )
    }

    func toggleOrientation() {
        placementOrientation = placementOrientation == .horizontal ? .vertical : .horizontal

        // Update selected ship orientation
        if let ship = selectedShip {
            selectedShip = Ship(
                size: ship.size,
                origin: ship.origin,
                orientation: placementOrientation
            )
        }
    }

    /// Auto-populate the board with randomly placed ships
    func autoPopulateShips() {
        // Use the random placement strategy to generate ships
        let strategy = RandomPlacement()
        let allFleetSizes = Board.fleetSizes

        let ships = strategy.generatePlacement(
            for: allFleetSizes,
            mode: gameMode,
            splitOrientation: boardSplit
        )

        // Replace current placement with generated ships
        placedShips = ships
        remainingFleetSizes = []
        selectedShip = nil

        HapticManager.shared.shipPlaced()
    }

    func canPlaceShip(at coordinate: Coordinate) -> Bool {
        guard let selected = selectedShip else { return false }

        let testShip = Ship(
            size: selected.size,
            origin: coordinate,
            orientation: placementOrientation
        )

        guard testShip.isWithinBounds else { return false }

        if case .success = PlacementValidator.canPlace(ship: testShip, on: placedShips) {
            return true
        }
        return false
    }

    func placeShip(at coordinate: Coordinate) -> Bool {
        guard let selected = selectedShip else { return false }

        let newShip = Ship(
            size: selected.size,
            origin: coordinate,
            orientation: placementOrientation
        )

        // Validate placement
        let result = PlacementValidator.canPlace(ship: newShip, on: placedShips)

        switch result {
        case .success:
            placedShips.append(newShip)

            // Remove size from remaining
            if let index = remainingFleetSizes.firstIndex(of: newShip.size) {
                remainingFleetSizes.remove(at: index)
            }

            HapticManager.shared.shipPlaced()
            selectedShip = nil
            return true

        case .failure(let error):
            HapticManager.shared.invalidPlacement()
            errorMessage = error.localizedDescription
            return false
        }
    }

    func removeShip(_ ship: Ship) {
        placedShips.removeAll { $0.id == ship.id }
        remainingFleetSizes.append(ship.size)
        remainingFleetSizes.sort(by: >)
    }

    func confirmPlacement() -> Bool {
        guard var state = gameState else { return false }

        // Validate full fleet
        let result = PlacementValidator.validate(
            ships: placedShips,
            mode: gameMode,
            splitOrientation: boardSplit
        )

        switch result {
        case .success:
            // Set player's board
            state.player1.board = Board(ships: placedShips)

            // Generate AI placement
            let aiStrategy = AIPlacementFactory.strategy(for: aiDifficulty)
            let aiShips = aiStrategy.generatePlacement(
                for: Board.fleetSizes,
                mode: gameMode,
                splitOrientation: boardSplit
            )
            state.player2.board = Board(ships: aiShips)

            // Transition to next phase
            TurnEngine.finishPlacement(state: &state)

            // If ranked, do coin flip
            if gameMode == .ranked && state.phase == .coinFlip {
                let firstPlayer = TurnEngine.performCoinFlip(state: &state)
                // If AI goes first, execute their turn after a delay
                if firstPlayer == 1 {
                    gameState = state
                    Task {
                        try? await Task.sleep(for: .milliseconds(500))
                        await executeAITurn()
                    }
                    return true
                }
            }

            gameState = state
            saveGame()
            return true

        case .failure(let error):
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Gameplay

    func selectPowerUp(_ type: PowerUpType?) {
        selectedPowerUp = type
        powerUpTarget = nil
    }

    func setPowerUpTarget(_ coordinate: Coordinate) {
        guard selectedPowerUp != nil else { return }
        powerUpTarget = coordinate
    }

    /// Use a power-up immediately (doesn't consume your turn)
    func usePowerUp() {
        guard var state = gameState,
              isPlayerTurn,
              let powerUp = selectedPowerUp,
              let target = powerUpTarget else { return }

        // Build the power-up action
        let action: PowerUpAction
        switch powerUp {
        case .sonarPing:
            action = .sonarPing(center: target)
        case .rowScan:
            action = .rowScan(row: target.row)
        }

        // Validate power-up can be used
        let playerIndex = state.currentPlayerIndex
        let player = state.player(at: playerIndex)
        guard player.powerUpKit.isAvailable(powerUp) else {
            errorMessage = "No \(powerUp == .sonarPing ? "Sonar" : "Row Scan") remaining"
            return
        }

        // Check ranked first turn restriction
        if state.isFirstPlayerFirstTurn && playerIndex == state.firstPlayerIndex {
            errorMessage = "Cannot use power-ups on first turn in ranked mode"
            return
        }

        // Consume the power-up
        var updatedPlayer = player
        updatedPlayer.powerUpKit.consume(powerUp)
        state.setPlayer(updatedPlayer, at: playerIndex)

        // Get opponent's board and check for ships
        let opponentIndex = 1 - playerIndex
        let opponent = state.player(at: opponentIndex)
        let affectedCoords = action.affectedCoordinates
        let detected = opponent.board.hasShipInAny(of: affectedCoords)

        // For sonar, find actual ship coordinates
        var detectedCoordinates: [Coordinate] = []
        if case .sonarPing = action {
            detectedCoordinates = affectedCoords.filter { opponent.board.hasShip(at: $0) }
        }

        let result = PowerUpResult(action: action, detected: detected, detectedCoordinates: detectedCoordinates)

        // Update state
        gameState = state
        selectedPowerUp = nil
        powerUpTarget = nil

        // Show result
        switch action {
        case .sonarPing:
            sonarScanArea = Set(affectedCoords)  // Show full 3x3 scan area
            sonarPulseCoordinates = Set(result.detectedCoordinates)  // Highlight ships found
            showingSonarPulse = true
            HapticManager.shared.sonarPing()
            Task {
                try? await Task.sleep(for: .seconds(2.5))
                await MainActor.run {
                    showingSonarPulse = false
                    sonarPulseCoordinates = []
                    sonarScanArea = []
                }
            }
        case .rowScan(let row):
            // Show row highlight and result
            rowScanHighlight = row
            lastPowerUpResult = result
            showingPowerUpResult = true
            HapticManager.shared.sonarPing()
            // Clear row highlight after delay
            Task {
                try? await Task.sleep(for: .seconds(3))
                await MainActor.run {
                    rowScanHighlight = nil
                }
            }
        }

        saveGame()
    }

    // Store last power-up result separately (for row scan display)
    @Published var lastPowerUpResult: PowerUpResult?

    func fireShot(at coordinate: Coordinate) {
        guard var state = gameState, isPlayerTurn else { return }

        // Fire shot only (no power-up bundled)
        let action = TurnAction(powerUp: nil, shot: coordinate)

        // Execute turn
        let result = TurnEngine.processTurn(action: action, state: &state)

        switch result {
        case .success(let turnResult):
            lastTurnResult = turnResult
            gameState = state

            // Trigger haptic feedback
            triggerShotHaptic(for: turnResult.shotResult)

            // Save after each turn
            saveGame()

            // Check for game end
            if state.isGameOver {
                triggerGameEndHaptic()
            }

            // If game not over and it's AI's turn, execute AI turn after delay
            if !state.isGameOver && state.currentPlayerIndex == 1 {
                Task {
                    await executeAITurnWithDelay()
                }
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func executeAITurnWithDelay() async {
        // First, let player see their result for a moment
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s to view player's result

        // Switch to player's board so they can watch the AI's shot
        showingPlayerBoardForAI = true

        // Brief pause for board switch animation
        try? await Task.sleep(nanoseconds: 400_000_000) // 0.4s for transition

        // Now show thinking indicator (on player's board)
        isAIThinking = true

        // Variable delay based on difficulty (harder AI "thinks" longer)
        let thinkingTime: UInt64 = switch aiDifficulty {
        case .easy: 600_000_000    // 0.6s
        case .medium: 900_000_000  // 0.9s
        case .hard: 1_200_000_000  // 1.2s
        }

        try? await Task.sleep(nanoseconds: thinkingTime)

        // Execute AI turn - shot will animate on visible player board
        await executeAITurn()

        isAIThinking = false
    }

    private func executeAITurn() async {
        guard var state = gameState, state.currentPlayerIndex == 1 else {
            isAIThinking = false
            return
        }

        // Use smart targeting strategy
        let target: Coordinate
        if let strategy = aiTargetingStrategy {
            // Get results for player 1's board (what AI has shot at)
            let aiResults = state.turnHistory.filter { $0.playerID == state.player2.id }
            target = strategy.selectTarget(board: state.player1.board, previousResults: aiResults)
        } else {
            // Fallback to random
            let validShots = TurnEngine.validShotCoordinates(in: state)
            target = validShots.randomElement() ?? Coordinate(row: 0, col: 0)
        }

        // AI doesn't use power-ups for now (could add later)
        let action = TurnAction.shotOnly(target)
        let result = TurnEngine.processTurn(action: action, state: &state)

        if case .success(let turnResult) = result {
            lastAITurnResult = turnResult
            showingAIResult = true
            gameState = state
            saveGame()

            // Haptic for AI hit (so player feels when they get hit)
            if case .hit = turnResult.shotResult {
                HapticManager.shared.hit()
            } else if case .sunk = turnResult.shotResult {
                HapticManager.shared.sunk()
            }

            // Check for game end
            if state.isGameOver {
                triggerGameEndHaptic()
            }

            // Auto-dismiss AI result after giving player time to see it
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2s to view AI result
                showingAIResult = false
                showingPlayerBoardForAI = false  // Switch back to enemy board
            }
        }
    }

    // MARK: - Save/Load

    func saveGame() {
        guard let state = gameState, !state.isGameOver else { return }
        Task {
            try? await matchStore.save(state)
        }
    }

    func loadSavedGames() async -> [GameState] {
        do {
            return try await matchStore.loadAll()
        } catch {
            return []
        }
    }

    func resumeGame(_ state: GameState) {
        gameState = state
        gameMode = state.mode
        aiDifficulty = state.aiDifficulty ?? .medium
        boardSplit = state.rankedSplitOrientation
        aiTargetingStrategy = AITargetingFactory.strategy(for: aiDifficulty)

        // Reset UI state
        selectedShip = nil
        selectedPowerUp = nil
        powerUpTarget = nil
        isAIThinking = false

        // If it's AI's turn, execute their turn
        if state.currentPlayerIndex == 1 && state.phase == .inProgress {
            Task {
                await executeAITurnWithDelay()
            }
        }
    }

    func deleteSavedGame(_ state: GameState) async {
        try? await matchStore.delete(id: state.id)
    }

    // MARK: - Haptic Feedback

    private func triggerShotHaptic(for result: ShotResult) {
        switch result {
        case .miss:
            HapticManager.shared.miss()
        case .hit:
            HapticManager.shared.hit()
        case .sunk:
            HapticManager.shared.sunk()
        }
    }

    private func triggerGameEndHaptic() {
        guard let state = gameState, let winnerId = state.winner else { return }
        if winnerId == state.player1.id {
            HapticManager.shared.gameWon()
        } else {
            HapticManager.shared.gameLost()
        }
    }

    // MARK: - UI Helpers

    func dismissPowerUpResult() {
        showingPowerUpResult = false
    }

    func dismissError() {
        errorMessage = nil
    }

    func dismissAIResult() {
        showingAIResult = false
    }

    func getCoordinateState(at coord: Coordinate, isOpponentBoard: Bool) -> CellState {
        guard let state = gameState else { return .empty }

        let board = isOpponentBoard ? state.player2.board : state.player1.board

        if board.hasBeenShot(at: coord) {
            if board.hasShip(at: coord) {
                if let ship = board.ship(at: coord), ship.isSunk {
                    return .sunk
                }
                return .hit
            } else {
                return .miss
            }
        }

        // For player's own board, show ships
        if !isOpponentBoard && board.hasShip(at: coord) {
            return .ship
        }

        return .empty
    }

    /// Check if a coordinate was just hit/missed (for animation)
    func isRecentShot(_ coord: Coordinate, isOpponentBoard: Bool) -> Bool {
        if isOpponentBoard {
            return lastTurnResult?.shotCoordinate == coord
        } else {
            return lastAITurnResult?.shotCoordinate == coord
        }
    }
}

// MARK: - Cell State

enum CellState: Equatable {
    case empty
    case ship
    case hit
    case miss
    case sunk

    var color: Color {
        switch self {
        case .empty: return .blue.opacity(0.3)
        case .ship: return .gray
        case .hit: return .red
        case .miss: return .white.opacity(0.5)
        case .sunk: return .black
        }
    }

    var symbol: String? {
        switch self {
        case .hit: return "flame.fill"
        case .miss: return "circle"
        case .sunk: return "xmark"
        default: return nil
        }
    }
}
