import SwiftUI

struct PlayerStatsView: View {
    @ObservedObject private var stats = PlayerStats.shared
    @ObservedObject private var achievements = AchievementManager.shared
    @State private var selectedTab = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AnimatedOceanBackground()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(10)
                            .background(Circle().fill(.white.opacity(0.1)))
                    }
                    Spacer()
                    Text("Commander Profile")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                    // Balance spacer
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Tab picker
                Picker("", selection: $selectedTab) {
                    Text("Stats").tag(0)
                    Text("Achievements").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Content
                if selectedTab == 0 {
                    statsContent
                } else {
                    achievementsContent
                }
            }
        }
    }

    // MARK: - Stats Tab

    private var statsContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Win/Loss overview
                overviewCard

                // Streak card
                streakCard

                // Performance card
                performanceCard

                // Difficulty breakdown
                difficultyCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    private var overviewCard: some View {
        VStack(spacing: 16) {
            Text("Battle Record")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(stats.gamesPlayed)")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.cyan)
                    Text("Played")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

                VStack(spacing: 4) {
                    Text("\(stats.gamesWon)")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.green)
                    Text("Won")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

                VStack(spacing: 4) {
                    Text("\(stats.gamesLost)")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.red)
                    Text("Lost")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

                VStack(spacing: 4) {
                    Text(String(format: "%.0f%%", stats.winRate))
                        .font(.title.weight(.bold))
                        .foregroundStyle(.yellow)
                    Text("Win Rate")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(statsCardBackground)
    }

    private var streakCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("Win Streaks")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    Text("\(stats.currentWinStreak)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(stats.currentWinStreak >= 3 ? .orange : .cyan)
                    Text("Current")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

                VStack(spacing: 4) {
                    Text("\(stats.bestWinStreak)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.yellow)
                    Text("Best")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            if stats.currentWinStreak >= 2 {
                Text("Streak bonus: +\(CoinManager.streakBonus(for: stats.currentWinStreak)) coins per win")
                    .font(.caption)
                    .foregroundStyle(.orange.opacity(0.8))
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(statsCardBackground)
    }

    private var performanceCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "scope")
                    .foregroundStyle(.cyan)
                Text("Performance")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12) {
                statCell(label: "Accuracy", value: String(format: "%.1f%%", stats.overallAccuracy))
                statCell(label: "Best Accuracy", value: stats.bestAccuracy > 0 ? String(format: "%.0f%%", stats.bestAccuracy) : "--")
                statCell(label: "Ships Sunk", value: "\(stats.totalShipsSunk)")
                statCell(label: "Ships Lost", value: "\(stats.totalShipsLost)")
                statCell(label: "Shots Fired", value: "\(stats.totalShotsFired)")
                statCell(label: "Fewest Turns Win", value: stats.fewestTurnsWin > 0 ? "\(stats.fewestTurnsWin)" : "--")
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(statsCardBackground)
    }

    private var difficultyCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(.cyan)
                Text("Difficulty Breakdown")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            VStack(spacing: 8) {
                difficultyRow(label: "Easy", wins: stats.easyWins, color: .green)
                difficultyRow(label: "Medium", wins: stats.mediumWins, color: .yellow)
                difficultyRow(label: "Hard", wins: stats.hardWins, color: .red)
                difficultyRow(label: "Ranked", wins: stats.rankedWins, color: .purple)
            }

            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("\(stats.perfectGames)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.cyan)
                    Text("Perfect Games")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

                VStack(spacing: 4) {
                    Text("\(stats.noPowerUpWins)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.cyan)
                    Text("No Power-Up Wins")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(statsCardBackground)
    }

    private func statCell(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(.cyan)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }

    private func difficultyRow(label: String, wins: Int, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
            Text("\(wins) wins")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.white)
        }
    }

    // MARK: - Achievements Tab

    private var achievementsContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Progress header
                HStack {
                    Text("\(achievements.unlockedCount)/\(achievements.totalCount) Unlocked")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 4)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white.opacity(0.1))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(.cyan)
                            .frame(
                                width: achievements.totalCount > 0
                                    ? geo.size.width * CGFloat(achievements.unlockedCount) / CGFloat(achievements.totalCount)
                                    : 0,
                                height: 8
                            )
                    }
                }
                .frame(height: 8)
                .padding(.horizontal, 4)

                // Achievement list
                ForEach(AchievementManager.allAchievements) { achievement in
                    achievementRow(achievement)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    private func achievementRow(_ achievement: Achievement) -> some View {
        let unlocked = achievements.isUnlocked(achievement)
        let showDetails = unlocked || !achievement.isSecret

        return HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(unlocked ? .cyan.opacity(0.2) : .white.opacity(0.05))
                    .frame(width: 44, height: 44)

                Image(systemName: showDetails ? achievement.icon : "lock.fill")
                    .font(.title3)
                    .foregroundStyle(unlocked ? .cyan : .white.opacity(0.3))
            }

            // Text
            VStack(alignment: .leading, spacing: 3) {
                Text(showDetails ? achievement.title : "???")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(unlocked ? .white : .white.opacity(0.5))

                Text(showDetails ? achievement.description : "Secret achievement")
                    .font(.caption)
                    .foregroundStyle(unlocked ? .white.opacity(0.7) : .white.opacity(0.3))
            }

            Spacer()

            // Reward
            if showDetails {
                HStack(spacing: 3) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.caption)
                        .foregroundStyle(unlocked ? .yellow : .yellow.opacity(0.3))
                    Text("+\(achievement.coinReward)")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(unlocked ? .yellow : .yellow.opacity(0.3))
                }
            }

            // Checkmark
            if unlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(unlocked ? .cyan.opacity(0.05) : .white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(unlocked ? .cyan.opacity(0.2) : .white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Shared

    private var statsCardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            )
    }
}

#Preview {
    PlayerStatsView()
}
