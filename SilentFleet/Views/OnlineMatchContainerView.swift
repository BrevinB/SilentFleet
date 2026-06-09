import SwiftUI
import GameKit
import GameEngine

/// Owns the lifecycle of a single online match — auth gate, preferences,
/// matchmaker presentation, loading state, and routing between placement /
/// play / summary screens.
struct OnlineMatchContainerView: View {
    @StateObject private var viewModel = OnlineGameViewModel()
    @ObservedObject private var gc = GameCenterManager.shared
    @State private var preferences = OnlineMatchPreferences()
    @State private var showingMatchmaker = false
    @State private var currentMatch: GKTurnBasedMatch?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AnimatedOceanBackground()

            Group {
                switch gc.authState {
                case .unauthenticated, .authenticating:
                    authPrompt
                case .failed(let message):
                    authFailed(message: message)
                case .authenticated:
                    authedContent
                }
            }
        }
        .navigationBarBackButtonHidden(false)
        .sheet(isPresented: $showingMatchmaker) {
            OnlineMatchmakerView(
                onDismiss: { showingMatchmaker = false },
                onError: { _ in showingMatchmaker = false }
            )
            .ignoresSafeArea()
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.dismissError() } }
        )) {
            Button("OK") { viewModel.dismissError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task {
            gc.authenticate()
            await NotificationManager.shared.requestAuthorizationForOnlineMatchIfNeeded()
            // Each subscriber gets its own multicast stream, so the container and
            // the view model both reliably receive every event.
            for await event in gc.turnEventStream() {
                guard event.didBecomeActive else { continue }
                currentMatch = event.match
                showingMatchmaker = false
                await viewModel.load(match: event.match)
            }
        }
    }

    // MARK: - Subviews

    private var authPrompt: some View {
        VStack(spacing: 16) {
            ProgressView().tint(.white)
            Text("Signing in to Game Center…")
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private func authFailed(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text("Game Center sign-in failed")
                .font(.headline)
                .foregroundStyle(.white)
            Text(message)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("Try Again") { gc.authenticate() }
                .foregroundStyle(.white)
                .padding(.horizontal, 24).padding(.vertical, 10)
                .background(Capsule().fill(.white.opacity(0.2)))
        }
    }

    @ViewBuilder
    private var authedContent: some View {
        if GKLocalPlayer.local.isMultiplayerGamingRestricted {
            VStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                Text("Multiplayer is restricted")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Your Apple ID has parental restrictions that prevent online multiplayer. You can still play against the AI.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        } else if currentMatch == nil {
            OnlineMatchPreferencesView(preferences: $preferences) {
                viewModel.prepareForCreation(preferences)
                showingMatchmaker = true
            }
        } else {
            switch viewModel.status {
            case .loading:
                VStack(spacing: 12) {
                    ProgressView().tint(.white)
                    Text("Loading match…")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
            case .placement:
                OnlinePlacementView(viewModel: viewModel)
            case .yourTurn, .waitingForOpponent:
                OnlineMatchPlayView(viewModel: viewModel)
            case .finished:
                OnlineMatchSummaryView(viewModel: viewModel) {
                    currentMatch = nil
                }
            case .error(let message):
                VStack(spacing: 12) {
                    Text("Couldn't load match").foregroundStyle(.white)
                    Text(message).font(.caption).foregroundStyle(.white.opacity(0.7))
                    Button("Back") { currentMatch = nil }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24).padding(.vertical, 10)
                        .background(Capsule().fill(.white.opacity(0.2)))
                }
            }
        }
    }
}

/// Summary screen for finished online matches, including the coins and
/// achievements just recorded into career stats.
struct OnlineMatchSummaryView: View {
    @ObservedObject var viewModel: OnlineGameViewModel
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: viewModel.didWinMatch ? "trophy.fill" : "flag.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(viewModel.didWinMatch ? .yellow : .orange)
                    .padding(.top, 24)

                Text(viewModel.winnerLabel ?? "Match Over")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)

                if let reward = viewModel.coinReward {
                    CoinRewardView(reward: reward)
                        .padding(.horizontal)
                }

                if !viewModel.newlyUnlockedAchievements.isEmpty {
                    VStack(spacing: 8) {
                        Text("Achievements Unlocked")
                            .font(.headline)
                            .foregroundStyle(.white)
                        ForEach(viewModel.newlyUnlockedAchievements) { achievement in
                            HStack(spacing: 12) {
                                Image(systemName: achievement.icon)
                                    .font(.title3)
                                    .foregroundStyle(.yellow)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(achievement.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                    Text(achievement.description)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                Spacer()
                                Text("+\(achievement.coinReward)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.yellow)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.1)))
                        }
                    }
                    .padding(.horizontal)
                }

                Button("Done") { onDone() }
                    .padding(.horizontal, 32).padding(.vertical, 12)
                    .background(Capsule().fill(.white.opacity(0.2)))
                    .foregroundStyle(.white)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
