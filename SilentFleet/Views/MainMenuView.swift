import SwiftUI
import GameEngine

struct MainMenuView: View {
    @StateObject private var viewModel = GameViewModel()
    @ObservedObject private var inventory = PlayerInventory.shared
    @State private var showingGameSetup = false
    @State private var navigateToGame = false
    @State private var showingSettings = false
    @State private var showingHowToPlay = false
    @State private var showingShop = false
    @State private var showingStats = false
    @State private var showingOnline = false
    @State private var showingGameCenter = false
    @ObservedObject private var gameCenter = GameCenterManager.shared
    @State private var titleOffset: CGFloat = -50
    @State private var buttonsOpacity: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var savedGames: [GameState] = []
    @State private var hasSavedGame = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Animated Background
                AnimatedOceanBackground()

                // Top bar: Shop (left) + Settings (right)
                VStack {
                    HStack {
                        // Shop button with coin balance
                        Button {
                            HapticManager.shared.buttonTap()
                            SoundManager.shared.buttonTap()
                            showingShop = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "bag.fill")
                                    .font(.subheadline)
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                                Text("\(inventory.coinBalance)")
                                    .font(.subheadline.weight(.semibold).monospacedDigit())
                                    .foregroundStyle(.yellow)
                            }
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(.white.opacity(0.1)))
                        }
                        .accessibilityLabel("Shop, \(inventory.coinBalance) coins")
                        .padding(.leading, 20)
                        .padding(.top, 8)

                        Spacer()

                        if gameCenter.isAuthenticated {
                            Button {
                                HapticManager.shared.buttonTap()
                                SoundManager.shared.buttonTap()
                                showingGameCenter = true
                            } label: {
                                Image(systemName: "gamecontroller.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .padding(12)
                                    .background(Circle().fill(.white.opacity(0.1)))
                            }
                            .accessibilityLabel("Game Center")
                            .padding(.trailing, 8)
                            .padding(.top, 8)
                        }

                        Button {
                            HapticManager.shared.buttonTap()
                            SoundManager.shared.buttonTap()
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(12)
                                .background(Circle().fill(.white.opacity(0.1)))
                        }
                        .accessibilityLabel("Settings")
                        .padding(.trailing, 20)
                        .padding(.top, 8)
                    }
                    Spacer()
                }
                .zIndex(1)

                VStack(spacing: 40) {
                    Spacer()

                    // Title with animation
                    VStack(spacing: 8) {
                        Text("SILENT FLEET")
                            .font(.system(.largeTitle, design: .rounded).weight(.black))
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                            .accessibilityAddTraits(.isHeader)

                        Text("Naval Warfare")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.7))

                        // Decorative ship icon
                        Image(systemName: "ferry.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.top, 8)
                            .accessibilityHidden(true)
                    }
                    .offset(y: titleOffset)
                    .onAppear {
                        if reduceMotion {
                            titleOffset = 0
                        } else {
                            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                                titleOffset = 0
                            }
                        }
                    }

                    Spacer()

                    // Menu Buttons
                    VStack(spacing: 16) {
                        MenuButton(
                            title: "New Game",
                            subtitle: "Start a new battle",
                            icon: "play.fill",
                            color: .blue
                        ) {
                            withAnimation {
                                showingGameSetup = true
                            }
                        }

                        MenuButton(
                            title: "Online Match",
                            subtitle: "Turn-based vs another player",
                            icon: "person.2.fill",
                            color: .cyan
                        ) {
                            showingOnline = true
                        }

                        MenuButton(
                            title: "Continue",
                            subtitle: "Resume saved game",
                            icon: "arrow.clockwise",
                            color: .green
                        ) {
                            if let game = savedGames.first {
                                viewModel.resumeGame(game)
                                navigateToGame = true
                            }
                        }
                        .opacity(hasSavedGame ? 1 : 0.5)
                        .disabled(!hasSavedGame)

                        MenuButton(
                            title: "How to Play",
                            subtitle: "Learn the rules",
                            icon: "questionmark.circle",
                            color: .orange
                        ) {
                            showingHowToPlay = true
                        }

                        MenuButton(
                            title: "Stats",
                            subtitle: "Career stats & achievements",
                            icon: "chart.bar.fill",
                            color: .purple
                        ) {
                            showingStats = true
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(buttonsOpacity)
                    .onAppear {
                        if reduceMotion {
                            buttonsOpacity = 1
                        } else {
                            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                                buttonsOpacity = 1
                            }
                        }
                    }

                    Spacer()

                    // Version
                    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.bottom, 20)
                }
            }
            .navigationDestination(isPresented: $showingGameSetup) {
                GameSetupView(viewModel: viewModel) {
                    showingGameSetup = false
                    navigateToGame = true
                }
            }
            .navigationDestination(isPresented: $navigateToGame) {
                GameContainerView(viewModel: viewModel)
            }
            .navigationDestination(isPresented: $showingOnline) {
                OnlineMatchContainerView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(SettingsManager.shared)
            }
            .sheet(isPresented: $showingHowToPlay) {
                HowToPlayView()
            }
            .sheet(isPresented: $showingShop) {
                ShopView()
            }
            .sheet(isPresented: $showingStats) {
                PlayerStatsView()
            }
            .sheet(isPresented: $showingGameCenter) {
                GameCenterDashboardView(state: .dashboard)
                    .ignoresSafeArea()
            }
            .task {
                await loadSavedGames()

                // First launch: walk new players through the rules
                if !SettingsManager.shared.hasSeenWelcome {
                    SettingsManager.shared.hasSeenWelcome = true
                    showingHowToPlay = true
                }
            }
            .onAppear {
                Task {
                    await loadSavedGames()
                }
            }
        }
    }

    private func loadSavedGames() async {
        savedGames = await viewModel.loadSavedGames()
        hasSavedGame = !savedGames.isEmpty
    }
}

// MARK: - Animated Background

struct AnimatedOceanBackground: View {
    @ObservedObject private var inventory = PlayerInventory.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var waveOffset: CGFloat = 0

    private var theme: BoardTheme { inventory.equippedTheme }

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [theme.backgroundGradientTop, theme.backgroundGradientBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Animated wave layers (skipped entirely when Reduce Motion is on)
            if !reduceMotion {
                WaveShape(offset: waveOffset, amplitude: 20)
                    .fill(theme.waveColor.opacity(theme.waveOpacity1))
                    .frame(height: 200)
                    .offset(y: 250)

                WaveShape(offset: waveOffset + 100, amplitude: 15)
                    .fill(theme.waveColor.opacity(theme.waveOpacity2))
                    .frame(height: 150)
                    .offset(y: 300)
            }
        }
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                waveOffset = 360
            }
        }
    }
}

struct WaveShape: Shape {
    var offset: CGFloat
    var amplitude: CGFloat

    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: 0, y: height))

        for x in stride(from: 0, through: width, by: 5) {
            let relativeX = x / width
            let sine = sin((relativeX * 360 + offset) * .pi / 180)
            let y = amplitude * sine + height / 2
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()

        return path
    }
}

// MARK: - Menu Button

struct MenuButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticManager.shared.buttonTap()
            SoundManager.shared.buttonTap()
            action()
        }) {
            HStack(spacing: 16) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                }
                .accessibilityHidden(true)

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.5))
                    .accessibilityHidden(true)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    MainMenuView()
}
