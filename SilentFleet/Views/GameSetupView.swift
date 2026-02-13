import SwiftUI
import GameEngine

struct GameSetupView: View {
    @ObservedObject var viewModel: GameViewModel
    let onStart: () -> Void

    @State private var selectedMode: GameMode = .casual
    @State private var selectedDifficulty: AIDifficulty = .medium
    @State private var selectedSplit: BoardSplit = .topBottom
    @State private var selectedGridSize: GridSize = .large
    @State private var currentStep: SetupStep = .mode
    @State private var contentOpacity: Double = 1

    @Environment(\.dismiss) private var dismiss

    enum SetupStep: CaseIterable {
        case mode
        case gridSize
        case difficulty
        case ranked
        case confirm
    }

    var body: some View {
        ZStack {
            // Background
            AnimatedOceanBackground()

            VStack(spacing: 0) {
                // Progress indicator
                SetupProgressView(currentStep: currentStep, selectedMode: selectedMode)
                    .padding(.top, 8)

                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        switch currentStep {
                        case .mode:
                            modeSelectionView
                        case .gridSize:
                            gridSizeSelectionView
                        case .difficulty:
                            difficultySelectionView
                        case .ranked:
                            rankedOptionsView
                        case .confirm:
                            confirmationView
                        }
                    }
                    .padding(24)
                    .opacity(contentOpacity)
                }

                // Bottom buttons
                bottomButtons
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if currentStep == .mode {
                        dismiss()
                    } else {
                        goBack()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(currentStep == .mode ? "Menu" : "Back")
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }

    // MARK: - Step Views

    private var modeSelectionView: some View {
        VStack(spacing: 20) {
            StepHeader(
                title: "Choose Game Mode",
                subtitle: "Select how you want to play"
            )

            VStack(spacing: 16) {
                ModeCard(
                    mode: .casual,
                    isSelected: selectedMode == .casual,
                    title: "Casual",
                    subtitle: "Relaxed gameplay",
                    features: [
                        "Ship sizes revealed when sunk",
                        "2 Sonar Pings available",
                        "2 Row Scans available",
                        "You always go first"
                    ],
                    icon: "sun.max.fill",
                    color: .green
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedMode = .casual
                    }
                    HapticManager.shared.buttonTap()
                    SoundManager.shared.buttonTap()
                }

                ModeCard(
                    mode: .ranked,
                    isSelected: selectedMode == .ranked,
                    title: "Ranked",
                    subtitle: "Competitive rules",
                    features: [
                        "Ship sizes hidden when sunk",
                        "1 Sonar Ping available",
                        "1 Row Scan available",
                        "Coin flip for first turn"
                    ],
                    icon: "trophy.fill",
                    color: .orange
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedMode = .ranked
                    }
                    HapticManager.shared.buttonTap()
                    SoundManager.shared.buttonTap()
                }
            }
        }
    }

    private var gridSizeSelectionView: some View {
        VStack(spacing: 20) {
            StepHeader(
                title: "Choose Grid Size",
                subtitle: "Smaller grids make for quicker games"
            )

            VStack(spacing: 12) {
                GridSizeCard(
                    gridSize: .small,
                    isSelected: selectedGridSize == .small,
                    title: "Small",
                    description: "6×6 grid with 5 ships. Quick battles.",
                    icon: "square.grid.2x2",
                    color: .green,
                    shipCount: GridSize.small.shipCount,
                    tileInfo: "\(GridSize.small.gridDescription) • \(GridSize.small.totalFleetTiles) tiles"
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedGridSize = .small
                    }
                    HapticManager.shared.buttonTap()
                    SoundManager.shared.buttonTap()
                }

                GridSizeCard(
                    gridSize: .medium,
                    isSelected: selectedGridSize == .medium,
                    title: "Medium",
                    description: "8×8 grid with 6 ships. Balanced gameplay.",
                    icon: "square.grid.3x3",
                    color: .orange,
                    shipCount: GridSize.medium.shipCount,
                    tileInfo: "\(GridSize.medium.gridDescription) • \(GridSize.medium.totalFleetTiles) tiles"
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedGridSize = .medium
                    }
                    HapticManager.shared.buttonTap()
                    SoundManager.shared.buttonTap()
                }

                GridSizeCard(
                    gridSize: .large,
                    isSelected: selectedGridSize == .large,
                    title: "Large",
                    description: "10×10 grid with 9 ships. Classic experience.",
                    icon: "square.grid.4x3fill",
                    color: .blue,
                    shipCount: GridSize.large.shipCount,
                    tileInfo: "\(GridSize.large.gridDescription) • \(GridSize.large.totalFleetTiles) tiles"
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedGridSize = .large
                    }
                    HapticManager.shared.buttonTap()
                    SoundManager.shared.buttonTap()
                }
            }
        }
    }

    private var difficultySelectionView: some View {
        VStack(spacing: 20) {
            StepHeader(
                title: "Select Difficulty",
                subtitle: "Choose your opponent's skill level"
            )

            VStack(spacing: 12) {
                DifficultyCard(
                    difficulty: .easy,
                    isSelected: selectedDifficulty == .easy,
                    title: "Easy",
                    description: "Random ship placement and targeting. Good for learning.",
                    icon: "face.smiling",
                    color: .green,
                    stars: 1
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedDifficulty = .easy
                    }
                    HapticManager.shared.buttonTap()
                    SoundManager.shared.buttonTap()
                }

                DifficultyCard(
                    difficulty: .medium,
                    isSelected: selectedDifficulty == .medium,
                    title: "Medium",
                    description: "Smart placement and hunt/target strategy. A fair challenge.",
                    icon: "brain",
                    color: .orange,
                    stars: 2
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedDifficulty = .medium
                    }
                    HapticManager.shared.buttonTap()
                    SoundManager.shared.buttonTap()
                }

                DifficultyCard(
                    difficulty: .hard,
                    isSelected: selectedDifficulty == .hard,
                    title: "Hard",
                    description: "Advanced strategies and probability-based targeting.",
                    icon: "bolt.fill",
                    color: .red,
                    stars: 3
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedDifficulty = .hard
                    }
                    HapticManager.shared.buttonTap()
                    SoundManager.shared.buttonTap()
                }
            }
        }
    }

    private var rankedOptionsView: some View {
        VStack(spacing: 20) {
            StepHeader(
                title: "Board Split",
                subtitle: "Choose how the board is divided for placement rules"
            )

            Text("In Ranked mode, you must place at least one large ship (size 3+) in each half of the board.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 16) {
                SplitCard(
                    split: .topBottom,
                    isSelected: selectedSplit == .topBottom,
                    title: "Top / Bottom",
                    icon: "rectangle.split.1x2"
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedSplit = .topBottom
                    }
                    HapticManager.shared.buttonTap()
                    SoundManager.shared.buttonTap()
                }

                SplitCard(
                    split: .leftRight,
                    isSelected: selectedSplit == .leftRight,
                    title: "Left / Right",
                    icon: "rectangle.split.2x1"
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedSplit = .leftRight
                    }
                    HapticManager.shared.buttonTap()
                    SoundManager.shared.buttonTap()
                }
            }

            // Visual preview
            BoardSplitPreview(split: selectedSplit)
        }
    }

    private var confirmationView: some View {
        VStack(spacing: 24) {
            StepHeader(
                title: "Ready for Battle?",
                subtitle: "Review your settings"
            )

            // Settings summary
            VStack(spacing: 12) {
                SettingSummaryRow(
                    icon: selectedMode == .casual ? "sun.max.fill" : "trophy.fill",
                    label: "Mode",
                    value: selectedMode == .casual ? "Casual" : "Ranked",
                    color: selectedMode == .casual ? .green : .orange
                )

                SettingSummaryRow(
                    icon: gridSizeIcon,
                    label: "Grid",
                    value: "\(selectedGridSize.displayName) (\(selectedGridSize.gridDescription))",
                    color: gridSizeColor
                )

                SettingSummaryRow(
                    icon: "cpu",
                    label: "Difficulty",
                    value: difficultyName,
                    color: difficultyColor
                )

                if selectedMode == .ranked {
                    SettingSummaryRow(
                        icon: "rectangle.split.2x1",
                        label: "Board Split",
                        value: selectedSplit == .topBottom ? "Top/Bottom" : "Left/Right",
                        color: .blue
                    )
                }

                Divider()
                    .background(.white.opacity(0.2))

                // Power-ups info
                HStack(spacing: 24) {
                    PowerUpInfo(
                        icon: "dot.radiowaves.left.and.right",
                        name: "Sonar",
                        count: selectedMode == .casual ? 2 : 1
                    )

                    PowerUpInfo(
                        icon: "line.horizontal.3",
                        name: "Row Scan",
                        count: selectedMode == .casual ? 2 : 1
                    )
                }
                .padding(.top, 8)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.1))
            )

            // Fleet info
            VStack(spacing: 8) {
                Text("Your Fleet (\(selectedGridSize.shipCount) ships)")
                    .font(.headline)
                    .foregroundStyle(.white)

                HStack(spacing: 8) {
                    ForEach(Array(selectedGridSize.fleetSizes.enumerated()), id: \.offset) { _, size in
                        HStack(spacing: 2) {
                            ForEach(0..<size, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(.white.opacity(0.6))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white.opacity(0.1))
                        )
                    }
                }
            }
        }
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            // Next/Start button
            Button {
                HapticManager.shared.buttonTap()
                if currentStep == .confirm {
                    startGame()
                } else {
                    goNext()
                }
            } label: {
                HStack {
                    Text(currentStep == .confirm ? "Start Battle" : "Continue")
                        .font(.headline)

                    if currentStep == .confirm {
                        Image(systemName: "flag.fill")
                    } else {
                        Image(systemName: "arrow.right")
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(currentStep == .confirm ? .green : .blue)
                )
            }
        }
        .padding(24)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.5))
                .ignoresSafeArea()
        )
    }

    // MARK: - Navigation

    private func goNext() {
        withAnimation(.easeInOut(duration: 0.15)) {
            contentOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            switch currentStep {
            case .mode:
                currentStep = .gridSize
            case .gridSize:
                currentStep = .difficulty
            case .difficulty:
                currentStep = selectedMode == .ranked ? .ranked : .confirm
            case .ranked:
                currentStep = .confirm
            case .confirm:
                break
            }

            withAnimation(.easeInOut(duration: 0.15)) {
                contentOpacity = 1
            }
        }
    }

    private func goBack() {
        withAnimation(.easeInOut(duration: 0.15)) {
            contentOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            switch currentStep {
            case .mode:
                break
            case .gridSize:
                currentStep = .mode
            case .difficulty:
                currentStep = .gridSize
            case .ranked:
                currentStep = .difficulty
            case .confirm:
                currentStep = selectedMode == .ranked ? .ranked : .difficulty
            }

            withAnimation(.easeInOut(duration: 0.15)) {
                contentOpacity = 1
            }
        }
    }

    private func startGame() {
        viewModel.startNewGame(
            mode: selectedMode,
            difficulty: selectedDifficulty,
            split: selectedMode == .ranked ? selectedSplit : nil,
            gridSize: selectedGridSize
        )
        onStart()
    }

    // MARK: - Helpers

    private var difficultyName: String {
        switch selectedDifficulty {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    private var difficultyColor: Color {
        switch selectedDifficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }

    private var gridSizeIcon: String {
        switch selectedGridSize {
        case .small: return "square.grid.2x2"
        case .medium: return "square.grid.3x3"
        case .large: return "square.grid.4x3fill"
        }
    }

    private var gridSizeColor: Color {
        switch selectedGridSize {
        case .small: return .green
        case .medium: return .orange
        case .large: return .blue
        }
    }
}

// MARK: - Supporting Views

struct SetupProgressView: View {
    let currentStep: GameSetupView.SetupStep
    let selectedMode: GameMode

    private var steps: [GameSetupView.SetupStep] {
        if selectedMode == .ranked {
            return [.mode, .gridSize, .difficulty, .ranked, .confirm]
        } else {
            return [.mode, .gridSize, .difficulty, .confirm]
        }
    }

    private var currentIndex: Int {
        steps.firstIndex(of: currentStep) ?? 0
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<steps.count, id: \.self) { index in
                Capsule()
                    .fill(index <= currentIndex ? Color.blue : Color.white.opacity(0.3))
                    .frame(height: 4)
                    .animation(.spring(response: 0.3), value: currentIndex)
            }
        }
        .padding(.horizontal, 24)
    }
}

struct StepHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

struct ModeCard: View {
    let mode: GameMode
    let isSelected: Bool
    let title: String
    let subtitle: String
    let features: [String]
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.white)

                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isSelected ? color : .white.opacity(0.3))
                }

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(features, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.caption2)
                                .foregroundStyle(color.opacity(0.8))

                            Text(feature)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(isSelected ? 0.15 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? color : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DifficultyCard: View {
    let difficulty: AIDifficulty
    let isSelected: Bool
    let title: String
    let description: String
    let icon: String
    let color: Color
    let stars: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.white)

                        // Star rating
                        HStack(spacing: 2) {
                            ForEach(0..<3, id: \.self) { i in
                                Image(systemName: i < stars ? "star.fill" : "star")
                                    .font(.caption2)
                                    .foregroundStyle(i < stars ? color : .white.opacity(0.3))
                            }
                        }
                    }

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? color : .white.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(isSelected ? 0.15 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? color : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GridSizeCard: View {
    let gridSize: GridSize
    let isSelected: Bool
    let title: String
    let description: String
    let icon: String
    let color: Color
    let shipCount: Int
    let tileInfo: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.white)

                        Text(tileInfo)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(2)

                    // Ship preview
                    HStack(spacing: 4) {
                        ForEach(Array(gridSize.fleetSizes.enumerated()), id: \.offset) { _, size in
                            HStack(spacing: 1) {
                                ForEach(0..<size, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(color.opacity(0.6))
                                        .frame(width: 5, height: 8)
                                }
                            }
                            .padding(2)
                            .background(
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(.white.opacity(0.08))
                            )
                        }
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? color : .white.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(isSelected ? 0.15 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? color : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SplitCard: View {
    let split: BoardSplit
    let isSelected: Bool
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(isSelected ? .blue : .white.opacity(0.5))

                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(isSelected ? 0.15 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? .blue : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BoardSplitPreview: View {
    let split: BoardSplit

    var body: some View {
        VStack(spacing: 4) {
            if split == .topBottom {
                Rectangle()
                    .fill(.blue.opacity(0.3))
                    .overlay(Text("Top Half").font(.caption2).foregroundStyle(.white))
                Rectangle()
                    .fill(.orange.opacity(0.3))
                    .overlay(Text("Bottom Half").font(.caption2).foregroundStyle(.white))
            } else {
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(.blue.opacity(0.3))
                        .overlay(Text("Left").font(.caption2).foregroundStyle(.white))
                    Rectangle()
                        .fill(.orange.opacity(0.3))
                        .overlay(Text("Right").font(.caption2).foregroundStyle(.white))
                }
            }
        }
        .frame(width: 150, height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SettingSummaryRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(label)
                .foregroundStyle(.white.opacity(0.7))

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
    }
}

struct PowerUpInfo: View {
    let icon: String
    let name: String
    let count: Int

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.cyan)

            Text(name)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

            Text("×\(count)")
                .font(.headline)
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    NavigationStack {
        GameSetupView(viewModel: GameViewModel()) {}
    }
}
