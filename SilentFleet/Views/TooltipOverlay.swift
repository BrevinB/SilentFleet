import SwiftUI

// MARK: - Tooltip Card

struct TooltipCard: View {
    let step: Int
    let totalSteps: Int
    let title: String
    let message: String
    let icon: String
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(.cyan)

            // Title
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)

            // Message
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // Step indicator
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Circle()
                        .fill(index == step ? .cyan : .white.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }

            // Buttons
            HStack(spacing: 16) {
                Button {
                    onSkip()
                } label: {
                    Text("Skip")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Button {
                    HapticManager.shared.buttonTap()
                    SoundManager.shared.buttonTap()
                    onNext()
                } label: {
                    Text(step == totalSteps - 1 ? "Got it!" : "Next")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(.cyan))
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.1, green: 0.15, blue: 0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.cyan.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 20)
        .padding(.horizontal, 32)
    }
}

// MARK: - Placement Tooltip Overlay

struct PlacementTooltipOverlay: View {
    @State private var currentStep = 0
    @Binding var isShowing: Bool

    private let steps: [(title: String, message: String, icon: String)] = [
        (
            title: "Select a Ship",
            message: "Tap a ship from the panel below to select it, or drag it directly onto the board.",
            icon: "hand.tap.fill"
        ),
        (
            title: "Place on Board",
            message: "Drag the ship onto the grid. Green means valid, red means invalid. Ships can't overlap or touch.",
            icon: "square.grid.3x3.topleft.filled"
        ),
        (
            title: "Quick Setup",
            message: "Use Randomize to auto-place all ships, or rotate to switch orientation. Drag placed ships to reposition.",
            icon: "shuffle"
        )
    ]

    var body: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { /* Block taps */ }

            TooltipCard(
                step: currentStep,
                totalSteps: steps.count,
                title: steps[currentStep].title,
                message: steps[currentStep].message,
                icon: steps[currentStep].icon,
                onNext: {
                    if currentStep < steps.count - 1 {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            currentStep += 1
                        }
                    } else {
                        dismiss()
                    }
                },
                onSkip: {
                    dismiss()
                }
            )
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
        .animation(.easeInOut(duration: 0.2), value: currentStep)
    }

    private func dismiss() {
        SettingsManager.shared.hasCompletedPlacementTooltips = true
        withAnimation(.easeOut(duration: 0.2)) {
            isShowing = false
        }
    }
}

// MARK: - Gameplay Tooltip Overlay

struct GameplayTooltipOverlay: View {
    @State private var currentStep = 0
    @Binding var isShowing: Bool

    private let steps: [(title: String, message: String, icon: String)] = [
        (
            title: "Fire Your Shot",
            message: "Tap any cell on the enemy grid to fire. Red = hit, white = miss. Sink all ships to win!",
            icon: "scope"
        ),
        (
            title: "Use Power-Ups First",
            message: "Before firing, try a Sonar Ping or Row Scan from the power-up bar. They don't use your turn!",
            icon: "bolt.fill"
        )
    ]

    var body: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { /* Block taps */ }

            TooltipCard(
                step: currentStep,
                totalSteps: steps.count,
                title: steps[currentStep].title,
                message: steps[currentStep].message,
                icon: steps[currentStep].icon,
                onNext: {
                    if currentStep < steps.count - 1 {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            currentStep += 1
                        }
                    } else {
                        dismiss()
                    }
                },
                onSkip: {
                    dismiss()
                }
            )
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
        .animation(.easeInOut(duration: 0.2), value: currentStep)
    }

    private func dismiss() {
        SettingsManager.shared.hasCompletedGameplayTooltips = true
        withAnimation(.easeOut(duration: 0.2)) {
            isShowing = false
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        PlacementTooltipOverlay(isShowing: .constant(true))
    }
}
