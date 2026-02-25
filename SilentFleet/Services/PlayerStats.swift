import Foundation
import Combine
import GameEngine

/// Persistent career statistics tracking for replayability
final class PlayerStats: ObservableObject {
    static let shared = PlayerStats()

    private let defaults = UserDefaults.standard
    private let prefix = "stats_"

    // MARK: - Lifetime Stats

    @Published var gamesPlayed: Int {
        didSet { defaults.set(gamesPlayed, forKey: key("gamesPlayed")) }
    }

    @Published var gamesWon: Int {
        didSet { defaults.set(gamesWon, forKey: key("gamesWon")) }
    }

    @Published var gamesLost: Int {
        didSet { defaults.set(gamesLost, forKey: key("gamesLost")) }
    }

    @Published var totalShipsSunk: Int {
        didSet { defaults.set(totalShipsSunk, forKey: key("totalShipsSunk")) }
    }

    @Published var totalShipsLost: Int {
        didSet { defaults.set(totalShipsLost, forKey: key("totalShipsLost")) }
    }

    @Published var totalShotsFired: Int {
        didSet { defaults.set(totalShotsFired, forKey: key("totalShotsFired")) }
    }

    @Published var totalShotsHit: Int {
        didSet { defaults.set(totalShotsHit, forKey: key("totalShotsHit")) }
    }

    // MARK: - Streak Stats

    @Published var currentWinStreak: Int {
        didSet { defaults.set(currentWinStreak, forKey: key("currentWinStreak")) }
    }

    @Published var bestWinStreak: Int {
        didSet { defaults.set(bestWinStreak, forKey: key("bestWinStreak")) }
    }

    // MARK: - Best Performance Records

    @Published var bestAccuracy: Double {
        didSet { defaults.set(bestAccuracy, forKey: key("bestAccuracy")) }
    }

    @Published var fewestTurnsWin: Int {
        didSet { defaults.set(fewestTurnsWin, forKey: key("fewestTurnsWin")) }
    }

    // MARK: - Per-Difficulty Stats

    @Published var easyWins: Int {
        didSet { defaults.set(easyWins, forKey: key("easyWins")) }
    }

    @Published var mediumWins: Int {
        didSet { defaults.set(mediumWins, forKey: key("mediumWins")) }
    }

    @Published var hardWins: Int {
        didSet { defaults.set(hardWins, forKey: key("hardWins")) }
    }

    @Published var rankedWins: Int {
        didSet { defaults.set(rankedWins, forKey: key("rankedWins")) }
    }

    // MARK: - Special Counters

    @Published var perfectGames: Int {
        didSet { defaults.set(perfectGames, forKey: key("perfectGames")) }
    }

    @Published var noPowerUpWins: Int {
        didSet { defaults.set(noPowerUpWins, forKey: key("noPowerUpWins")) }
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
        self.gamesPlayed = defaults.integer(forKey: key("gamesPlayed"))
        self.gamesWon = defaults.integer(forKey: key("gamesWon"))
        self.gamesLost = defaults.integer(forKey: key("gamesLost"))
        self.totalShipsSunk = defaults.integer(forKey: key("totalShipsSunk"))
        self.totalShipsLost = defaults.integer(forKey: key("totalShipsLost"))
        self.totalShotsFired = defaults.integer(forKey: key("totalShotsFired"))
        self.totalShotsHit = defaults.integer(forKey: key("totalShotsHit"))
        self.currentWinStreak = defaults.integer(forKey: key("currentWinStreak"))
        self.bestWinStreak = defaults.integer(forKey: key("bestWinStreak"))
        self.bestAccuracy = defaults.double(forKey: key("bestAccuracy"))
        self.fewestTurnsWin = defaults.integer(forKey: key("fewestTurnsWin"))
        self.easyWins = defaults.integer(forKey: key("easyWins"))
        self.mediumWins = defaults.integer(forKey: key("mediumWins"))
        self.hardWins = defaults.integer(forKey: key("hardWins"))
        self.rankedWins = defaults.integer(forKey: key("rankedWins"))
        self.perfectGames = defaults.integer(forKey: key("perfectGames"))
        self.noPowerUpWins = defaults.integer(forKey: key("noPowerUpWins"))
    }

    private func key(_ name: String) -> String {
        "\(prefix)\(name)"
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
        return AchievementManager.shared.evaluateAll(stats: self, lastGameState: state)
    }
}
