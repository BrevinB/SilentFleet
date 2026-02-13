import SwiftUI
import GameEngine

// Preference key to capture board frame
struct BoardFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct PlacementView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject private var inventory = PlayerInventory.shared
    @State private var hoverCoordinate: Coordinate?
    @State private var isDragging: Bool = false
    @State private var isDraggingFromSelection: Bool = false
    @State private var isDraggingPlacedShip: Bool = false
    @State private var draggedPlacedShip: Ship? = nil  // The ship being moved (temporarily removed from placed)
    @State private var dragLocation: CGPoint = .zero
    @State private var boardFrame: CGRect = .zero
    @State private var draggedShipSize: Int?
    @State private var floatingShipValid: Bool = false
    @State private var showingPlacementTooltips: Bool = false

    private let boardCellSize: CGFloat = 32
    private let boardSpacing: CGFloat = 2
    private let boardLabelWidth: CGFloat = 20
    private let boardPadding: CGFloat = 8

    // Calculate centered origin for ship placement
    private func centeredOrigin(for coord: Coordinate, shipSize: Int, orientation: Orientation) -> Coordinate {
        let offset = (shipSize - 1) / 2
        switch orientation {
        case .horizontal:
            return Coordinate(row: coord.row, col: max(0, coord.col - offset))
        case .vertical:
            return Coordinate(row: max(0, coord.row - offset), col: coord.col)
        }
    }

    // Convert global position to board coordinate
    private func coordinateFromGlobalPosition(_ position: CGPoint) -> Coordinate? {
        // Make sure board frame is valid
        guard boardFrame.width > 0 && boardFrame.height > 0 else { return nil }

        // Convert to local board coordinates (relative to board view)
        let localX = position.x - boardFrame.minX - boardPadding - boardLabelWidth
        let localY = position.y - boardFrame.minY - boardPadding - 16 // 16 for column labels

        let cellWithSpacing = boardCellSize + boardSpacing

        let col = Int(localX / cellWithSpacing)
        let row = Int(localY / cellWithSpacing)

        // Check bounds
        guard row >= 0 && row < Board.size && col >= 0 && col < Board.size else {
            return nil
        }

        return Coordinate(row: row, col: col)
    }

    // Check if a ship placement would be valid
    private func isValidPlacement(at coord: Coordinate, size: Int) -> Bool {
        let origin = centeredOrigin(for: coord, shipSize: size, orientation: viewModel.placementOrientation)
        let ship = Ship(size: size, origin: origin, orientation: viewModel.placementOrientation)
        guard ship.isWithinBounds else { return false }
        if case .success = PlacementValidator.canPlace(ship: ship, on: viewModel.placedShips) {
            return true
        }
        return false
    }

    // Get the ship preview for current hover position (only while dragging)
    private var previewShip: Ship? {
        guard isDragging, let hover = hoverCoordinate else { return nil }

        // Determine which ship we're dragging
        let shipSize: Int
        let orientation: Orientation

        if let placedShip = draggedPlacedShip {
            // Dragging a placed ship - use its size and orientation
            shipSize = placedShip.size
            orientation = placedShip.orientation
        } else if let selected = viewModel.selectedShip {
            // Dragging from selection
            shipSize = selected.size
            orientation = viewModel.placementOrientation
        } else {
            return nil
        }

        let origin = centeredOrigin(for: hover, shipSize: shipSize, orientation: orientation)
        return Ship(size: shipSize, origin: origin, orientation: orientation)
    }

    // Check if preview placement is valid
    private var isPreviewValid: Bool {
        guard let preview = previewShip else { return false }
        guard preview.isWithinBounds else { return false }
        if case .success = PlacementValidator.canPlace(ship: preview, on: viewModel.placedShips) {
            return true
        }
        return false
    }

    var body: some View {
        ZStack {
            // Navy Background
            AnimatedOceanBackground()

            VStack(spacing: 16) {
                // Header
                VStack(spacing: 4) {
                    Text("Place Your Fleet")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)

                    if isDraggingFromSelection {
                        Text("Drag onto the board...")
                            .font(.caption)
                            .foregroundStyle(.cyan)
                    } else if isDraggingPlacedShip {
                        Text("Drag to reposition ship...")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else if isDragging {
                        Text("Drag to position...")
                            .font(.caption)
                            .foregroundStyle(.cyan)
                    } else if viewModel.selectedShip != nil {
                        Text("Tap or drag on board to place")
                            .font(.caption)
                            .foregroundStyle(.cyan)
                    } else if viewModel.remainingFleetSizes.isEmpty {
                        Text("All ships placed! Tap Continue when ready")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Text("Drag ships to place or reposition them")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(.top)

                // Board with placement preview
                PlacementBoardView(
                    placedShips: viewModel.placedShips,
                    draggedPlacedShip: draggedPlacedShip,
                    selectedShip: viewModel.selectedShip,
                    orientation: viewModel.placementOrientation,
                    skin: inventory.equippedSkin,
                    theme: inventory.equippedTheme,
                    hoverCoordinate: $hoverCoordinate,
                    isDragging: $isDragging,
                    boardFrame: $boardFrame,
                    previewShip: previewShip,
                    isPreviewValid: isPreviewValid,
                    onPlacedShipDragStart: { ship in
                        // User started dragging a placed ship - temporarily remove it
                        isDraggingPlacedShip = true
                        draggedPlacedShip = ship
                        viewModel.placedShips.removeAll { $0.id == ship.id }
                        HapticManager.shared.buttonTap()
                        SoundManager.shared.buttonTap()
                    },
                    onDragEnd: { coord in
                        // Handle drag end for both new ships and repositioned ships
                        if let movedShip = draggedPlacedShip {
                            // Repositioning a placed ship
                            let origin = centeredOrigin(for: coord, shipSize: movedShip.size, orientation: movedShip.orientation)
                            let newShip = Ship(size: movedShip.size, origin: origin, orientation: movedShip.orientation)

                            // Check if valid
                            if newShip.isWithinBounds,
                               case .success = PlacementValidator.canPlace(ship: newShip, on: viewModel.placedShips) {
                                // Place in new position
                                viewModel.placedShips.append(newShip)
                                HapticManager.shared.shipPlaced()
                                SoundManager.shared.shipPlaced()
                            } else {
                                // Invalid - return to original position
                                viewModel.placedShips.append(movedShip)
                                HapticManager.shared.invalidPlacement()
                                SoundManager.shared.invalidPlacement()
                            }

                            isDraggingPlacedShip = false
                            draggedPlacedShip = nil
                            hoverCoordinate = nil
                        } else if let selected = viewModel.selectedShip {
                            // Placing a new ship from selection
                            let origin = centeredOrigin(for: coord, shipSize: selected.size, orientation: viewModel.placementOrientation)
                            let ship = Ship(size: selected.size, origin: origin, orientation: viewModel.placementOrientation)

                            // Check if valid
                            guard ship.isWithinBounds else {
                                HapticManager.shared.invalidPlacement()
                                SoundManager.shared.invalidPlacement()
                                return
                            }
                            if case .failure = PlacementValidator.canPlace(ship: ship, on: viewModel.placedShips) {
                                HapticManager.shared.invalidPlacement()
                                SoundManager.shared.invalidPlacement()
                                return
                            }

                            // Place the ship immediately
                            viewModel.placedShips.append(ship)
                            if let index = viewModel.remainingFleetSizes.firstIndex(of: ship.size) {
                                viewModel.remainingFleetSizes.remove(at: index)
                            }
                            HapticManager.shared.shipPlaced()
                            SoundManager.shared.shipPlaced()
                            viewModel.selectedShip = nil
                            hoverCoordinate = nil
                        }
                    },
                    onDragCancel: {
                        // Drag was cancelled (e.g., dragged outside board) - restore placed ship
                        if let movedShip = draggedPlacedShip {
                            viewModel.placedShips.append(movedShip)
                            isDraggingPlacedShip = false
                            draggedPlacedShip = nil
                            hoverCoordinate = nil
                        }
                    }
                )

                // Ship Selection
                ShipSelectionView(
                    viewModel: viewModel,
                    onTap: { size in
                        // Tap to select (old behavior)
                        viewModel.selectShipSize(size)
                    },
                    onDragStarted: { size, location in
                        draggedShipSize = size
                        viewModel.selectShipSize(size)
                        isDragging = true
                        isDraggingFromSelection = true
                        dragLocation = location
                        floatingShipValid = false
                        // Check if over board
                        if let coord = coordinateFromGlobalPosition(location) {
                            hoverCoordinate = coord
                            floatingShipValid = isValidPlacement(at: coord, size: size)
                        }
                    },
                    onDragChanged: { size, location in
                        dragLocation = location
                        if let coord = coordinateFromGlobalPosition(location) {
                            if hoverCoordinate != coord {
                                hoverCoordinate = coord
                                floatingShipValid = isValidPlacement(at: coord, size: size)
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }
                        } else {
                            hoverCoordinate = nil
                            floatingShipValid = false
                        }
                    },
                    onDragEnded: { size, location in
                        isDragging = false
                        isDraggingFromSelection = false
                        draggedShipSize = nil
                        floatingShipValid = false
                        if let coord = coordinateFromGlobalPosition(location) {
                            // Calculate centered placement
                            let origin = centeredOrigin(for: coord, shipSize: size, orientation: viewModel.placementOrientation)
                            let ship = Ship(size: size, origin: origin, orientation: viewModel.placementOrientation)

                            // Check if valid and place immediately
                            if ship.isWithinBounds,
                               case .success = PlacementValidator.canPlace(ship: ship, on: viewModel.placedShips) {
                                viewModel.placedShips.append(ship)
                                if let index = viewModel.remainingFleetSizes.firstIndex(of: ship.size) {
                                    viewModel.remainingFleetSizes.remove(at: index)
                                }
                                HapticManager.shared.shipPlaced()
                                SoundManager.shared.shipPlaced()
                            } else {
                                HapticManager.shared.invalidPlacement()
                                SoundManager.shared.invalidPlacement()
                            }
                            viewModel.selectedShip = nil
                            hoverCoordinate = nil
                        } else {
                            // Dropped outside board
                            viewModel.selectedShip = nil
                            hoverCoordinate = nil
                        }
                    }
                )

                // Controls Row
                HStack(spacing: 12) {
                    // Orientation Toggle
                    Button {
                        HapticManager.shared.buttonTap()
                        SoundManager.shared.buttonTap()
                        viewModel.toggleOrientation()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text(viewModel.placementOrientation == .horizontal ? "Horizontal" : "Vertical")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.15))
                                .overlay(Capsule().stroke(.white.opacity(0.3), lineWidth: 1))
                        )
                    }

                    // Auto-populate Button
                    Button {
                        HapticManager.shared.buttonTap()
                        SoundManager.shared.buttonTap()
                        viewModel.autoPopulateShips()
                        // Clear any dragging state
                        isDragging = false
                        isDraggingPlacedShip = false
                        draggedPlacedShip = nil
                        hoverCoordinate = nil
                    } label: {
                        HStack {
                            Image(systemName: "shuffle")
                            Text("Randomize")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(.orange.opacity(0.2))
                                .overlay(Capsule().stroke(.orange.opacity(0.5), lineWidth: 1))
                        )
                    }
                }

                Spacer()

                // Continue Button
                Button {
                    _ = viewModel.confirmPlacement()
                } label: {
                    HStack {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(viewModel.remainingFleetSizes.isEmpty ? .green : .white.opacity(0.2))
                    )
                }
                .disabled(!viewModel.remainingFleetSizes.isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            // Floating ship preview while dragging from selection
            if isDraggingFromSelection, let size = draggedShipSize {
                DraggingShipView(
                    size: size,
                    orientation: viewModel.placementOrientation,
                    isOverBoard: hoverCoordinate != nil,
                    isValid: floatingShipValid
                )
                .position(dragLocation)
                .allowsHitTesting(false)
            }
        }
        .coordinateSpace(name: "placement")
        .overlay {
            if showingPlacementTooltips {
                PlacementTooltipOverlay(isShowing: $showingPlacementTooltips)
            }
        }
        .onAppear {
            if !SettingsManager.shared.hasCompletedPlacementTooltips {
                showingPlacementTooltips = true
            }
        }
    }
}

// Floating ship that follows finger during drag
struct DraggingShipView: View {
    let size: Int
    let orientation: Orientation
    let isOverBoard: Bool
    let isValid: Bool

    var body: some View {
        Group {
            if orientation == .horizontal {
                HStack(spacing: 2) {
                    ForEach(0..<size, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(shipColor)
                            .frame(width: 28, height: 28)
                    }
                }
            } else {
                VStack(spacing: 2) {
                    ForEach(0..<size, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(shipColor)
                            .frame(width: 28, height: 28)
                    }
                }
            }
        }
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .opacity(0.9)
    }

    private var shipColor: Color {
        if !isOverBoard {
            return .gray
        }
        return isValid ? .green : .red
    }
}

struct ShipSelectionView: View {
    @ObservedObject var viewModel: GameViewModel
    var onTap: (Int) -> Void
    var onDragStarted: (Int, CGPoint) -> Void
    var onDragChanged: (Int, CGPoint) -> Void
    var onDragEnded: (Int, CGPoint) -> Void

    // Group remaining sizes for display
    private var groupedSizes: [(size: Int, count: Int)] {
        var counts: [Int: Int] = [:]
        for size in viewModel.remainingFleetSizes {
            counts[size, default: 0] += 1
        }
        return counts.map { (size: $0.key, count: $0.value) }
            .sorted { $0.size > $1.size }
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("Available Ships")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))

            HStack(spacing: 12) {
                ForEach(groupedSizes, id: \.size) { item in
                    DraggableShipButton(
                        size: item.size,
                        count: item.count,
                        isSelected: viewModel.selectedShip?.size == item.size,
                        onTap: onTap,
                        onDragStarted: onDragStarted,
                        onDragChanged: onDragChanged,
                        onDragEnded: onDragEnded
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

struct DraggableShipButton: View {
    let size: Int
    let count: Int
    let isSelected: Bool
    var onTap: (Int) -> Void
    var onDragStarted: (Int, CGPoint) -> Void
    var onDragChanged: (Int, CGPoint) -> Void
    var onDragEnded: (Int, CGPoint) -> Void

    @State private var isDragging = false
    private var skin: ShipSkin { PlayerInventory.shared.equippedSkin }

    var body: some View {
        VStack(spacing: 4) {
            // Ship visualization
            HStack(spacing: 2) {
                ForEach(0..<size, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isSelected ? skin.selectionHighlight : .white.opacity(0.6))
                        .frame(width: 12, height: 12)
                }
            }

            // Count badge
            Text("\(count)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(Circle().fill(count > 0 ? skin.selectionBadgeColor : .white.opacity(0.3)))
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(isSelected ? 0.2 : 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? skin.selectionHighlight : .white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                )
        )
        .opacity(count == 0 ? 0.5 : (isDragging ? 0.3 : 1))
        .onTapGesture {
            guard count > 0 else { return }
            HapticManager.shared.buttonTap()
            SoundManager.shared.buttonTap()
            onTap(size)
        }
        .gesture(
            DragGesture(minimumDistance: 10, coordinateSpace: .named("placement"))
                .onChanged { value in
                    guard count > 0 else { return }
                    if !isDragging {
                        isDragging = true
                        HapticManager.shared.buttonTap()
                        SoundManager.shared.buttonTap()
                        onDragStarted(size, value.location)
                    } else {
                        onDragChanged(size, value.location)
                    }
                }
                .onEnded { value in
                    guard count > 0 else { return }
                    isDragging = false
                    onDragEnded(size, value.location)
                }
        )
        .allowsHitTesting(count > 0)
    }
}

// MARK: - Placement Board with Preview

struct PlacementBoardView: View {
    let placedShips: [Ship]
    let draggedPlacedShip: Ship?  // Ship currently being repositioned
    let selectedShip: Ship?
    let orientation: Orientation
    let skin: ShipSkin
    let theme: BoardTheme
    @Binding var hoverCoordinate: Coordinate?
    @Binding var isDragging: Bool
    @Binding var boardFrame: CGRect
    let previewShip: Ship?
    let isPreviewValid: Bool
    let onPlacedShipDragStart: (Ship) -> Void
    let onDragEnd: (Coordinate) -> Void
    let onDragCancel: () -> Void

    private let gridSize = Board.size
    private let cellSize: CGFloat = 32
    private let spacing: CGFloat = 2
    private let labelWidth: CGFloat = 20

    // Check if a coordinate has a placed ship (for drag detection)
    private func shipAt(_ coord: Coordinate) -> Ship? {
        placedShips.first { $0.occupies(coord) }
    }

    // Calculate the coordinate from a position within the grid
    private func coordinateFromPosition(_ position: CGPoint) -> Coordinate? {
        // Account for label width offset
        let adjustedX = position.x - labelWidth
        let adjustedY = position.y - 16 // Account for column labels height

        // Calculate cell + spacing size
        let cellWithSpacing = cellSize + spacing

        let col = Int(adjustedX / cellWithSpacing)
        let row = Int(adjustedY / cellWithSpacing)

        // Bounds check
        guard row >= 0 && row < gridSize && col >= 0 && col < gridSize else {
            return nil
        }

        return Coordinate(row: row, col: col)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Column labels
            HStack(spacing: spacing) {
                Text(" ")
                    .frame(width: labelWidth)

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
                        .frame(width: labelWidth)

                    // Cells
                    ForEach(0..<gridSize, id: \.self) { col in
                        let coord = Coordinate(row: row, col: col)
                        PlacementCellView(
                            coordinate: coord,
                            hasShip: hasShip(at: coord),
                            isPreview: isPreviewCell(coord),
                            isValidPlacement: isPreviewValid,
                            skin: skin,
                            theme: theme
                        )
                        .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
        .padding(8)
        .background(
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.boardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.boardBorder, lineWidth: 1)
                    )
                    .onAppear {
                        boardFrame = geo.frame(in: .named("placement"))
                    }
                    .onChange(of: geo.size) { _, _ in
                        boardFrame = geo.frame(in: .named("placement"))
                    }
            }
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 5)
                .onChanged { value in
                    // Offset by padding (8)
                    let adjustedLocation = CGPoint(
                        x: value.location.x - 8,
                        y: value.location.y - 8
                    )

                    if !isDragging {
                        // Starting a new drag
                        let startAdjusted = CGPoint(
                            x: value.startLocation.x - 8,
                            y: value.startLocation.y - 8
                        )

                        if let startCoord = coordinateFromPosition(startAdjusted) {
                            // Check if starting on a placed ship
                            if let ship = shipAt(startCoord) {
                                onPlacedShipDragStart(ship)
                                isDragging = true
                            } else if selectedShip != nil {
                                // Starting with a selected ship from the panel
                                isDragging = true
                            }
                        }
                    }

                    // Update hover position while dragging
                    if isDragging {
                        if let coord = coordinateFromPosition(adjustedLocation) {
                            if hoverCoordinate != coord {
                                hoverCoordinate = coord
                                // Light haptic when moving to new cell
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }
                        } else {
                            hoverCoordinate = nil
                        }
                    }
                }
                .onEnded { value in
                    guard isDragging else { return }
                    isDragging = false

                    let adjustedLocation = CGPoint(
                        x: value.location.x - 8,
                        y: value.location.y - 8
                    )

                    if let coord = coordinateFromPosition(adjustedLocation) {
                        onDragEnd(coord)
                    } else {
                        // Dragged outside board - cancel
                        onDragCancel()
                    }
                }
        )
    }

    private func hasShip(at coord: Coordinate) -> Bool {
        placedShips.contains { $0.occupies(coord) }
    }

    private func isPreviewCell(_ coord: Coordinate) -> Bool {
        guard let preview = previewShip else { return false }
        return preview.occupies(coord)
    }
}

struct PlacementCellView: View {
    let coordinate: Coordinate
    let hasShip: Bool
    let isPreview: Bool
    let isValidPlacement: Bool
    var skin: ShipSkin = PlayerInventory.shared.equippedSkin
    var theme: BoardTheme = PlayerInventory.shared.equippedTheme

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)

            // Ship indicator for already placed ships
            if hasShip && !isPreview {
                RoundedRectangle(cornerRadius: 2)
                    .fill(skin.shipFill)
                    .padding(4)
            }

            // Preview ship indicator (while dragging)
            if isPreview && !hasShip {
                RoundedRectangle(cornerRadius: 2)
                    .fill(isValidPlacement ? .green.opacity(0.7) : .red.opacity(0.7))
                    .padding(4)
            }

            // Placed ship border (subtle to indicate it's interactive)
            if hasShip && !isPreview {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(skin.shipBorder, lineWidth: 1)
            }

            // Preview border
            if isPreview && isValidPlacement && !hasShip {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.green, lineWidth: 2)
            } else if isPreview && !isValidPlacement && !hasShip {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.red, lineWidth: 2)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isPreview)
    }

    private var backgroundColor: Color {
        if hasShip && !isPreview {
            return skin.shipPlacedBackground
        }

        if isPreview {
            return isValidPlacement ? .green.opacity(0.3) : .red.opacity(0.3)
        }

        return theme.cellEmpty
    }
}

#Preview {
    NavigationStack {
        PlacementView(viewModel: {
            let vm = GameViewModel()
            vm.startNewGame(mode: .casual, difficulty: .easy)
            return vm
        }())
    }
}
