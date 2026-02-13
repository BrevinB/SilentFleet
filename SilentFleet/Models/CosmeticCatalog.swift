import SwiftUI

enum CosmeticCatalog {

    // MARK: - Ship Skins

    static let allSkins: [ShipSkin] = [standard, stealth, goldFleet, crimson, neon, arcticSkin]

    static let standard = ShipSkin(
        id: "skin_standard",
        displayName: "Standard",
        price: 0,
        shipFill: .cyan.opacity(0.8),
        shipBorder: .cyan.opacity(0.6),
        shipPlacedBackground: .cyan.opacity(0.3),
        indicatorHealthy: .cyan,
        indicatorSunk: .red.opacity(0.5),
        indicatorBackground: .white.opacity(0.1),
        indicatorSunkBackground: .red.opacity(0.15),
        indicatorBorder: .white.opacity(0.2),
        indicatorSunkBorder: .red.opacity(0.3),
        shipIcon: "ship.fill",
        shipIconShadowColor: .green,
        selectionHighlight: .cyan,
        selectionBadgeColor: .cyan,
        previewDescription: "Classic fleet colors"
    )

    static let stealth = ShipSkin(
        id: "skin_stealth",
        displayName: "Stealth",
        price: 200,
        shipFill: .gray.opacity(0.9),
        shipBorder: .gray.opacity(0.7),
        shipPlacedBackground: .gray.opacity(0.3),
        indicatorHealthy: .gray,
        indicatorSunk: .red.opacity(0.4),
        indicatorBackground: .gray.opacity(0.15),
        indicatorSunkBackground: .red.opacity(0.1),
        indicatorBorder: .gray.opacity(0.4),
        indicatorSunkBorder: .red.opacity(0.3),
        shipIcon: "airplane",
        shipIconShadowColor: .gray,
        selectionHighlight: .gray,
        selectionBadgeColor: .gray,
        previewDescription: "Low-profile dark fleet"
    )

    static let goldFleet = ShipSkin(
        id: "skin_gold",
        displayName: "Gold Fleet",
        price: 300,
        shipFill: .yellow.opacity(0.85),
        shipBorder: .yellow.opacity(0.6),
        shipPlacedBackground: .yellow.opacity(0.25),
        indicatorHealthy: .yellow,
        indicatorSunk: .red.opacity(0.5),
        indicatorBackground: .yellow.opacity(0.1),
        indicatorSunkBackground: .red.opacity(0.15),
        indicatorBorder: .yellow.opacity(0.3),
        indicatorSunkBorder: .red.opacity(0.3),
        shipIcon: "crown.fill",
        shipIconShadowColor: .yellow,
        selectionHighlight: .yellow,
        selectionBadgeColor: .yellow,
        previewDescription: "Royal golden armada"
    )

    static let crimson = ShipSkin(
        id: "skin_crimson",
        displayName: "Crimson",
        price: 250,
        shipFill: Color(red: 0.9, green: 0.2, blue: 0.3).opacity(0.85),
        shipBorder: Color(red: 0.9, green: 0.2, blue: 0.3).opacity(0.6),
        shipPlacedBackground: Color(red: 0.9, green: 0.2, blue: 0.3).opacity(0.25),
        indicatorHealthy: Color(red: 0.9, green: 0.2, blue: 0.3),
        indicatorSunk: .gray.opacity(0.5),
        indicatorBackground: Color(red: 0.9, green: 0.2, blue: 0.3).opacity(0.1),
        indicatorSunkBackground: .gray.opacity(0.15),
        indicatorBorder: Color(red: 0.9, green: 0.2, blue: 0.3).opacity(0.3),
        indicatorSunkBorder: .gray.opacity(0.3),
        shipIcon: "bolt.fill",
        shipIconShadowColor: .red,
        selectionHighlight: Color(red: 0.9, green: 0.2, blue: 0.3),
        selectionBadgeColor: Color(red: 0.9, green: 0.2, blue: 0.3),
        previewDescription: "Blood-red warships"
    )

    static let neon = ShipSkin(
        id: "skin_neon",
        displayName: "Neon",
        price: 350,
        shipFill: Color(red: 0.0, green: 1.0, blue: 0.6).opacity(0.85),
        shipBorder: Color(red: 0.0, green: 1.0, blue: 0.6).opacity(0.6),
        shipPlacedBackground: Color(red: 0.0, green: 1.0, blue: 0.6).opacity(0.25),
        indicatorHealthy: Color(red: 0.0, green: 1.0, blue: 0.6),
        indicatorSunk: .red.opacity(0.5),
        indicatorBackground: Color(red: 0.0, green: 1.0, blue: 0.6).opacity(0.1),
        indicatorSunkBackground: .red.opacity(0.15),
        indicatorBorder: Color(red: 0.0, green: 1.0, blue: 0.6).opacity(0.3),
        indicatorSunkBorder: .red.opacity(0.3),
        shipIcon: "sparkle",
        shipIconShadowColor: Color(red: 0.0, green: 1.0, blue: 0.6),
        selectionHighlight: Color(red: 0.0, green: 1.0, blue: 0.6),
        selectionBadgeColor: Color(red: 0.0, green: 1.0, blue: 0.6),
        previewDescription: "Electric neon glow"
    )

    static let arcticSkin = ShipSkin(
        id: "skin_arctic",
        displayName: "Arctic",
        price: 400,
        shipFill: Color(red: 0.7, green: 0.9, blue: 1.0).opacity(0.85),
        shipBorder: Color(red: 0.7, green: 0.9, blue: 1.0).opacity(0.6),
        shipPlacedBackground: Color(red: 0.7, green: 0.9, blue: 1.0).opacity(0.25),
        indicatorHealthy: Color(red: 0.7, green: 0.9, blue: 1.0),
        indicatorSunk: .red.opacity(0.5),
        indicatorBackground: Color(red: 0.7, green: 0.9, blue: 1.0).opacity(0.1),
        indicatorSunkBackground: .red.opacity(0.15),
        indicatorBorder: Color(red: 0.7, green: 0.9, blue: 1.0).opacity(0.3),
        indicatorSunkBorder: .red.opacity(0.3),
        shipIcon: "snowflake",
        shipIconShadowColor: .white,
        selectionHighlight: Color(red: 0.7, green: 0.9, blue: 1.0),
        selectionBadgeColor: Color(red: 0.7, green: 0.9, blue: 1.0),
        previewDescription: "Ice-cold polar fleet"
    )

    // MARK: - Board Themes

    static let allThemes: [BoardTheme] = [classicNavy, deepOcean, sunset, arcticTheme, volcanic]

    static let classicNavy = BoardTheme(
        id: "theme_classic",
        displayName: "Classic Navy",
        price: 0,
        backgroundGradientTop: Color(red: 0.1, green: 0.2, blue: 0.4),
        backgroundGradientBottom: Color(red: 0.05, green: 0.1, blue: 0.2),
        waveColor: .white,
        waveOpacity1: 0.05,
        waveOpacity2: 0.03,
        cellEmpty: .white.opacity(0.1),
        cellHit: .orange.opacity(0.7),
        cellMiss: .white.opacity(0.05),
        cellSunk: .red.opacity(0.5),
        hitSymbol: "flame.fill",
        missSymbol: "circle",
        sunkSymbol: "xmark",
        hitSymbolColor: .orange,
        missSymbolColor: .white.opacity(0.5),
        sunkSymbolColor: .red,
        boardBackground: .white.opacity(0.1),
        boardBorder: .white.opacity(0.2),
        labelColor: .white.opacity(0.7),
        rippleHit: .orange,
        rippleMiss: .white,
        previewDescription: "Traditional naval warfare"
    )

    static let deepOcean = BoardTheme(
        id: "theme_deep_ocean",
        displayName: "Deep Ocean",
        price: 300,
        backgroundGradientTop: Color(red: 0.0, green: 0.1, blue: 0.3),
        backgroundGradientBottom: Color(red: 0.0, green: 0.02, blue: 0.1),
        waveColor: .cyan,
        waveOpacity1: 0.06,
        waveOpacity2: 0.03,
        cellEmpty: .cyan.opacity(0.08),
        cellHit: .orange.opacity(0.75),
        cellMiss: .cyan.opacity(0.04),
        cellSunk: .red.opacity(0.55),
        hitSymbol: "flame.fill",
        missSymbol: "circle",
        sunkSymbol: "xmark",
        hitSymbolColor: .orange,
        missSymbolColor: .cyan.opacity(0.4),
        sunkSymbolColor: .red,
        boardBackground: .cyan.opacity(0.08),
        boardBorder: .cyan.opacity(0.2),
        labelColor: .cyan.opacity(0.6),
        rippleHit: .orange,
        rippleMiss: .cyan,
        previewDescription: "Abyssal depths"
    )

    static let sunset = BoardTheme(
        id: "theme_sunset",
        displayName: "Sunset",
        price: 400,
        backgroundGradientTop: Color(red: 0.4, green: 0.15, blue: 0.1),
        backgroundGradientBottom: Color(red: 0.15, green: 0.05, blue: 0.15),
        waveColor: .orange,
        waveOpacity1: 0.06,
        waveOpacity2: 0.04,
        cellEmpty: .orange.opacity(0.08),
        cellHit: .yellow.opacity(0.8),
        cellMiss: .orange.opacity(0.04),
        cellSunk: .red.opacity(0.6),
        hitSymbol: "flame.fill",
        missSymbol: "circle",
        sunkSymbol: "xmark",
        hitSymbolColor: .yellow,
        missSymbolColor: .orange.opacity(0.5),
        sunkSymbolColor: .red,
        boardBackground: .orange.opacity(0.08),
        boardBorder: .orange.opacity(0.2),
        labelColor: .orange.opacity(0.7),
        rippleHit: .yellow,
        rippleMiss: .orange,
        previewDescription: "Warm twilight waters"
    )

    static let arcticTheme = BoardTheme(
        id: "theme_arctic",
        displayName: "Arctic",
        price: 450,
        backgroundGradientTop: Color(red: 0.15, green: 0.25, blue: 0.35),
        backgroundGradientBottom: Color(red: 0.05, green: 0.1, blue: 0.2),
        waveColor: Color(red: 0.7, green: 0.9, blue: 1.0),
        waveOpacity1: 0.07,
        waveOpacity2: 0.04,
        cellEmpty: Color(red: 0.7, green: 0.9, blue: 1.0).opacity(0.1),
        cellHit: .orange.opacity(0.7),
        cellMiss: Color(red: 0.7, green: 0.9, blue: 1.0).opacity(0.05),
        cellSunk: .red.opacity(0.5),
        hitSymbol: "flame.fill",
        missSymbol: "circle",
        sunkSymbol: "xmark",
        hitSymbolColor: .orange,
        missSymbolColor: Color(red: 0.7, green: 0.9, blue: 1.0).opacity(0.5),
        sunkSymbolColor: .red,
        boardBackground: Color(red: 0.7, green: 0.9, blue: 1.0).opacity(0.08),
        boardBorder: Color(red: 0.7, green: 0.9, blue: 1.0).opacity(0.2),
        labelColor: Color(red: 0.7, green: 0.9, blue: 1.0).opacity(0.7),
        rippleHit: .orange,
        rippleMiss: Color(red: 0.7, green: 0.9, blue: 1.0),
        previewDescription: "Frozen polar seas"
    )

    static let volcanic = BoardTheme(
        id: "theme_volcanic",
        displayName: "Volcanic",
        price: 500,
        backgroundGradientTop: Color(red: 0.25, green: 0.05, blue: 0.0),
        backgroundGradientBottom: Color(red: 0.1, green: 0.02, blue: 0.0),
        waveColor: .red,
        waveOpacity1: 0.07,
        waveOpacity2: 0.04,
        cellEmpty: .red.opacity(0.08),
        cellHit: .yellow.opacity(0.85),
        cellMiss: .red.opacity(0.04),
        cellSunk: Color(red: 0.4, green: 0.0, blue: 0.0),
        hitSymbol: "flame.fill",
        missSymbol: "circle",
        sunkSymbol: "xmark",
        hitSymbolColor: .yellow,
        missSymbolColor: .red.opacity(0.4),
        sunkSymbolColor: Color(red: 0.8, green: 0.2, blue: 0.0),
        boardBackground: .red.opacity(0.08),
        boardBorder: .red.opacity(0.2),
        labelColor: .red.opacity(0.6),
        rippleHit: .yellow,
        rippleMiss: .red,
        previewDescription: "Molten lava battlefield"
    )

    // MARK: - Lookup

    static func skin(withID id: String) -> ShipSkin {
        allSkins.first { $0.id == id } ?? standard
    }

    static func theme(withID id: String) -> BoardTheme {
        allThemes.first { $0.id == id } ?? classicNavy
    }
}
