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

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 20)

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

                    // Streak indicator
                    if isVictory {
                        StreakBadgeView(streak: PlayerStats.shared.currentWinStreak)
                    }

                    // Stats
                    if let state = viewModel.gameState {
                        StatsView(state: state)
                    }

                    // Coin reward
                    if let reward = viewModel.coinReward {
                        CoinRewardView(reward: reward)
                    }

                    // Newly unlocked achievements
                    if !viewModel.newlyUnlockedAchievements.isEmpty {
                        AchievementUnlockView(achievements: viewModel.newlyUnlockedAchievements)
                    }

                    // Actions
                    VStack(spacing: 12) {
                        Button {
                            HapticManager.shared.buttonTap()
                            SoundManager.shared.buttonTap()
                            viewModel.startNewGame(
                                mode: viewModel.gameMode,
                                difficulty: viewModel.aiDifficulty,
                                split: viewModel.boardSplit,
                                gridSize: viewModel.gridSize
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
                            HapticManager.shared.buttonTap()
                            SoundManager.shared.buttonTap()
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
    }

    private var isVictory: Bool {
        guard let state = viewModel.gameState else { return false }
        return state.winner == state.player1.id
    }
}

// MARK: - Streak Badge

struct StreakBadgeView: View {
    let streak: Int

    var body: some View {
        if streak >= 2 {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("\(streak) Win Streak!")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.orange)
                Text("+\(CoinManager.streakBonus(for: streak)) bonus")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.yellow)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.orange.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(.orange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Achievement Unlock Banner

struct AchievementUnlockView: View {
    let achievements: [Achievement]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("Achievement\(achievements.count > 1 ? "s" : "") Unlocked!")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            ForEach(achievements) { achievement in
                HStack(spacing: 12) {
                    Image(systemName: achievement.icon)
                        .font(.title3)
                        .foregroundStyle(.cyan)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(.cyan.opacity(0.15)))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(achievement.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(achievement.description)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    HStack(spacing: 3) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                        Text("+\(achievement.coinReward)")
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(.yellow)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.cyan.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.cyan.opacity(0.25), lineWidth: 1)
                )
        )
        .padding(.horizontal)
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

struct CoinRewardView: View {
    let reward: CoinReward

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundStyle(.yellow)
                Text("Coins Earned")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            VStack(spacing: 6) {
                if reward.winBonus > 0 {
                    rewardRow(label: "Victory Bonus", amount: reward.winBonus)
                }
                if reward.sinkBonus > 0 {
                    rewardRow(label: "Ships Sunk", amount: reward.sinkBonus)
                }
                rewardRow(label: "Completion", amount: reward.completionBonus)
                if reward.streakBonus > 0 {
                    rewardRow(label: "Streak Bonus", amount: reward.streakBonus, color: .orange)
                }
                if reward.difficultyBonus > 0 {
                    rewardRow(label: "Difficulty Bonus", amount: reward.difficultyBonus, color: .cyan)
                }

                Divider().overlay(.white.opacity(0.2))

                HStack {
                    Text("Total")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("+\(reward.total)")
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(.yellow)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.yellow.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }

    private func rewardRow(label: String, amount: Int, color: Color = .yellow) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text("+\(amount)")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(color)
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
