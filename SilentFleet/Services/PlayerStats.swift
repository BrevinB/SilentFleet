import Foundation
import Combine
import GameEngine

/// Persistent career statistics tracking for replayability
final class PlayerStats: ObservableObject {
    static let shared = PlayerStats()

    private let defaults = UserDefaults.standard
    private static let prefix = "stats_"

    // MARK: - Lifetime Stats

    @Published var gamesPlayed: Int {
        didSet { defaults.set(gamesPlayed, forKey: Self.key("gamesPlayed")) }
    }

    @Published var gamesWon: Int {
        didSet { defaults.set(gamesWon, forKey: Self.key("gamesWon")) }
    }

    @Published var gamesLost: Int {
        didSet { defaults.set(gamesLost, forKey: Self.key("gamesLost")) }
    }

    @Published var totalShipsSunk: Int {
        didSet { defaults.set(totalShipsSunk, forKey: Self.key("totalShipsSunk")) }
    }

    @Published var totalShipsLost: Int {
        didSet { defaults.set(totalShipsLost, forKey: Self.key("totalShipsLost")) }
    }

    @Published var totalShotsFired: Int {
        didSet { defaults.set(totalShotsFired, forKey: Self.key("totalShotsFired")) }
    }

    @Published var totalShotsHit: Int {
        didSet { defaults.set(totalShotsHit, forKey: Self.key("totalShotsHit")) }
    }

    // MARK: - Streak Stats

    @Published var currentWinStreak: Int {
        didSet { defaults.set(currentWinStreak, forKey: Self.key("currentWinStreak")) }
    }

    @Published var bestWinStreak: Int {
        didSet { defaults.set(bestWinStreak, forKey: Self.key("bestWinStreak")) }
    }

    // MARK: - Best Performance Records

    @Published var bestAccuracy: Double {
        didSet { defaults.set(bestAccuracy, forKey: Self.key("bestAccuracy")) }
    }

    @Published var fewestTurnsWin: Int {
        didSet { defaults.set(fewestTurnsWin, forKey: Self.key("fewestTurnsWin")) }
    }

    // MARK: - Per-Difficulty Stats

    @Published var easyWins: Int {
        didSet { defaults.set(easyWins, forKey: Self.key("easyWins")) }
    }

    @Published var mediumWins: Int {
        didSet { defaults.set(mediumWins, forKey: Self.key("mediumWins")) }
    }

    @Published var hardWins: Int {
        didSet { defaults.set(hardWins, forKey: Self.key("hardWins")) }
    }

    @Published var rankedWins: Int {
        didSet { defaults.set(rankedWins, forKey: Self.key("rankedWins")) }
    }

    // MARK: - Special Counters

    @Published var perfectGames: Int {
        didSet { defaults.set(perfectGames, forKey: Self.key("perfectGames")) }
    }

    @Published var noPowerUpWins: Int {
        didSet { defaults.set(noPowerUpWins, forKey: Self.key("noPowerUpWins")) }
    }

    // MARK: - Computed

    var winRate: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(gamesWon) / Double(gamesPlayed) * 100
    }

    var overallAccuracy: Double {
        guard totalShotsFired > 0 else { return 0 }
        return Double(totalShotsHit) / Double(totalShotsFired) * 100
    }

    // MARK: - Init

    private init() {
        self.gamesPlayed = defaults.integer(forKey: Self.key("gamesPlayed"))
        self.gamesWon = defaults.integer(forKey: Self.key("gamesWon"))
        self.gamesLost = defaults.integer(forKey: Self.key("gamesLost"))
        self.totalShipsSunk = defaults.integer(forKey: Self.key("totalShipsSunk"))
        self.totalShipsLost = defaults.integer(forKey: Self.key("totalShipsLost"))
        self.totalShotsFired = defaults.integer(forKey: Self.key("totalShotsFired"))
        self.totalShotsHit = defaults.integer(forKey: Self.key("totalShotsHit"))
        self.currentWinStreak = defaults.integer(forKey: Self.key("currentWinStreak"))
        self.bestWinStreak = defaults.integer(forKey: Self.key("bestWinStreak"))
        self.bestAccuracy = defaults.double(forKey: Self.key("bestAccuracy"))
        self.fewestTurnsWin = defaults.integer(forKey: Self.key("fewestTurnsWin"))
        self.easyWins = defaults.integer(forKey: Self.key("easyWins"))
        self.mediumWins = defaults.integer(forKey: Self.key("mediumWins"))
        self.hardWins = defaults.integer(forKey: Self.key("hardWins"))
        self.rankedWins = defaults.integer(forKey: Self.key("rankedWins"))
        self.perfectGames = defaults.integer(forKey: Self.key("perfectGames"))
        self.noPowerUpWins = defaults.integer(forKey: Self.key("noPowerUpWins"))
    }

    private static func key(_ name: String) -> String {
        "\(Self.prefix)\(name)"
    }

    // MARK: - Recording

    /// Record the result of a completed game. Returns newly unlocked achievements.
    @discardableResult
    func recordGame(_ state: GameState) -> [Achievement] {
        let playerWon = state.winner == state.player1.id
        let playerShots = state.turnHistory.filter { $0.playerID == state.player1.id }
        let hits = playerShots.filter { $0.shotResult.isHit }.count
        let shots = playerShots.count
        let accuracy = shots > 0 ? Double(hits) / Double(shots) * 100 : 0
        let shipsSunk = state.player2.board.sunkCount
        let shipsLost = state.player1.board.sunkCount
        let playerTurns = playerShots.count

        // Check if player used any power-ups
        let playerPowerUpKit = state.player1.powerUpKit
        let startingKit = PowerUpKit.forMode(state.mode)
        let usedPowerUps = (startingKit.totalRemaining - playerPowerUpKit.totalRemaining)

        // Update lifetime stats
        gamesPlayed += 1
        totalShotsFired += shots
        totalShotsHit += hits
        totalShipsSunk += shipsSunk
        totalShipsLost += shipsLost

        if playerWon {
            gamesWon += 1
            currentWinStreak += 1
            if currentWinStreak > bestWinStreak {
                bestWinStreak = currentWinStreak
            }

            // Per-difficulty tracking
            if let difficulty = state.aiDifficulty {
                switch difficulty {
                case .easy: easyWins += 1
                case .medium: mediumWins += 1
                case .hard: hardWins += 1
                }
            }

            if state.mode == .ranked {
                rankedWins += 1
            }

            // Best accuracy (wins only, min 10 shots)
            if shots >= 10 && accuracy > bestAccuracy {
                bestAccuracy = accuracy
            }

            // Fewest turns
            if fewestTurnsWin == 0 || playerTurns < fewestTurnsWin {
                fewestTurnsWin = playerTurns
            }

            // Perfect game (no ships lost)
            if shipsLost == 0 {
                perfectGames += 1
            }

            // No power-up win
            if usedPowerUps == 0 {
                noPowerUpWins += 1
            }
        } else {
            gamesLost += 1
            currentWinStreak = 0
        }

        // Check for newly unlocked achievements
        let newlyUnlocked = AchievementManager.shared.evaluateAll(stats: self, lastGameState: state)

        // Sync to Game Center (no-ops if unauthenticated).
        GameCenterReporter.submitLeaderboards(stats: self)
        GameCenterReporter.reportAchievements(localIDs: newlyUnlocked.map(\.id))

        return newlyUnlocked
    }
}
