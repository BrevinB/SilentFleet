import SwiftUI
import GameKit
import UIKit

/// SwiftUI wrapper for `GKGameCenterViewController` so we can present the
/// dashboard from a sheet. Defaults to the player profile/dashboard state.
struct GameCenterDashboardView: UIViewControllerRepresentable {
    enum State {
        case dashboard
        case leaderboards
        case achievements
        case leaderboard(id: String)
    }

    let state: State

    init(state: State = .dashboard) {
        self.state = state
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let vc: GKGameCenterViewController
        switch state {
        case .dashboard:
            vc = GKGameCenterViewController(state: .dashboard)
        case .leaderboards:
            vc = GKGameCenterViewController(state: .leaderboards)
        case .achievements:
            vc = GKGameCenterViewController(state: .achievements)
        case .leaderboard(let id):
            vc = GKGameCenterViewController(
                leaderboardID: id,
                playerScope: .global,
                timeScope: .allTime
            )
        }
        vc.gameCenterDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: GKGameCenterViewController, context: Context) {}

    final class Coordinator: NSObject, GKGameCenterControllerDelegate {
        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            gameCenterViewController.dismiss(animated: true)
        }
    }
}
