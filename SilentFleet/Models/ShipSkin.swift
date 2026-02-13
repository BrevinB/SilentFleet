import SwiftUI

struct ShipSkin: Identifiable {
    let id: String
    let displayName: String
    let price: Int

    // Ship colors
    let shipFill: Color
    let shipBorder: Color
    let shipPlacedBackground: Color

    // Fleet indicator
    let indicatorHealthy: Color
    let indicatorSunk: Color
    let indicatorBackground: Color
    let indicatorSunkBackground: Color
    let indicatorBorder: Color
    let indicatorSunkBorder: Color

    // Sonar
    let shipIcon: String
    let shipIconShadowColor: Color

    // Selection UI
    let selectionHighlight: Color
    let selectionBadgeColor: Color

    let previewDescription: String
}
