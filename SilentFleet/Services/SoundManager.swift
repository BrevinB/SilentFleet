import AudioToolbox

/// Manages sound effects throughout the app using system sounds
final class SoundManager {
    static let shared = SoundManager()

    private init() {}

    private var isEnabled: Bool {
        SettingsManager.shared.soundEnabled
    }

    // MARK: - UI Sounds

    func buttonTap() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1104) // Tock
    }

    func confirm() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1111) // Begin recording / confirmation beep
    }

    // MARK: - Placement Sounds

    func shipPlaced() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1057) // Short thud
    }

    func invalidPlacement() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1073) // Error / buzz
    }

    func placementComplete() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1025) // Positive chime
    }

    // MARK: - Gameplay Sounds

    func shotFired() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1104) // Tock
    }

    func hit() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1255) // Heavy impact
    }

    func miss() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1103) // Soft tap
    }

    func sunk() {
        guard isEnabled else { return }
        // Two-part descending thud to suggest sinking
        AudioServicesPlaySystemSound(1255) // Heavy impact
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            AudioServicesPlaySystemSound(1103) // Softer tap
        }
    }

    func sonarPing() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1057) // Sonar-like thud
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            AudioServicesPlaySystemSound(1057)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            AudioServicesPlaySystemSound(1057)
        }
    }

    func rowScan() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1110) // Sweep sound
    }

    func turnChange() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1105) // Subtle click
    }

    // MARK: - Game End Sounds

    func gameWon() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1025) // Fanfare / positive
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            AudioServicesPlaySystemSound(1025)
        }
    }

    func gameLost() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1073) // Negative buzz
    }
}
