import Foundation
import GameKit

/// Submits scores and achievements to Game Center. All calls no-op silently
/// when the local player isn't authenticated, so callers don't need to gate
/// each call.
enum GameCenterReporter {
    /// Submit leaderboard scores derived from the player's career stats.
    /// Called after `PlayerStats.recordGame` updates lifetime counters.
    static func submitLeaderboards(stats: PlayerStats) {
        guard GKLocalPlayer.local.isAuthenticated else { return }

        let updates: [(value: Int, leaderboardID: String)] = [
            (stats.gamesWon,       GameCenterIDs.Leaderboard.lifetimeWins),
            (stats.rankedWins,     GameCenterIDs.Leaderboard.rankedWins),
            (stats.bestWinStreak,  GameCenterIDs.Leaderboard.bestStreak),
            (stats.totalShipsSunk, GameCenterIDs.Leaderboard.shipsSunk),
        ]

        Task {
            for update in updates {
                guard update.value > 0 else { continue }
                do {
                    try await GKLeaderboard.submitScore(
                        update.value,
                        context: 0,
                        player: GKLocalPlayer.local,
                        leaderboardIDs: [update.leaderboardID]
                    )
                } catch {
                    // Silent failure: leaderboard ID may not exist in ASC yet,
                    // or the network may be unreachable. Don't block UX.
                }
            }
        }
    }

    /// Report newly unlocked achievements to Game Center. `localIDs` are the
    /// in-app achievement identifiers from `Achievement.swift`; they're mapped
    /// to GC IDs via `GameCenterIDs.achievementMap`.
    static func reportAchievements(localIDs: [String]) {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        let gcIDs = localIDs.compactMap { GameCenterIDs.achievementMap[$0] }
        guard !gcIDs.isEmpty else { return }

        Task {
            let achievements = gcIDs.map { id -> GKAchievement in
                let a = GKAchievement(identifier: id)
                a.percentComplete = 100
                a.showsCompletionBanner = true
                return a
            }
            do {
                try await GKAchievement.report(achievements)
            } catch {
                // Silent failure: unknown ID or offline. Local unlock state
                // is the source of truth so this is recoverable next session.
            }
        }
    }
}
