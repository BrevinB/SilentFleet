import SwiftUI

struct BoardTheme: Identifiable {
    let id: String
    let displayName: String
    let price: Int

    // Background gradient
    let backgroundGradientTop: Color
    let backgroundGradientBottom: Color

    // Waves
    let waveColor: Color
    let waveOpacity1: Double
    let waveOpacity2: Double

    // Cells
    let cellEmpty: Color
    let cellHit: Color
    let cellMiss: Color
    let cellSunk: Color

    // Symbols
    let hitSymbol: String
    let missSymbol: String
    let sunkSymbol: String
    let hitSymbolColor: Color
    let missSymbolColor: Color
    let sunkSymbolColor: Color

    // Board chrome
    let boardBackground: Color
    let boardBorder: Color
    let labelColor: Color

    // Ripples
    let rippleHit: Color
    let rippleMiss: Color

    let previewDescription: String
}
