import SwiftUI
import GameKit

/// Presents `GKTurnBasedMatchmakerViewController`.
///
/// Modern Game Center delivers selected matches through the
/// `GKTurnBasedEventListener` callback with `didBecomeActive: true`, not
/// through this delegate, so this wrapper only forwards cancel/error.
struct OnlineMatchmakerView: UIViewControllerRepresentable {
    let onDismiss: () -> Void
    let onError: (Error) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> GKTurnBasedMatchmakerViewController {
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2
        request.defaultNumberOfPlayers = 2
        request.inviteMessage = "Join me for a game of Silent Fleet!"
        let vc = GKTurnBasedMatchmakerViewController(matchRequest: request)
        vc.turnBasedMatchmakerDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: GKTurnBasedMatchmakerViewController, context: Context) {}

    final class Coordinator: NSObject, GKTurnBasedMatchmakerViewControllerDelegate {
        let parent: OnlineMatchmakerView
        init(parent: OnlineMatchmakerView) { self.parent = parent }

        func turnBasedMatchmakerViewControllerWasCancelled(_ viewController: GKTurnBasedMatchmakerViewController) {
            parent.onDismiss()
        }

        func turnBasedMatchmakerViewController(
            _ viewController: GKTurnBasedMatchmakerViewController,
            didFailWithError error: Error
        ) {
            parent.onError(error)
        }
    }
}

/// Wrapper to present an arbitrary `UIViewController` (used for the GC auth VC).
struct GameCenterAuthSheet: UIViewControllerRepresentable {
    let viewController: UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
