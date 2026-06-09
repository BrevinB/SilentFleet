import Foundation

/// Central mapping between in-app concepts and Game Center identifiers.
///
/// Update these strings to match the IDs you actually created in App Store
/// Connect → Game Center. Leaderboard or achievement IDs that don't exist on
/// the server will be silently rejected by GameKit — that's safe but means
/// nothing will appear. Keep these in sync with your ASC configuration.
enum GameCenterIDs {
    // MARK: - Leaderboards

    enum Leaderboard {
        /// Lifetime wins (all modes combined).
        static let lifetimeWins = "sf.wins.lifetime"
        /// Wins on ranked mode.
        static let rankedWins = "sf.wins.ranked"
        /// Best win streak ever achieved.
        static let bestStreak = "sf.streak.best"
        /// Total ships sunk across all matches.
        static let shipsSunk = "sf.ships.sunk"
    }

    // MARK: - Achievements

    /// Maps the local Achievement.id (defined in Achievement.swift) to the
    /// Game Center achievement identifier configured in App Store Connect.
    /// Local IDs not present here are not reported to GC.
    static let achievementMap: [String: String] = [
        "first_victory":   "sf.ach.firstwin",
        "ten_victories":   "sf.ach.wins10",
        "fifty_victories": "sf.ach.wins50",
        "hundred_games":   "sf.ach.played100",
        "streak_3":        "sf.ach.streak3",
        "streak_5":        "sf.ach.streak5",
        "streak_10":       "sf.ach.streak10",
        "sharpshooter":    "sf.ach.sharpshooter",
        "eagle_eye":       "sf.ach.eagleeye",
        "perfect_game":    "sf.ach.flawless",
        "no_powerups":     "sf.ach.purist",
        "beat_medium":     "sf.ach.beat_medium",
        "beat_hard":       "sf.ach.beat_hard",
        "hard_master":     "sf.ach.hard_master",
        "ranked_first":    "sf.ach.ranked_first",
        "sink_25":         "sf.ach.sink25",
        "sink_100":        "sf.ach.sink100",
        "sink_500":        "sf.ach.sink500",
        "five_perfect":    "sf.ach.five_perfect",
        "all_difficulties": "sf.ach.all_difficulties",
    ]
}
