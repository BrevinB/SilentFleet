import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsManager
    @ObservedObject private var inventory = PlayerInventory.shared
    @Environment(\.dismiss) private var dismiss

    private var theme: BoardTheme { inventory.equippedTheme }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [theme.backgroundGradientTop, theme.backgroundGradientBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Sound Section
                        settingsSection(title: "Sound", icon: "speaker.wave.2.fill") {
                            VStack(spacing: 16) {
                                Toggle(isOn: $settings.soundEnabled) {
                                    HStack(spacing: 12) {
                                        Image(systemName: settings.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                            .foregroundStyle(settings.soundEnabled ? .cyan : .white.opacity(0.4))
                                            .frame(width: 24)
                                        Text("Sound Effects")
                                            .foregroundStyle(.white)
                                    }
                                }
                                .tint(.cyan)

                                if settings.soundEnabled {
                                    VStack(spacing: 8) {
                                        HStack {
                                            Image(systemName: "speaker.fill")
                                                .foregroundStyle(.white.opacity(0.5))
                                                .font(.caption)
                                            Slider(value: $settings.soundVolume, in: 0...1)
                                                .tint(.cyan)
                                            Image(systemName: "speaker.wave.3.fill")
                                                .foregroundStyle(.white.opacity(0.5))
                                                .font(.caption)
                                        }
                                        Text("Volume (applies to custom audio)")
                                            .font(.caption2)
                                            .foregroundStyle(.white.opacity(0.4))
                                    }
                                }
                            }
                        }

                        // Haptics Section
                        settingsSection(title: "Feedback", icon: "iphone.radiowaves.left.and.right") {
                            Toggle(isOn: $settings.hapticsEnabled) {
                                HStack(spacing: 12) {
                                    Image(systemName: "iphone.radiowaves.left.and.right")
                                        .foregroundStyle(settings.hapticsEnabled ? .cyan : .white.opacity(0.4))
                                        .frame(width: 24)
                                    Text("Haptic Feedback")
                                        .foregroundStyle(.white)
                                }
                            }
                            .tint(.cyan)
                        }

                        // Tutorial Section
                        settingsSection(title: "Tutorial", icon: "lightbulb.fill") {
                            Button {
                                SoundManager.shared.buttonTap()
                                HapticManager.shared.buttonTap()
                                settings.resetTutorials()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .foregroundStyle(.orange)
                                        .frame(width: 24)
                                    Text("Reset Tutorial Tips")
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if !settings.hasCompletedPlacementTooltips && !settings.hasCompletedGameplayTooltips {
                                        Text("Already reset")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.4))
                                    }
                                }
                            }
                        }

                        // About Section
                        settingsSection(title: "About", icon: "info.circle.fill") {
                            VStack(spacing: 12) {
                                aboutRow(label: "Version", value: "1.0")
                                aboutRow(label: "Build", value: "Phase 5")
                                aboutRow(label: "Engine", value: "GameEngine v1")
                            }
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Settings")
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

    // MARK: - Helpers

    private func settingsSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(.cyan)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            content()
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.15), lineWidth: 1)
                        )
                )
        }
    }

    private func aboutRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(value)
                .foregroundStyle(.white)
                .font(.subheadline.weight(.medium))
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager.shared)
}
