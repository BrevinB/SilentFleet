import Foundation
import GameKit
import SwiftUI
import Combine
import UIKit

/// Authenticates the local Game Center player and brokers turn-based events.
///
/// The manager is a singleton so a single listener instance can receive
/// `GKTurnBasedEventListener` callbacks for the lifetime of the app, and so
/// any view in the UI can present the GC sign-in VC when GC hands us one.
@MainActor
final class GameCenterManager: NSObject, ObservableObject {
    static let shared = GameCenterManager()

    enum AuthState: Equatable {
        case unauthenticated
        case authenticating
        case authenticated
        case failed(String)
    }

    @Published private(set) var authState: AuthState = .unauthenticated
    @Published private(set) var localPlayer: GKLocalPlayer?

    /// A view controller that Game Center asked us to present (sign-in flow).
    /// SwiftUI observes this and presents it in a sheet when non-nil.
    @Published var pendingAuthViewController: UIViewController?

    struct TurnEvent {
        let match: GKTurnBasedMatch
        let didBecomeActive: Bool
    }

    /// Turn events are multicast: every caller of `turnEventStream()` gets its
    /// own stream and receives *every* event. A single shared `AsyncStream`
    /// would split events between consumers (each element is delivered to only
    /// one iterator), which previously dropped opponent-move and match-end
    /// notifications. Keeping one continuation per subscriber fixes that.
    private var continuations: [UUID: AsyncStream<TurnEvent>.Continuation] = [:]

    private override init() {
        super.init()
    }

    var isAuthenticated: Bool {
        if case .authenticated = authState { return true }
        return false
    }

    /// Vend a new turn-event stream. Each subscriber gets all events for the
    /// lifetime of the returned stream; the continuation is removed when the
    /// stream's consumer task is cancelled.
    func turnEventStream() -> AsyncStream<TurnEvent> {
        let id = UUID()
        return AsyncStream { continuation in
            self.continuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in self?.continuations.removeValue(forKey: id) }
            }
        }
    }

    private func emit(_ event: TurnEvent) {
        for continuation in continuations.values {
            continuation.yield(event)
        }
    }

    /// Kicks off authentication. Safe to call multiple times.
    func authenticate() {
        if case .authenticated = authState { return }
        if case .authenticating = authState { return }
        authState = .authenticating

        let player = GKLocalPlayer.local
        player.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                guard let self else { return }
                if let viewController {
                    self.pendingAuthViewController = viewController
                    return
                }
                if let error {
                    self.authState = .failed(error.localizedDescription)
                    self.localPlayer = nil
                    return
                }
                if player.isAuthenticated {
                    self.localPlayer = player
                    self.authState = .authenticated
                    player.unregisterAllListeners()
                    player.register(self)
                } else {
                    self.authState = .failed("Game Center is not available.")
                    self.localPlayer = nil
                }
            }
        }
    }
}

extension GameCenterManager: GKLocalPlayerListener {
    nonisolated func player(
        _ player: GKPlayer,
        receivedTurnEventFor match: GKTurnBasedMatch,
        didBecomeActive: Bool
    ) {
        Task { @MainActor in
            self.emit(TurnEvent(match: match, didBecomeActive: didBecomeActive))
        }
    }

    nonisolated func player(_ player: GKPlayer, matchEnded match: GKTurnBasedMatch) {
        Task { @MainActor in
            self.emit(TurnEvent(match: match, didBecomeActive: false))
        }
    }
}
