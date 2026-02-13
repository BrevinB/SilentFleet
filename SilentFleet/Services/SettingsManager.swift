import Foundation
import Combine

/// Manages persistent user settings across the app
final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    // MARK: - Sound Settings

    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: "soundEnabled") }
    }

    @Published var soundVolume: Double {
        didSet { defaults.set(soundVolume, forKey: "soundVolume") }
    }

    // MARK: - Haptic Settings

    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: "hapticsEnabled") }
    }

    // MARK: - Tutorial Completion

    @Published var hasCompletedPlacementTooltips: Bool {
        didSet { defaults.set(hasCompletedPlacementTooltips, forKey: "hasCompletedPlacementTooltips") }
    }

    @Published var hasCompletedGameplayTooltips: Bool {
        didSet { defaults.set(hasCompletedGameplayTooltips, forKey: "hasCompletedGameplayTooltips") }
    }

    private init() {
        // Load persisted values with defaults
        self.soundEnabled = defaults.object(forKey: "soundEnabled") as? Bool ?? true
        self.soundVolume = defaults.object(forKey: "soundVolume") as? Double ?? 0.7
        self.hapticsEnabled = defaults.object(forKey: "hapticsEnabled") as? Bool ?? true
        self.hasCompletedPlacementTooltips = defaults.bool(forKey: "hasCompletedPlacementTooltips")
        self.hasCompletedGameplayTooltips = defaults.bool(forKey: "hasCompletedGameplayTooltips")
    }

    // MARK: - Tutorial Reset

    func resetTutorials() {
        hasCompletedPlacementTooltips = false
        hasCompletedGameplayTooltips = false
    }
}
