import Foundation
import Combine
import RevenueCat

/// In-app purchase manager backed by RevenueCat.
///
/// Coin packs are configured as a single Offering named "default" in the
/// RevenueCat dashboard. Each package is linked to an App Store Connect
/// Consumable. Local coin balance is the source of truth; RC's stored
/// non-subscription transactions are used to credit coins once per purchase
/// (so a restore doesn't double-credit).
@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    /// Maps RevenueCat package identifier → coin amount granted on purchase.
    /// Must match what's configured in the RevenueCat dashboard.
    private static let coinsByPackageID: [String: Int] = [
        "coins_500":  500,
        "coins_1200": 1200,
        "coins_3000": 3000,
    ]

    @Published private(set) var offering: Offering?
    @Published private(set) var isLoadingOffering = false
    @Published var isPurchasing = false
    @Published var errorMessage: String?

    /// Set of RevenueCat transaction IDs we've already credited locally,
    /// persisted across launches so a restore can't re-credit a consumable.
    private let creditedTxKey = "rc_credited_transaction_ids"
    private var creditedTxIDs: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: creditedTxKey) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: creditedTxKey) }
    }

    private init() {}

    /// Configure RevenueCat. Called once from `SilentFleetApp.init`.
    /// Replace `apiKey` with the iOS Public App-Specific key from the RC dashboard.
    func configure(apiKey: String) {
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: apiKey)
        // Load the current Offering up front so the shop UI has data ready.
        Task { await refreshOffering() }
        // Reconcile any non-subscription transactions on launch (handles pending
        // purchases that completed while the app was closed).
        Task { await reconcileTransactions() }
    }

    /// Refresh the offering shown to the shop UI.
    func refreshOffering() async {
        isLoadingOffering = true
        defer { isLoadingOffering = false }
        do {
            let offerings = try await Purchases.shared.offerings()
            self.offering = offerings.current
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Convenience: list of (package, coin amount) tuples in display order
    /// so the shop view doesn't have to know the mapping.
    var coinPacks: [(package: Package, coins: Int)] {
        guard let offering else { return [] }
        return offering.availablePackages.compactMap { pkg in
            guard let coins = Self.coinsByPackageID[pkg.identifier] else { return nil }
            return (pkg, coins)
        }
    }

    func purchase(_ package: Package) async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled { return false }
            await reconcileTransactions()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Restore — only meaningful for non-consumables, but Apple still requires
    /// a "Restore Purchases" button on any IAP-bearing app.
    func restorePurchases() async {
        do {
            _ = try await Purchases.shared.restorePurchases()
            await reconcileTransactions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Walk RevenueCat's non-subscription transactions and credit coins for
    /// any we haven't credited yet. This is idempotent.
    private func reconcileTransactions() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            var credited = creditedTxIDs
            for tx in info.nonSubscriptions {
                guard !credited.contains(tx.transactionIdentifier) else { continue }
                // RevenueCat exposes the product identifier — map back to package.
                guard let coins = coinsForProductID(tx.productIdentifier) else { continue }
                PlayerInventory.shared.addCoins(coins)
                credited.insert(tx.transactionIdentifier)
            }
            creditedTxIDs = credited
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func coinsForProductID(_ productID: String) -> Int? {
        guard let pkg = offering?.availablePackages.first(where: {
            $0.storeProduct.productIdentifier == productID
        }) else { return nil }
        return Self.coinsByPackageID[pkg.identifier]
    }

    func dismissError() { errorMessage = nil }
}
