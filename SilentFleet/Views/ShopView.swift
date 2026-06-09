import SwiftUI
import RevenueCat

struct ShopView: View {
    @ObservedObject private var inventory = PlayerInventory.shared
    @StateObject private var store = StoreManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.15, blue: 0.3),
                        Color(red: 0.04, green: 0.08, blue: 0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    // Coin balance header
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.yellow)
                        Text("\(inventory.coinBalance)")
                            .font(.title2.weight(.bold).monospacedDigit())
                            .foregroundStyle(.yellow)
                        Text("coins")
                            .font(.subheadline)
                            .foregroundStyle(.yellow.opacity(0.7))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(
                        Capsule()
                            .fill(.yellow.opacity(0.15))
                            .overlay(Capsule().stroke(.yellow.opacity(0.3), lineWidth: 1))
                    )

                    // Tab picker
                    Picker("Shop", selection: $selectedTab) {
                        Text("Skins").tag(0)
                        Text("Themes").tag(1)
                        Text("Coins").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Tab content
                    ScrollView {
                        switch selectedTab {
                        case 0:
                            skinsTab
                        case 1:
                            themesTab
                        default:
                            coinPacksTab
                        }
                    }
                }
            }
            .navigationTitle("Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.cyan)
                }
            }
        }
    }

    // MARK: - Skins Tab

    private var skinsTab: some View {
        LazyVStack(spacing: 12) {
            ForEach(CosmeticCatalog.allSkins) { skin in
                SkinCard(skin: skin, inventory: inventory)
            }
        }
        .padding()
    }

    // MARK: - Themes Tab

    private var themesTab: some View {
        LazyVStack(spacing: 12) {
            ForEach(CosmeticCatalog.allThemes) { theme in
                ThemeCard(theme: theme, inventory: inventory)
            }
        }
        .padding()
    }

    // MARK: - Coin Packs Tab

    private var coinPacksTab: some View {
        LazyVStack(spacing: 12) {
            if store.isLoadingOffering && store.coinPacks.isEmpty {
                ProgressView().tint(.white).padding(.top, 40)
            } else if store.coinPacks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.4))
                    Text("Coin packs unavailable")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                    Button("Retry") {
                        Task { await store.refreshOffering() }
                    }
                    .font(.caption)
                    .foregroundStyle(.cyan)
                }
                .padding(.top, 40)
            } else {
                let maxCoins = store.coinPacks.map(\.coins).max() ?? 0
                ForEach(store.coinPacks, id: \.package.identifier) { entry in
                    CoinPackCard(
                        package: entry.package,
                        coins: entry.coins,
                        isBestValue: entry.coins == maxCoins && store.coinPacks.count > 1,
                        store: store
                    )
                }
            }

            Button {
                Task { await store.restorePurchases() }
            } label: {
                Text("Restore Purchases")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.top, 8)
        }
        .padding()
    }
}

// MARK: - Skin Card

private struct SkinCard: View {
    let skin: ShipSkin
    @ObservedObject var inventory: PlayerInventory

    private var isOwned: Bool { inventory.ownedSkinIDs.contains(skin.id) }
    private var isEquipped: Bool { inventory.equippedSkinID == skin.id }

    var body: some View {
        HStack(spacing: 14) {
            // Color swatches (decorative — the skin name carries the meaning)
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(skin.shipFill)
                    .frame(width: 20, height: 36)
                RoundedRectangle(cornerRadius: 4)
                    .fill(skin.indicatorHealthy)
                    .frame(width: 20, height: 36)
                RoundedRectangle(cornerRadius: 4)
                    .fill(skin.selectionHighlight)
                    .frame(width: 20, height: 36)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(skin.displayName)
                        .font(.headline)
                        .foregroundStyle(.white)

                    if isEquipped {
                        Text("EQUIPPED")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(.green.opacity(0.2)))
                    } else if isOwned {
                        Text("OWNED")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.cyan)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(.cyan.opacity(0.2)))
                    }
                }

                Text(skin.previewDescription)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .accessibilityElement(children: .combine)

            Spacer()

            // Action button
            if isEquipped {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)
            } else if isOwned {
                Button("Equip") {
                    inventory.equipSkin(skin)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(.cyan))
                .accessibilityLabel("Equip \(skin.displayName)")
            } else {
                Button {
                    inventory.purchaseSkin(skin)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.caption)
                        Text("\(skin.price)")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(.yellow)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.yellow.opacity(0.2)))
                }
                .disabled(inventory.coinBalance < skin.price)
                .opacity(inventory.coinBalance < skin.price ? 0.5 : 1)
                .accessibilityLabel("Buy \(skin.displayName) for \(skin.price) coins")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isEquipped ? .green.opacity(0.4) : .white.opacity(0.12), lineWidth: 1)
                )
        )
    }
}

// MARK: - Theme Card

private struct ThemeCard: View {
    let theme: BoardTheme
    @ObservedObject var inventory: PlayerInventory

    private var isOwned: Bool { inventory.ownedThemeIDs.contains(theme.id) }
    private var isEquipped: Bool { inventory.equippedThemeID == theme.id }

    var body: some View {
        HStack(spacing: 14) {
            // Mini gradient preview (decorative)
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [theme.backgroundGradientTop, theme.backgroundGradientBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    HStack(spacing: 2) {
                        Circle().fill(theme.cellEmpty).frame(width: 8, height: 8)
                        Circle().fill(theme.cellHit).frame(width: 8, height: 8)
                        Circle().fill(theme.cellSunk).frame(width: 8, height: 8)
                    }
                )
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white.opacity(0.2), lineWidth: 1))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(theme.displayName)
                        .font(.headline)
                        .foregroundStyle(.white)

                    if isEquipped {
                        Text("EQUIPPED")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(.green.opacity(0.2)))
                    } else if isOwned {
                        Text("OWNED")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.cyan)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(.cyan.opacity(0.2)))
                    }
                }

                Text(theme.previewDescription)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .accessibilityElement(children: .combine)

            Spacer()

            if isEquipped {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)
            } else if isOwned {
                Button("Equip") {
                    inventory.equipTheme(theme)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(.cyan))
                .accessibilityLabel("Equip \(theme.displayName)")
            } else {
                Button {
                    inventory.purchaseTheme(theme)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.caption)
                        Text("\(theme.price)")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(.yellow)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.yellow.opacity(0.2)))
                }
                .disabled(inventory.coinBalance < theme.price)
                .opacity(inventory.coinBalance < theme.price ? 0.5 : 1)
                .accessibilityLabel("Buy \(theme.displayName) for \(theme.price) coins")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isEquipped ? .green.opacity(0.4) : .white.opacity(0.12), lineWidth: 1)
                )
        )
    }
}

// MARK: - Coin Pack Card

private struct CoinPackCard: View {
    let package: Package
    let coins: Int
    var isBestValue: Bool = false
    @ObservedObject var store: StoreManager

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(.yellow.opacity(isBestValue ? 0.3 : 0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: "dollarsign.circle.fill")
                    .font(.title)
                    .foregroundStyle(.yellow)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("\(coins) Coins")
                        .font(.headline)
                        .foregroundStyle(.white)

                    if isBestValue {
                        Text("BEST VALUE")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.yellow)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(.yellow.opacity(0.18))
                                    .overlay(Capsule().stroke(.yellow.opacity(0.6), lineWidth: 1))
                            )
                    }
                }
                Text("Instant delivery")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .accessibilityElement(children: .combine)

            Spacer()

            Button {
                Task { _ = await store.purchase(package) }
            } label: {
                Text(package.storeProduct.localizedPriceString)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(isBestValue ? Color.yellow.opacity(0.85) : Color.blue))
            }
            .disabled(store.isPurchasing)
            .opacity(store.isPurchasing ? 0.5 : 1)
            .accessibilityLabel("Buy \(coins) coins for \(package.storeProduct.localizedPriceString)\(isBestValue ? ", best value" : "")")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(isBestValue ? 0.12 : 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isBestValue ? .yellow.opacity(0.45) : .white.opacity(0.12),
                            lineWidth: isBestValue ? 1.5 : 1
                        )
                )
        )
    }
}

#Preview {
    ShopView()
}
