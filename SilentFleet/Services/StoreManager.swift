import Foundation
import Combine
import StoreKit

struct CoinPack: Identifiable {
    let id: String
    let coins: Int
    let displayPrice: String
    let productID: String
}

@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    static let coinPacks: [CoinPack] = [
        CoinPack(id: "pack_500", coins: 500, displayPrice: "$0.99", productID: "com.silentfleet.coins500"),
        CoinPack(id: "pack_1200", coins: 1200, displayPrice: "$2.99", productID: "com.silentfleet.coins1200"),
        CoinPack(id: "pack_3000", coins: 3000, displayPrice: "$5.99", productID: "com.silentfleet.coins3000"),
    ]

    @Published var isPurchasing = false

    private init() {}

    func configure() {
        // RevenueCat configuration would go here:
        // Purchases.configure(withAPIKey: "your_api_key")
    }

    func purchaseCoinPack(_ pack: CoinPack) async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }

        #if DEBUG
        // In debug, instantly award coins without real IAP
        try? await Task.sleep(for: .milliseconds(500))
        PlayerInventory.shared.addCoins(pack.coins)
        return true
        #else
        // Production: Use RevenueCat or StoreKit
        do {
            let products = try await Product.products(for: [pack.productID])
            guard let product = products.first else { return false }
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    PlayerInventory.shared.addCoins(pack.coins)
                    await transaction.finish()
                    return true
                }
                return false
            case .pending, .userCancelled:
                return false
            @unknown default:
                return false
            }
        } catch {
            return false
        }
        #endif
    }

    func restorePurchases() async {
        #if DEBUG
        // No-op in debug
        #else
        try? await AppStore.sync()
        #endif
    }
}
