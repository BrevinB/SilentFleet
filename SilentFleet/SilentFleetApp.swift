import SwiftUI

@main
struct SilentFleetApp: App {
    init() {
        StoreManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            MainMenuView()
                .environmentObject(SettingsManager.shared)
                .environmentObject(PlayerInventory.shared)
        }
    }
}
