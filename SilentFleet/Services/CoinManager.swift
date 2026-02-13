import Foundation
import GameEngine

struct CoinReward {
    let winBonus: Int
    let sinkBonus: Int
    let completionBonus: Int

    var total: Int { winBonus + sinkBonus + completionBonus }
}

enum CoinManager {
    private static let winAmount = 100
    private static let perShipSunk = 15
    private static let completionAmount = 25

    static func calculateReward(for state: GameState) -> CoinReward {
        let playerWon = state.winner == state.player1.id
        let shipsSunk = state.player2.board.sunkCount

        return CoinReward(
            winBonus: playerWon ? winAmount : 0,
            sinkBonus: shipsSunk * perShipSunk,
            completionBonus: completionAmount
        )
    }

    @discardableResult
    static func awardCoins(for state: GameState) -> CoinReward {
        let reward = calculateReward(for: state)
        PlayerInventory.shared.addCoins(reward.total)
        return reward
    }
}
