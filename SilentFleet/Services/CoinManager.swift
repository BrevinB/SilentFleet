import Foundation
import GameEngine

struct CoinReward {
    let winBonus: Int
    let sinkBonus: Int
    let completionBonus: Int
    let streakBonus: Int
    let difficultyBonus: Int

    var total: Int { winBonus + sinkBonus + completionBonus + streakBonus + difficultyBonus }
}

enum CoinManager {
    private static let winAmount = 100
    private static let perShipSunk = 15
    private static let completionAmount = 25

    /// Bonus coins per win-streak level (streak 2 = 25, 3 = 50, 4 = 75, 5+ = 100)
    static func streakBonus(for streak: Int) -> Int {
        guard streak >= 2 else { return 0 }
        return min(streak - 1, 4) * 25
    }

    /// Extra coins for beating harder AI
    static func difficultyBonus(for difficulty: AIDifficulty?, playerWon: Bool) -> Int {
        guard playerWon, let difficulty else { return 0 }
        switch difficulty {
        case .easy: return 0
        case .medium: return 25
        case .hard: return 50
        }
    }

    static func calculateReward(for state: GameState, streak: Int = 0) -> CoinReward {
        let playerWon = state.winner == state.player1.id
        let shipsSunk = state.player2.board.sunkCount

        return CoinReward(
            winBonus: playerWon ? winAmount : 0,
            sinkBonus: shipsSunk * perShipSunk,
            completionBonus: completionAmount,
            streakBonus: playerWon ? streakBonus(for: streak) : 0,
            difficultyBonus: difficultyBonus(for: state.aiDifficulty, playerWon: playerWon)
        )
    }

    @discardableResult
    static func awardCoins(for state: GameState, streak: Int = 0) -> CoinReward {
        let reward = calculateReward(for: state, streak: streak)
        PlayerInventory.shared.addCoins(reward.total)
        return reward
    }
}
