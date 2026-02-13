import SwiftUI

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    private let pageCount = 5

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.4),
                        Color(red: 0.05, green: 0.1, blue: 0.2)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    TabView(selection: $currentPage) {
                        welcomePage.tag(0)
                        fleetPage.tag(1)
                        battlePage.tag(2)
                        powerUpsPage.tag(3)
                        modesPage.tag(4)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    // Custom page indicator
                    HStack(spacing: 8) {
                        ForEach(0..<pageCount, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? .cyan : .white.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut(duration: 0.2), value: currentPage)
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("How to Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.cyan)
                }
            }
        }
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "ferry.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.cyan)
                    .padding(.top, 40)

                Text("Welcome, Commander!")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)

                Text("Silent Fleet is a strategic naval warfare game where you command a fleet of ships against an AI opponent.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                VStack(spacing: 16) {
                    objectiveRow(icon: "scope", text: "Locate and destroy all enemy ships")
                    objectiveRow(icon: "shield.fill", text: "Protect your fleet from enemy attacks")
                    objectiveRow(icon: "trophy.fill", text: "Sink the entire enemy fleet to win")
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.1))
                )
                .padding(.horizontal, 24)

                Text("Swipe to learn more")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 8)

                Spacer()
            }
        }
    }

    // MARK: - Page 2: Fleet & Placement

    private var fleetPage: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.cyan)
                    .padding(.top, 40)

                Text("Fleet & Placement")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 16) {
                    ruleRow(number: "1", text: "Your fleet consists of ships of sizes 2, 3, 3, 4, and 5")
                    ruleRow(number: "2", text: "Place ships on the 10x10 grid by dragging from the ship panel")
                    ruleRow(number: "3", text: "Ships cannot overlap or touch each other (including diagonals)")
                    ruleRow(number: "4", text: "Tap the rotate button to switch between horizontal and vertical")
                    ruleRow(number: "5", text: "Use Randomize to auto-place all ships")
                    ruleRow(number: "6", text: "Drag placed ships to reposition them")
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.1))
                )
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }

    // MARK: - Page 3: Battle Controls

    private var battlePage: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.orange)
                    .padding(.top, 40)

                Text("Battle & Turn Flow")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 16) {
                    ruleRow(number: "1", text: "Tap on the enemy grid to fire a shot")
                    ruleRow(number: "2", text: "Red flame = Hit! White circle = Miss")
                    ruleRow(number: "3", text: "When all cells of a ship are hit, it sinks")
                    ruleRow(number: "4", text: "After your shot, the AI fires back at your fleet")
                    ruleRow(number: "5", text: "Toggle between your fleet and enemy waters with the board switch button")
                    ruleRow(number: "6", text: "The game ends when one fleet is completely sunk")
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.1))
                )
                .padding(.horizontal, 24)

                // Shot result legend
                HStack(spacing: 20) {
                    legendItem(icon: "flame.fill", color: .red, label: "Hit")
                    legendItem(icon: "circle", color: .white, label: "Miss")
                    legendItem(icon: "xmark", color: .black, label: "Sunk")
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }

    // MARK: - Page 4: Power-Ups

    private var powerUpsPage: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.yellow)
                    .padding(.top, 40)

                Text("Power-Ups")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)

                Text("Use power-ups before firing your shot. They don't consume your turn!")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                VStack(spacing: 16) {
                    powerUpCard(
                        icon: "dot.radiowaves.left.and.right",
                        name: "Sonar Ping",
                        description: "Reveals whether ships exist in a 3x3 area. Detected ships briefly glow green on the board.",
                        color: .cyan
                    )

                    powerUpCard(
                        icon: "line.horizontal.3",
                        name: "Row Scan",
                        description: "Scans an entire row and tells you if any enemy ships are present.",
                        color: .green
                    )
                }
                .padding(.horizontal, 24)

                Text("Select a power-up from the bar, then tap the board to use it.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()
            }
        }
    }

    // MARK: - Page 5: Game Modes

    private var modesPage: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "flag.2.crossed.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.green)
                    .padding(.top, 40)

                Text("Game Modes")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)

                VStack(spacing: 16) {
                    modeInfoCard(
                        icon: "sun.max.fill",
                        name: "Casual",
                        features: [
                            "Ship sizes shown when sunk",
                            "2 Sonar Pings + 2 Row Scans",
                            "You always go first"
                        ],
                        color: .green
                    )

                    modeInfoCard(
                        icon: "trophy.fill",
                        name: "Ranked",
                        features: [
                            "Ship sizes hidden when sunk",
                            "1 Sonar Ping + 1 Row Scan",
                            "Coin flip for first turn",
                            "Board split placement rules"
                        ],
                        color: .orange
                    )
                }
                .padding(.horizontal, 24)

                // Let's Play button
                Button {
                    SoundManager.shared.buttonTap()
                    HapticManager.shared.buttonTap()
                    dismiss()
                } label: {
                    HStack {
                        Text("Let's Play!")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.cyan)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Spacer()
            }
        }
    }

    // MARK: - Helper Views

    private func objectiveRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.cyan)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
        }
    }

    private func ruleRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(.cyan)
                .frame(width: 20, height: 20)
                .background(Circle().fill(.cyan.opacity(0.2)))

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
        }
    }

    private func legendItem(icon: String, color: Color, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.white.opacity(0.1))
        )
    }

    private func powerUpCard(icon: String, name: String, description: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func modeInfoCard(icon: String, name: String, features: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(name)
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            ForEach(features, id: \.self) { feature in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .foregroundStyle(color.opacity(0.8))
                    Text(feature)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    HowToPlayView()
}
