import SwiftUI
import GameEngine

struct OnlineMatchPlayView: View {
    @ObservedObject var viewModel: OnlineGameViewModel
    @State private var showingLocalBoard = false
    @State private var isActing = false
    @State private var showingForfeitConfirm = false
    @State private var isForfeiting = false

    private var isYourTurn: Bool { viewModel.status == .yourTurn }
    private var isFinished: Bool { viewModel.status == .finished }

    var body: some View {
        ZStack {
            AnimatedOceanBackground()

            VStack(spacing: 12) {
                statusHeader

                if isYourTurn {
                    banners
                }

                boardSection

                controls

                if isYourTurn && !showingLocalBoard {
                    OnlinePowerUpBar(viewModel: viewModel)
                    powerUpInstruction
                }

                Spacer()
            }
            .padding(.top, 8)
            .padding(.horizontal, 16)
        }
        .sheet(isPresented: $viewModel.showingPowerUpResult) {
            if let result = viewModel.lastPowerUpResult {
                PowerUpResultView(result: result) { viewModel.dismissPowerUpResult() }
                    .presentationDetents([.height(220)])
            }
        }
        .confirmationDialog(
            "Forfeit this match?",
            isPresented: $showingForfeitConfirm,
            titleVisibility: .visible
        ) {
            Button("Forfeit", role: .destructive) {
                isForfeiting = true
                Task {
                    await viewModel.forfeit()
                    isForfeiting = false
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your opponent will be recorded as the winner. This can't be undone.")
        }
    }

    // MARK: - Sections

    private var statusHeader: some View {
        VStack(spacing: 4) {
            switch viewModel.status {
            case .yourTurn:
                Text("Your Turn")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.green)
                Text(viewModel.selectedPowerUp == nil
                     ? "Tap a cell on Enemy Waters to fire."
                     : "Tap the board to use your power-up (uses your turn).")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            case .waitingForOpponent:
                Text("Waiting for \(viewModel.opponentDisplayName)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.orange)
                Text(viewModel.awaitingResult
                     ? "Move sent — you'll see the result on your next turn."
                     : "You can close the app — you'll be notified when it's your turn.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            case .finished:
                Text(viewModel.winnerLabel ?? "Match Over")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
            case .loading:
                ProgressView().tint(.white)
            case .placement:
                Text("Placement").font(.headline).foregroundStyle(.white)
            case .error(let message):
                Text(message).foregroundStyle(.red)
            }

            Text("Enemy ships sunk: \(viewModel.opponentShipsSunk)/\(viewModel.totalShips)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    @ViewBuilder
    private var banners: some View {
        VStack(spacing: 8) {
            if let enemy = viewModel.lastOpponentTurnResult {
                ResultCard(title: "ENEMY ATTACK", result: enemy, gameMode: viewModel.gameMode, isEnemy: true)
            }
            if let mine = viewModel.lastTurnResult {
                ResultCard(title: "YOUR LAST SHOT", result: mine, gameMode: viewModel.gameMode, isEnemy: false)
            }
        }
    }

    private var boardSection: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: showingLocalBoard ? "shield.fill" : "scope")
                    .foregroundStyle(showingLocalBoard ? .cyan : .orange)
                Text(showingLocalBoard ? "Your Fleet" : "Enemy Waters")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            if showingLocalBoard {
                BoardView(
                    board: viewModel.localBoard,
                    isOpponentBoard: false,
                    showShips: true,
                    recentShotCoordinate: viewModel.lastOpponentTurnResult?.shotCoordinate
                )
            } else {
                BoardView(
                    board: Board(boardSize: viewModel.currentBoardSize),
                    isOpponentBoard: true,
                    sonarPulseCoordinates: viewModel.sonarPulseCoordinates,
                    sonarScanArea: viewModel.sonarScanArea,
                    showingSonarPulse: viewModel.showingSonarPulse,
                    rowScanHighlight: viewModel.rowScanHighlight,
                    recentShotCoordinate: viewModel.lastTurnResult?.shotCoordinate,
                    explicitCellStates: viewModel.opponentCellStates,
                    onCellTap: { coord in handleTap(coord) }
                )
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation { showingLocalBoard.toggle() }
            } label: {
                HStack {
                    Image(systemName: showingLocalBoard ? "scope" : "shield")
                    Text(showingLocalBoard ? "View Enemy" : "View Fleet")
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

            Button(role: .destructive) {
                showingForfeitConfirm = true
            } label: {
                HStack {
                    Image(systemName: "flag.fill")
                    Text("Forfeit")
                }
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.red.opacity(0.25))
                        .overlay(Capsule().stroke(Color.red.opacity(0.6), lineWidth: 1))
                )
            }
            .disabled(isForfeiting || isFinished)
        }
    }

    @ViewBuilder
    private var powerUpInstruction: some View {
        if let powerUp = viewModel.selectedPowerUp {
            VStack(spacing: 4) {
                Text(powerUp == .sonarPing
                     ? "Sonar: reveals ships in a 3×3 area"
                     : "Row Scan: detects if any ships are in a row")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Text("Tap the board to use it — this uses your turn, and the reading arrives next turn.")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.cyan)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white.opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.cyan.opacity(0.5), lineWidth: 1))
            )
        }
    }

    private func handleTap(_ coord: Coordinate) {
        guard isYourTurn, !isActing else { return }
        isActing = true
        Task {
            if let powerUp = viewModel.selectedPowerUp {
                await viewModel.usePowerUp(powerUp, at: coord)
            } else {
                await viewModel.fireShot(at: coord)
            }
            isActing = false
        }
    }
}

/// Compact power-up selector for online play. Selecting a power-up then tapping
/// the board spends the turn on that power-up.
struct OnlinePowerUpBar: View {
    @ObservedObject var viewModel: OnlineGameViewModel

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
                        viewModel.selectPowerUp(isSelected ? nil : type)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: type == .sonarPing ? "dot.radiowaves.left.and.right" : "line.horizontal.3")
                                .font(.title2)
                                .foregroundStyle(isSelected ? .cyan : .white)
                            Text(type == .sonarPing ? "Sonar" : "Row Scan")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.white)
                            Text(countText(for: type))
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(isAvailable ? .cyan : .white.opacity(0.4))
                        }
                        .frame(minWidth: 80)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected ? .cyan.opacity(0.2) : .white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isSelected ? .cyan : .white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                                )
                        )
                    }
                    .disabled(!isAvailable)
                    .opacity(isAvailable ? 1 : 0.4)
                    .accessibilityLabel("\(type == .sonarPing ? "Sonar Ping" : "Row Scan"), \(countText(for: type))")
                }

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
                    .accessibilityLabel("Cancel power-up")
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.2), lineWidth: 1))
        )
    }

    private func countText(for type: PowerUpType) -> String {
        guard let kit = viewModel.remainingKit else { return "0 left" }
        switch type {
        case .sonarPing: return "\(kit.sonarPingRemaining) left"
        case .rowScan: return "\(kit.rowScanRemaining) left"
        }
    }
}
