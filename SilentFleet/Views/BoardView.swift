import SwiftUI
import GameEngine

struct BoardView: View {
    let board: Board
    let isOpponentBoard: Bool
    var showShips: Bool = false
    var selectedShip: Ship? = nil
    var placementOrientation: Orientation = .horizontal
    var highlightedCoordinates: Set<Coordinate> = []
    var sonarPulseCoordinates: Set<Coordinate> = []  // Cells with detected ships from sonar
    var sonarScanArea: Set<Coordinate> = []  // Full 3x3 area being scanned (blue outline)
    var showingSonarPulse: Bool = false
    var rowScanHighlight: Int? = nil  // Row being scanned (yellow highlight)
    var recentShotCoordinate: Coordinate? = nil
    var onCellTap: ((Coordinate) -> Void)?

    @ObservedObject private var inventory = PlayerInventory.shared
    @State private var hoverCoordinate: Coordinate?

    private let gridSize = Board.size
    private let cellSize: CGFloat = 32
    private let spacing: CGFloat = 2

    private var theme: BoardTheme { inventory.equippedTheme }
    private var skin: ShipSkin { inventory.equippedSkin }

    var body: some View {
        VStack(spacing: 0) {
            // Column labels
            HStack(spacing: spacing) {
                Text(" ")
                    .frame(width: 20)

                ForEach(0..<gridSize, id: \.self) { col in
                    Text("\(col)")
                        .font(.caption2)
                        .foregroundStyle(theme.labelColor)
                        .frame(width: cellSize, height: 16)
                }
            }

            // Grid with row labels
            ForEach(0..<gridSize, id: \.self) { row in
                HStack(spacing: spacing) {
                    // Row label
                    Text("\(row)")
                        .font(.caption2)
                        .foregroundStyle(theme.labelColor)
                        .frame(width: 20)

                    // Cells
                    ForEach(0..<gridSize, id: \.self) { col in
                        let coord = Coordinate(row: row, col: col)
                        CellView(
                            coordinate: coord,
                            state: cellState(for: coord),
                            theme: theme,
                            skin: skin,
                            isHighlighted: highlightedCoordinates.contains(coord),
                            isPreview: isPreviewCell(coord),
                            isValidPreview: isValidPreviewCell(coord),
                            isRecentShot: recentShotCoordinate == coord,
                            isSonarPulse: showingSonarPulse && sonarPulseCoordinates.contains(coord),
                            isSonarScanArea: showingSonarPulse && sonarScanArea.contains(coord),
                            isRowScanHighlight: rowScanHighlight == row
                        )
                        .frame(width: cellSize, height: cellSize)
                        .onTapGesture {
                            onCellTap?(coord)
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.boardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.boardBorder, lineWidth: 1)
                )
        )
    }

    private func cellState(for coord: Coordinate) -> CellState {
        // Check for shots
        if board.hasBeenShot(at: coord) {
            if board.hasShip(at: coord) {
                if let ship = board.ship(at: coord), ship.isSunk {
                    return .sunk
                }
                return .hit
            }
            return .miss
        }

        // Show ships on player's board or during placement
        if (showShips || !isOpponentBoard) && board.hasShip(at: coord) {
            return .ship
        }

        return .empty
    }

    private func isPreviewCell(_ coord: Coordinate) -> Bool {
        guard let ship = selectedShip else { return false }
        let previewShip = Ship(
            size: ship.size,
            origin: coord,
            orientation: placementOrientation
        )
        // Only show preview if hovering or if this is the origin
        return false // Simplified - would need hover state for full preview
    }

    private func isValidPreviewCell(_ coord: Coordinate) -> Bool {
        guard let ship = selectedShip else { return false }
        let testShip = Ship(
            size: ship.size,
            origin: coord,
            orientation: placementOrientation
        )
        if case .success = PlacementValidator.canPlace(ship: testShip, on: board.ships) {
            return testShip.isWithinBounds
        }
        return false
    }
}

struct CellView: View {
    let coordinate: Coordinate
    let state: CellState
    let theme: BoardTheme
    let skin: ShipSkin
    var isHighlighted: Bool = false
    var isPreview: Bool = false
    var isValidPreview: Bool = false
    var isRecentShot: Bool = false
    var isSonarPulse: Bool = false  // Cell with detected ship (shows ship icon)
    var isSonarScanArea: Bool = false  // Cell in the 3x3 scan area (blue outline)
    var isRowScanHighlight: Bool = false  // Cell in scanned row (yellow highlight)

    @State private var animationScale: CGFloat = 1.0
    @State private var animationOpacity: Double = 1.0
    @State private var showRipple: Bool = false
    @State private var sonarPulsePhase: CGFloat = 0
    @State private var rowScanPulsePhase: CGFloat = 0

    private var sonarOpacity: Double {
        0.5 + 0.3 * sin(sonarPulsePhase)
    }

    private var sonarScale: CGFloat {
        0.95 + 0.05 * CGFloat(sin(sonarPulsePhase))
    }

    private var rowScanOpacity: Double {
        0.4 + 0.3 * sin(rowScanPulsePhase)
    }

    var body: some View {
        ZStack {
            // Ripple effect for recent shots
            if showRipple {
                Circle()
                    .stroke(rippleColor, lineWidth: 2)
                    .scaleEffect(animationScale)
                    .opacity(animationOpacity)
            }

            // Background
            RoundedRectangle(cornerRadius: 4)
                .fill(cellBackgroundColor)
                .scaleEffect(cellScale)

            // Row scan highlight overlay
            if isRowScanHighlight {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.yellow.opacity(rowScanOpacity))
            }

            // Sonar pulse overlay - pulsing ship indicator
            if isSonarPulse {
                Image(systemName: skin.shipIcon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: skin.shipIconShadowColor, radius: 4)
            }

            // State indicator (hidden during sonar pulse)
            if let symbol = symbolForState, !isSonarPulse {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(symbolColor)
                    .scaleEffect(isRecentShot ? animationScale : 1.0)
            }

            // Highlight border
            if isHighlighted {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.yellow, lineWidth: 2)
            }

            // Sonar scan area border (blue outline for 3x3 area)
            if isSonarScanArea && !isSonarPulse {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.cyan, lineWidth: 2)
                    .opacity(sonarOpacity)
            }

            // Sonar pulse border (green for detected ships)
            if isSonarPulse {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.green, lineWidth: 2)
                    .opacity(sonarOpacity)
            }

            // Row scan border
            if isRowScanHighlight {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.orange, lineWidth: 2)
                    .opacity(rowScanOpacity)
            }
        }
        .onChange(of: isRecentShot) { _, newValue in
            if newValue {
                triggerAnimation()
            }
        }
        .onChange(of: isSonarPulse) { _, newValue in
            if newValue {
                startSonarPulse()
            } else {
                sonarPulsePhase = 0
            }
        }
        .onChange(of: isSonarScanArea) { _, newValue in
            if newValue {
                startSonarPulse()
            }
        }
        .onChange(of: isRowScanHighlight) { _, newValue in
            if newValue {
                startRowScanPulse()
            } else {
                rowScanPulsePhase = 0
            }
        }
        .onAppear {
            if isRecentShot {
                triggerAnimation()
            }
            if isSonarPulse || isSonarScanArea {
                startSonarPulse()
            }
            if isRowScanHighlight {
                startRowScanPulse()
            }
        }
    }

    private var cellBackgroundColor: Color {
        isSonarPulse ? .green.opacity(sonarOpacity) : backgroundColor
    }

    private var cellScale: CGFloat {
        if isSonarPulse {
            return sonarScale
        }
        if isRecentShot && (state == .hit || state == .sunk) {
            return animationScale
        }
        return 1.0
    }

    private func startSonarPulse() {
        withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
            sonarPulsePhase = .pi
        }
    }

    private func startRowScanPulse() {
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            rowScanPulsePhase = .pi
        }
    }

    private func triggerAnimation() {
        // Reset
        animationScale = 0.5
        animationOpacity = 1.0
        showRipple = true

        // Animate
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            animationScale = 1.0
        }

        // Ripple fade out
        withAnimation(.easeOut(duration: 0.6)) {
            animationOpacity = 0
        }

        // Hide ripple after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            showRipple = false
            animationScale = 1.0
        }
    }

    private var rippleColor: Color {
        switch state {
        case .hit, .sunk: return theme.rippleHit
        case .miss: return theme.rippleMiss
        default: return .clear
        }
    }

    private var backgroundColor: Color {
        if isPreview {
            return isValidPreview ? .green.opacity(0.4) : .red.opacity(0.4)
        }

        switch state {
        case .empty:
            return theme.cellEmpty
        case .ship:
            return skin.shipPlacedBackground
        case .hit:
            return theme.cellHit
        case .miss:
            return theme.cellMiss
        case .sunk:
            return theme.cellSunk
        }
    }

    private var symbolForState: String? {
        switch state {
        case .hit: return theme.hitSymbol
        case .miss: return theme.missSymbol
        case .sunk: return theme.sunkSymbol
        default: return nil
        }
    }

    private var symbolColor: Color {
        switch state {
        case .hit: return theme.hitSymbolColor
        case .miss: return theme.missSymbolColor
        case .sunk: return theme.sunkSymbolColor
        default: return .clear
        }
    }
}

#Preview {
    BoardView(
        board: Board(ships: [
            Ship(size: 5, origin: Coordinate(row: 0, col: 0), orientation: .horizontal),
            Ship(size: 3, origin: Coordinate(row: 2, col: 2), orientation: .vertical)
        ]),
        isOpponentBoard: false,
        showShips: true
    )
    .padding()
}
