import Foundation
import Combine

final class PlayerInventory: ObservableObject {
    static let shared = PlayerInventory()

    private let defaults = UserDefaults.standard

    @Published var coinBalance: Int {
        didSet { defaults.set(coinBalance, forKey: "coinBalance") }
    }

    @Published var ownedSkinIDs: Set<String> {
        didSet { defaults.set(Array(ownedSkinIDs), forKey: "ownedSkinIDs") }
    }

    @Published var ownedThemeIDs: Set<String> {
        didSet { defaults.set(Array(ownedThemeIDs), forKey: "ownedThemeIDs") }
    }

    @Published var equippedSkinID: String {
        didSet { defaults.set(equippedSkinID, forKey: "equippedSkinID") }
    }

    @Published var equippedThemeID: String {
        didSet { defaults.set(equippedThemeID, forKey: "equippedThemeID") }
    }

    // MARK: - Computed

    var equippedSkin: ShipSkin {
        CosmeticCatalog.skin(withID: equippedSkinID)
    }

    var equippedTheme: BoardTheme {
        CosmeticCatalog.theme(withID: equippedThemeID)
    }

    // MARK: - Init

    private init() {
        let defaultSkinID = CosmeticCatalog.standard.id
        let defaultThemeID = CosmeticCatalog.classicNavy.id

        self.coinBalance = defaults.integer(forKey: "coinBalance")

        let savedSkins = defaults.stringArray(forKey: "ownedSkinIDs") ?? [defaultSkinID]
        self.ownedSkinIDs = Set(savedSkins)

        let savedThemes = defaults.stringArray(forKey: "ownedThemeIDs") ?? [defaultThemeID]
        self.ownedThemeIDs = Set(savedThemes)

        self.equippedSkinID = defaults.string(forKey: "equippedSkinID") ?? defaultSkinID
        self.equippedThemeID = defaults.string(forKey: "equippedThemeID") ?? defaultThemeID

        // Ensure defaults are always owned
        if !ownedSkinIDs.contains(defaultSkinID) {
            ownedSkinIDs.insert(defaultSkinID)
        }
        if !ownedThemeIDs.contains(defaultThemeID) {
            ownedThemeIDs.insert(defaultThemeID)
        }
    }

    // MARK: - Actions

    @discardableResult
    func purchaseSkin(_ skin: ShipSkin) -> Bool {
        guard coinBalance >= skin.price else { return false }
        guard !ownedSkinIDs.contains(skin.id) else { return false }
        coinBalance -= skin.price
        ownedSkinIDs.insert(skin.id)
        return true
    }

    @discardableResult
    func purchaseTheme(_ theme: BoardTheme) -> Bool {
        guard coinBalance >= theme.price else { return false }
        guard !ownedThemeIDs.contains(theme.id) else { return false }
        coinBalance -= theme.price
        ownedThemeIDs.insert(theme.id)
        return true
    }

    func equipSkin(_ skin: ShipSkin) {
        guard ownedSkinIDs.contains(skin.id) else { return }
        equippedSkinID = skin.id
    }

    func equipTheme(_ theme: BoardTheme) {
        guard ownedThemeIDs.contains(theme.id) else { return }
        equippedThemeID = theme.id
    }

    func addCoins(_ amount: Int) {
        coinBalance += amount
    }
}
