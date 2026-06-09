import Foundation
import UserNotifications
import UIKit

/// Manages push-notification permission and APNs registration so Game Center
/// can deliver turn-event alerts when the app is backgrounded.
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private let didPromptKey = "notifications_did_prompt_for_online_match"

    private init() {}

    /// Whether the user has already been asked once for permission. We only
    /// prompt the first time they enter Online Match so the popup feels
    /// contextual instead of a random launch-time interruption.
    var hasPromptedForPermission: Bool {
        UserDefaults.standard.bool(forKey: didPromptKey)
    }

    /// Request notification authorization and register with APNs on success.
    /// Idempotent — safe to call repeatedly.
    func requestAuthorizationForOnlineMatchIfNeeded() async {
        UserDefaults.standard.set(true, forKey: didPromptKey)

        let center = UNUserNotificationCenter.current()
        let current = await center.notificationSettings()
        switch current.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
            return
        case .denied:
            return
        case .notDetermined:
            break
        @unknown default:
            break
        }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
            }
        } catch {
            // Silent — user can re-enable in Settings later.
        }
    }
}
