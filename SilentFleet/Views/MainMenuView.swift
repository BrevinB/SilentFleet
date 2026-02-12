import SwiftUI
import GameEngine

struct MainMenuView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var showingGameSetup = false
    @State private var navigateToGame = false
    @State private var titleOffset: CGFloat = -50
    @State private var buttonsOpacity: Double = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // Animated Background
                AnimatedOceanBackground()

                VStack(spacing: 40) {
                    Spacer()

                    // Title with animation
                    VStack(spacing: 8) {
                        Text("SILENT FLEET")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)

                        Text("Naval Warfare")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.7))

                        // Decorative ship icon
                        Image(systemName: "ferry.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.top, 8)
                    }
                    .offset(y: titleOffset)
                    .onAppear {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                            titleOffset = 0
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
                            title: "Continue",
                            subtitle: "Resume saved game",
                            icon: "arrow.clockwise",
                            color: .green
                        ) {
                            // Future: load saved games
                        }
                        .opacity(0.5)

                        MenuButton(
                            title: "How to Play",
                            subtitle: "Learn the rules",
                            icon: "questionmark.circle",
                            color: .orange
                        ) {
                            // Future: show rules
                        }
                        .opacity(0.5)
                    }
                    .padding(.horizontal, 24)
                    .opacity(buttonsOpacity)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                            buttonsOpacity = 1
                        }
                    }

                    Spacer()

                    // Version
                    Text("v1.0")
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
        }
    }
}

// MARK: - Animated Background

struct AnimatedOceanBackground: View {
    @State private var waveOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.05, green: 0.1, blue: 0.2)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Animated wave layers
            WaveShape(offset: waveOffset, amplitude: 20)
                .fill(Color.white.opacity(0.05))
                .frame(height: 200)
                .offset(y: 250)

            WaveShape(offset: waveOffset + 100, amplitude: 15)
                .fill(Color.white.opacity(0.03))
                .frame(height: 150)
                .offset(y: 300)
        }
        .onAppear {
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
