import SwiftUI

@main
struct SilentFleetApp: App {
    @StateObject private var gameCenter = GameCenterManager.shared

    init() {
        StoreManager.shared.configure(apiKey: AppConfig.revenueCatAPIKey)
        GameCenterManager.shared.authenticate()
        MetricsManager.shared.start()
        #if DEBUG
        AutoplayDriver.runIfRequested()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            MainMenuView()
                .environmentObject(SettingsManager.shared)
                .environmentObject(PlayerInventory.shared)
                .sheet(item: .init(
                    get: { gameCenter.pendingAuthViewController.map(IdentifiedVC.init) },
                    set: { _ in gameCenter.pendingAuthViewController = nil }
                )) { wrapper in
                    GameCenterAuthSheet(viewController: wrapper.viewController)
                        .ignoresSafeArea()
                }
        }
    }
}

private struct IdentifiedVC: Identifiable {
    let id = UUID()
    let viewController: UIViewController
}
