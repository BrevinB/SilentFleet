#if DEBUG
import Foundation
import GameEngine

/// Headless smoke-test harness: plays full games against the AI through the
/// real GameViewModel when launched with AUTOPLAY=1 in the environment
/// (e.g. `SIMCTL_CHILD_AUTOPLAY=1 xcrun simctl launch ...`).
/// Inert in normal runs; DEBUG builds only.
@MainActor
enum AutoplayDriver {
    static func runIfRequested() {
        guard ProcessInfo.processInfo.environment["AUTOPLAY"] == "1" else { return }
        Task {
            let scenarios: [(AIDifficulty, GridSize)] = [
                (.hard, .small),
                (.hard, .large),
                (.medium, .medium),
            ]
            for (difficulty, grid) in scenarios {
                NSLog("AUTOPLAY: starting \(difficulty) on \(grid)")
                await playGame(difficulty: difficulty, grid: grid)
            }
            NSLog("AUTOPLAY: ALL GAMES COMPLETED WITHOUT CRASH")
        }
    }

    private static func playGame(difficulty: AIDifficulty, grid: GridSize) async {
        let vm = GameViewModel()
        vm.startNewGame(mode: .casual, difficulty: difficulty, gridSize: grid)
        vm.autoPopulateShips()
        guard vm.confirmPlacement() else {
            NSLog("AUTOPLAY: placement failed: \(vm.errorMessage ?? "?")")
            return
        }

        var idleTicks = 0
        while !vm.isGameOver && idleTicks < 600 {
            if vm.isPlayerTurn, let board = vm.opponentBoard {
                if let coord = nextTarget(on: board) {
                    vm.fireShot(at: coord)
                }
            } else {
                idleTicks += 1
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
        NSLog("AUTOPLAY: finished gameOver=\(vm.isGameOver) turns=\(vm.turnCount) winner=\(vm.winner ?? "none")")
    }

    private static func nextTarget(on board: Board) -> Coordinate? {
        for row in 0..<board.boardSize {
            for col in 0..<board.boardSize {
                let coord = Coordinate(row: row, col: col)
                if !board.hasBeenShot(at: coord) {
                    return coord
                }
            }
        }
        return nil
    }
}
#endif
