import Foundation
import GameEngine
import Combine

/// A single achievement definition
struct Achievement: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let coinReward: Int
    let isSecret: Bool

    /// Check function - returns true if the achievement should be unlocked
    let check: (PlayerStats, GameState?) -> Bool

    static func == (lhs: Achievement, rhs: Achievement) -> Bool {
        lhs.id == rhs.id
    }
}

/// Manages all achievement definitions and unlock state
final class AchievementManager: ObservableObject {
    static let shared = AchievementManager()

    private let defaults = UserDefaults.standard
    private let unlockedKey = "unlockedAchievements"

    @Published var unlockedIDs: Set<String> {
        didSet { defaults.set(Array(unlockedIDs), forKey: unlockedKey) }
    }

    var unlockedCount: Int { unlockedIDs.count }
    var totalCount: Int { Self.allAchievements.count }

    private init() {
        let saved = defaults.stringArray(forKey: unlockedKey) ?? []
        self.unlockedIDs = Set(saved)
    }

    func isUnlocked(_ achievement: Achievement) -> Bool {
        unlockedIDs.contains(achievement.id)
    }

    /// Evaluate all achievements against current stats. Returns newly unlocked ones.
    func evaluateAll(stats: PlayerStats, lastGameState: GameState?) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []

        for achievement in Self.allAchievements {
            guard !unlockedIDs.contains(achievement.id) else { continue }
            if achievement.check(stats, lastGameState) {
                unlockedIDs.insert(achievement.id)
                PlayerInventory.shared.addCoins(achievement.coinReward)
                newlyUnlocked.append(achievement)
            }
        }

        return newlyUnlocked
    }

    // MARK: - Achievement Definitions

    static let allAchievements: [Achievement] = [
        // -- First steps --
        Achievement(
            id: "first_victory",
            title: "First Blood",
            description: "Win your first game",
            icon: "trophy.fill",
            coinReward: 25,
            isSecret: false,
            check: { stats, _ in stats.gamesWon >= 1 }
        ),
        Achievement(
            id: "ten_victories",
            title: "Veteran Captain",
            description: "Win 10 games",
            icon: "medal.fill",
            coinReward: 50,
            isSecret: false,
            check: { stats, _ in stats.gamesWon >= 10 }
        ),
        Achievement(
            id: "fifty_victories",
            title: "Fleet Admiral",
            description: "Win 50 games",
            icon: "star.fill",
            coinReward: 150,
            isSecret: false,
            check: { stats, _ in stats.gamesWon >= 50 }
        ),
        Achievement(
            id: "hundred_games",
            title: "Seasoned Sailor",
            description: "Play 100 games",
            icon: "anchor.circle.fill",
            coinReward: 100,
            isSecret: false,
            check: { stats, _ in stats.gamesPlayed >= 100 }
        ),

        // -- Streaks --
        Achievement(
            id: "streak_3",
            title: "On a Roll",
            description: "Win 3 games in a row",
            icon: "flame.fill",
            coinReward: 40,
            isSecret: false,
            check: { stats, _ in stats.bestWinStreak >= 3 }
        ),
        Achievement(
            id: "streak_5",
            title: "Unstoppable",
            description: "Win 5 games in a row",
            icon: "flame.circle.fill",
            coinReward: 75,
            isSecret: false,
            check: { stats, _ in stats.bestWinStreak >= 5 }
        ),
        Achievement(
            id: "streak_10",
            title: "Legendary",
            description: "Win 10 games in a row",
            icon: "bolt.shield.fill",
            coinReward: 250,
            isSecret: false,
            check: { stats, _ in stats.bestWinStreak >= 10 }
        ),

        // -- Skill-based --
        Achievement(
            id: "sharpshooter",
            title: "Sharpshooter",
            description: "Achieve 70%+ accuracy in a winning game",
            icon: "scope",
            coinReward: 50,
            isSecret: false,
            check: { stats, _ in stats.bestAccuracy >= 70 }
        ),
        Achievement(
            id: "eagle_eye",
            title: "Eagle Eye",
            description: "Achieve 85%+ accuracy in a winning game",
            icon: "eye.fill",
            coinReward: 125,
            isSecret: false,
            check: { stats, _ in stats.bestAccuracy >= 85 }
        ),
        Achievement(
            id: "perfect_game",
            title: "Flawless Victory",
            description: "Win without losing a single ship",
            icon: "checkmark.shield.fill",
            coinReward: 100,
            isSecret: false,
            check: { stats, _ in stats.perfectGames >= 1 }
        ),
        Achievement(
            id: "no_powerups",
            title: "Purist",
            description: "Win a game without using any power-ups",
            icon: "hand.raised.fill",
            coinReward: 75,
            isSecret: false,
            check: { stats, _ in stats.noPowerUpWins >= 1 }
        ),

        // -- Difficulty mastery --
        Achievement(
            id: "beat_medium",
            title: "Rising Tide",
            description: "Win a game on Medium difficulty",
            icon: "water.waves",
            coinReward: 25,
            isSecret: false,
            check: { stats, _ in stats.mediumWins >= 1 }
        ),
        Achievement(
            id: "beat_hard",
            title: "Storm Chaser",
            description: "Win a game on Hard difficulty",
            icon: "cloud.bolt.fill",
            coinReward: 50,
            isSecret: false,
            check: { stats, _ in stats.hardWins >= 1 }
        ),
        Achievement(
            id: "hard_master",
            title: "Master Tactician",
            description: "Win 10 games on Hard difficulty",
            icon: "crown.fill",
            coinReward: 200,
            isSecret: false,
            check: { stats, _ in stats.hardWins >= 10 }
        ),
        Achievement(
            id: "ranked_first",
            title: "Competitive Spirit",
            description: "Win your first Ranked game",
            icon: "flag.checkered",
            coinReward: 40,
            isSecret: false,
            check: { stats, _ in stats.rankedWins >= 1 }
        ),

        // -- Sinking milestones --
        Achievement(
            id: "sink_25",
            title: "Depth Charge",
            description: "Sink 25 ships total",
            icon: "ferry.fill",
            coinReward: 40,
            isSecret: false,
            check: { stats, _ in stats.totalShipsSunk >= 25 }
        ),
        Achievement(
            id: "sink_100",
            title: "Scourge of the Seas",
            description: "Sink 100 ships total",
            icon: "tornado",
            coinReward: 100,
            isSecret: false,
            check: { stats, _ in stats.totalShipsSunk >= 100 }
        ),
        Achievement(
            id: "sink_500",
            title: "Davy Jones",
            description: "Sink 500 ships total",
            icon: "hurricane",
            coinReward: 250,
            isSecret: true,
            check: { stats, _ in stats.totalShipsSunk >= 500 }
        ),

        // -- Secret / fun --
        Achievement(
            id: "five_perfect",
            title: "Untouchable",
            description: "Win 5 perfect games (no ships lost)",
            icon: "sparkles",
            coinReward: 150,
            isSecret: true,
            check: { stats, _ in stats.perfectGames >= 5 }
        ),
        Achievement(
            id: "all_difficulties",
            title: "Jack of All Trades",
            description: "Win at least one game on each difficulty",
            icon: "list.star",
            coinReward: 75,
            isSecret: false,
            check: { stats, _ in
                stats.easyWins >= 1 && stats.mediumWins >= 1 && stats.hardWins >= 1
            }
        ),
    ]
}
