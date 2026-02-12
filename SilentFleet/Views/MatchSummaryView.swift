import SwiftUI
import GameEngine

struct MatchSummaryView: View {
    @ObservedObject var viewModel: GameViewModel
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Navy Background
            AnimatedOceanBackground()

            // Victory/Defeat overlay gradient
            LinearGradient(
                colors: [isVictory ? .yellow.opacity(0.15) : .red.opacity(0.15), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Result
                VStack(spacing: 16) {
                    Image(systemName: isVictory ? "trophy.fill" : "flag.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(isVictory ? .yellow : .red)
                        .shadow(color: isVictory ? .yellow.opacity(0.5) : .red.opacity(0.5), radius: 20)

                    Text(viewModel.winner ?? "Game Over")
                        .font(.largeTitle.weight(.black))
                        .foregroundStyle(.white)

                    Text(isVictory ? "Congratulations!" : "Better luck next time")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.7))
                }

                // Stats
                if let state = viewModel.gameState {
                    StatsView(state: state)
                }

                Spacer()

                // Actions
                VStack(spacing: 12) {
                    Button {
                        viewModel.startNewGame(
                            mode: viewModel.gameMode,
                            difficulty: viewModel.aiDifficulty,
                            split: viewModel.boardSplit
                        )
                    } label: {
                        Text("Play Again")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.cyan)
                            )
                    }

                    Button {
                        onDismiss()
                    } label: {
                        Text("Main Menu")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.white.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
    }

    private var isVictory: Bool {
        guard let state = viewModel.gameState else { return false }
        return state.winner == state.player1.id
    }
}

struct StatsView: View {
    let state: GameState

    var body: some View {
        VStack(spacing: 16) {
            Text("Match Statistics")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 32) {
                StatItem(
                    title: "Turns",
                    value: "\(state.turnHistory.count)"
                )

                StatItem(
                    title: "Hits",
                    value: "\(playerHits)"
                )

                StatItem(
                    title: "Accuracy",
                    value: accuracy
                )
            }

            HStack(spacing: 32) {
                StatItem(
                    title: "Ships Sunk",
                    value: "\(state.player2.board.sunkCount)"
                )

                StatItem(
                    title: "Ships Lost",
                    value: "\(state.player1.board.sunkCount)"
                )
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

    private var playerHits: Int {
        state.turnHistory
            .filter { $0.playerID == state.player1.id && $0.shotResult.isHit }
            .count
    }

    private var playerShots: Int {
        state.turnHistory
            .filter { $0.playerID == state.player1.id }
            .count
    }

    private var accuracy: String {
        guard playerShots > 0 else { return "0%" }
        let pct = Double(playerHits) / Double(playerShots) * 100
        return String(format: "%.0f%%", pct)
    }
}

struct StatItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(.cyan)

            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

#Preview {
    MatchSummaryView(viewModel: {
        let vm = GameViewModel()
        vm.startNewGame(mode: .casual, difficulty: .easy)
        return vm
    }()) {}
}
