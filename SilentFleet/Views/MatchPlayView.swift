import SwiftUI
import GameEngine
import Combine

struct MatchPlayView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var showingPlayerBoard = false
    @State private var showingGameplayTooltips = false

    // Auto-switch to player board when AI is about to attack or has attacked
    private var effectiveShowingPlayerBoard: Bool {
        if viewModel.showingPlayerBoardForAI || viewModel.showingAIResult {
            return true // Show player's board during AI turn sequence
        }
        return showingPlayerBoard
    }

    var body: some View {
        ZStack {
            // Navy Background
            AnimatedOceanBackground()

            VStack(spacing: 12) {
                // Status Header
                StatusHeaderView(viewModel: viewModel)

                // Turn Result Banner (prominent display of last action)
                TurnResultBanner(viewModel: viewModel)

                // Main Board
                VStack(spacing: 4) {
                    // Board title with context
                    HStack {
                        Image(systemName: effectiveShowingPlayerBoard ? "shield.fill" : "scope")
                            .foregroundStyle(effectiveShowingPlayerBoard ? .cyan : .orange)
                        Text(effectiveShowingPlayerBoard ? "Your Fleet" : "Enemy Waters")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .animation(.easeInOut(duration: 0.2), value: effectiveShowingPlayerBoard)

                if effectiveShowingPlayerBoard {
                    BoardView(
                        board: viewModel.playerBoard ?? Board(),
                        isOpponentBoard: false,
                        showShips: true,
                        recentShotCoordinate: viewModel.showingAIResult ? viewModel.lastAITurnResult?.shotCoordinate : nil
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                } else {
                    BoardView(
                        board: viewModel.opponentBoard ?? Board(),
                        isOpponentBoard: true,
                        highlightedCoordinates: powerUpHighlight,
                        sonarPulseCoordinates: viewModel.sonarPulseCoordinates,
                        sonarScanArea: viewModel.sonarScanArea,
                        showingSonarPulse: viewModel.showingSonarPulse,
                        rowScanHighlight: viewModel.rowScanHighlight,
                        recentShotCoordinate: viewModel.lastTurnResult?.shotCoordinate,
                        onCellTap: { coord in
                            if viewModel.isPlayerTurn {
                                if let powerUp = viewModel.selectedPowerUp {
                                    // Set target and execute power-up immediately
                                    if powerUp == .rowScan {
                                        viewModel.setPowerUpTarget(Coordinate(row: coord.row, col: 0))
                                    } else {
                                        viewModel.setPowerUpTarget(coord)
                                    }
                                    viewModel.usePowerUp()
                                } else {
                                    // No power-up selected, fire shot
                                    viewModel.fireShot(at: coord)
                                }
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: effectiveShowingPlayerBoard)

                // Toggle Board Button (disabled during AI result display)
                Button {
                    withAnimation {
                        showingPlayerBoard.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: showingPlayerBoard ? "scope" : "shield")
                        Text(showingPlayerBoard ? "View Enemy" : "View Fleet")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.15))
                            .overlay(Capsule().stroke(.white.opacity(0.3), lineWidth: 1))
                    )
                }
                .disabled(viewModel.showingAIResult || viewModel.showingPlayerBoardForAI)
                .opacity(viewModel.showingAIResult || viewModel.showingPlayerBoardForAI ? 0.5 : 1)

                // Power-up Bar
                if viewModel.isPlayerTurn && !effectiveShowingPlayerBoard {
                    PowerUpBarView(viewModel: viewModel)
                }

                // Power-up instruction
                if let powerUp = viewModel.selectedPowerUp {
                    VStack(spacing: 4) {
                        // Description of selected power-up
                        Text(powerUp == .sonarPing
                             ? "Sonar: Reveals ships in a 3x3 area briefly"
                             : "Row Scan: Detects if any ships are in a row")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))

                        Text("Tap on the board to use")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.cyan)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white.opacity(0.1))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.cyan.opacity(0.5), lineWidth: 1))
                    )
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $viewModel.showingPowerUpResult) {
            if let result = viewModel.lastPowerUpResult {
                PowerUpResultView(result: result) {
                    viewModel.dismissPowerUpResult()
                }
                .presentationDetents([.height(200)])
            }
        }
        .overlay {
            // AI Thinking Overlay
            if viewModel.isAIThinking {
                AIThinkingOverlay()
            }
        }
        .overlay {
            if showingGameplayTooltips {
                GameplayTooltipOverlay(isShowing: $showingGameplayTooltips)
            }
        }
        .onAppear {
            if !SettingsManager.shared.hasCompletedGameplayTooltips {
                showingGameplayTooltips = true
            }
        }
    }

    private var powerUpHighlight: Set<Coordinate> {
        guard let target = viewModel.powerUpTarget,
              let powerUp = viewModel.selectedPowerUp else {
            return []
        }

        let action: PowerUpAction
        switch powerUp {
        case .sonarPing:
            action = .sonarPing(center: target)
        case .rowScan:
            action = .rowScan(row: target.row)
        }

        return Set(action.affectedCoordinates)
    }
}

struct StatusHeaderView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 8) {
            // Turn indicator at top
            Text(viewModel.isPlayerTurn ? "Your Turn" : "AI Turn")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(viewModel.isPlayerTurn ? .green : .orange)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(viewModel.isPlayerTurn ? .green.opacity(0.2) : .orange.opacity(0.2))
                        .overlay(
                            Capsule().stroke(viewModel.isPlayerTurn ? .green.opacity(0.5) : .orange.opacity(0.5), lineWidth: 1)
                        )
                )

            // Fleet status
            HStack(spacing: 16) {
                // Player fleet
                FleetStatusView(
                    title: "Your Fleet",
                    board: viewModel.playerBoard,
                    alignment: .leading
                )

                Spacer()

                // Enemy fleet
                FleetStatusView(
                    title: "Enemy Fleet",
                    board: viewModel.opponentBoard,
                    alignment: .trailing
                )
            }
            .padding(.horizontal)
        }
    }
}

/// Visual display of fleet ship statuses
struct FleetStatusView: View {
    let title: String
    let board: Board?
    let alignment: HorizontalAlignment

    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)

            if let board = board {
                // Ship indicators - grouped by size for cleaner display
                let statuses = board.shipStatuses
                HStack(spacing: 3) {
                    ForEach(Array(statuses.enumerated()), id: \.offset) { _, status in
                        ShipIndicator(size: status.size, isSunk: status.isSunk)
                    }
                }
            }
        }
    }
}

/// Visual indicator for a single ship showing its size
struct ShipIndicator: View {
    let size: Int
    let isSunk: Bool
    var skin: ShipSkin = PlayerInventory.shared.equippedSkin

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<size, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 2)
                    .fill(isSunk ? skin.indicatorSunk : skin.indicatorHealthy)
                    .frame(width: 6, height: 12)
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(isSunk ? skin.indicatorSunkBackground : skin.indicatorBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(isSunk ? skin.indicatorSunkBorder : skin.indicatorBorder, lineWidth: 1)
        )
        .opacity(isSunk ? 0.6 : 1.0)
    }
}

// MARK: - Turn Result Banner

struct TurnResultBanner: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 8) {
            // Show AI's attack result (when AI just attacked)
            if viewModel.showingAIResult, let aiResult = viewModel.lastAITurnResult {
                ResultCard(
                    title: "ENEMY ATTACK",
                    result: aiResult,
                    gameMode: viewModel.gameMode,
                    isEnemy: true
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Show player's last attack result (when it's player's turn and they just shot)
            if let playerResult = viewModel.lastTurnResult, !viewModel.showingAIResult {
                ResultCard(
                    title: "YOUR ATTACK",
                    result: playerResult,
                    gameMode: viewModel.gameMode,
                    isEnemy: false
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.showingAIResult)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.lastTurnResult?.shotCoordinate)
    }
}

struct ResultCard: View {
    let title: String
    let result: TurnResult
    let gameMode: GameMode
    let isEnemy: Bool

    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon with animation
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 44, height: 44)

                Image(systemName: iconName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isEnemy ? .red : .cyan)

                Text(resultText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Text("at (\(result.shotCoordinate.row), \(result.shotCoordinate.col))")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            // Coordinate highlight
            Text("\(result.shotCoordinate.row),\(result.shotCoordinate.col)")
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(backgroundColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(backgroundColor.opacity(0.2))
                )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(backgroundColor.opacity(0.5), lineWidth: 2)
        )
        .padding(.horizontal)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3).repeatCount(2, autoreverses: true)) {
                isAnimating = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isAnimating = false
            }
        }
    }

    private var backgroundColor: Color {
        switch result.shotResult {
        case .miss: return .gray
        case .hit: return .orange
        case .sunk: return .red
        }
    }

    private var iconName: String {
        switch result.shotResult {
        case .miss: return "drop.fill"
        case .hit: return "flame.fill"
        case .sunk: return "burst.fill"
        }
    }

    private var resultText: String {
        switch result.shotResult {
        case .miss:
            return "Miss! Water splash"
        case .hit:
            return "Hit! Ship damaged"
        case .sunk(let size):
            if let s = size, gameMode == .casual {
                return "Sunk! Size-\(s) ship destroyed"
            }
            return "Sunk! Ship destroyed"
        }
    }
}

struct PowerUpBarView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 8) {
            Text("Power-Ups")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))

            HStack(spacing: 16) {
                ForEach(PowerUpType.allCases, id: \.self) { type in
                    let isAvailable = viewModel.availablePowerUps.contains(type)
                    let isSelected = viewModel.selectedPowerUp == type

                    Button {
                        if isSelected {
                            viewModel.selectPowerUp(nil)
                        } else if isAvailable {
                            viewModel.selectPowerUp(type)
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: type == .sonarPing ? "dot.radiowaves.left.and.right" : "line.horizontal.3")
                                .font(.title2)
                                .foregroundStyle(isSelected ? .cyan : .white)

                            Text(type == .sonarPing ? "Sonar" : "Row Scan")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.white)

                            // Brief description
                            Text(type == .sonarPing ? "3x3 area" : "Whole row")
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.5))

                            // Count
                            Text(countText(for: type))
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(isAvailable ? .cyan : .white.opacity(0.4))
                        }
                        .frame(minWidth: 80)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected ? .cyan.opacity(0.2) : .white.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? .cyan : .white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                        )
                    }
                    .disabled(!isAvailable)
                    .opacity(isAvailable ? 1 : 0.4)
                }

                // Cancel button when power-up selected
                if viewModel.selectedPowerUp != nil {
                    Button {
                        viewModel.selectPowerUp(nil)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundStyle(.red)
                            Text("Cancel")
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }

    private func countText(for type: PowerUpType) -> String {
        guard let state = viewModel.gameState else { return "0" }
        let kit = state.player1.powerUpKit
        switch type {
        case .sonarPing:
            return "\(kit.sonarPingRemaining) left"
        case .rowScan:
            return "\(kit.rowScanRemaining) left"
        }
    }
}

struct PowerUpResultView: View {
    let result: PowerUpResult
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: result.detected ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(result.detected ? .green : .red)

            Text(result.detected ? "Target Detected!" : "No Target Found")
                .font(.title2.weight(.bold))

            Text(descriptionText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Continue") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var descriptionText: String {
        switch result.action {
        case .sonarPing(let center):
            return result.detected
                ? "Ships detected in 3x3 area around (\(center.row), \(center.col))"
                : "No ships in 3x3 area around (\(center.row), \(center.col))"
        case .rowScan(let row):
            return result.detected
                ? "Ships detected in row \(row)"
                : "No ships in row \(row)"
        }
    }
}

struct AIThinkingOverlay: View {
    @State private var dotCount = 0
    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Animated radar icon
                Image(systemName: "scope")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse)

                HStack(spacing: 4) {
                    Text("Enemy is targeting")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(String(repeating: ".", count: dotCount + 1))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 24, alignment: .leading)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
        }
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 3
        }
    }
}

#Preview {
    NavigationStack {
        MatchPlayView(viewModel: {
            let vm = GameViewModel()
            vm.startNewGame(mode: .casual, difficulty: .easy)
            return vm
        }())
    }
}
