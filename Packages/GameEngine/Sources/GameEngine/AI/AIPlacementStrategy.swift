import Foundation

/// Protocol for AI ship placement strategies
public protocol AIPlacementStrategy: Sendable {
    /// Generate a valid ship placement for the given fleet
    /// - Parameters:
    ///   - fleetSizes: Sizes of ships to place (e.g., [5,4,3,3,2,2,1,1,1])
    ///   - mode: Game mode (affects ranked constraints)
    ///   - splitOrientation: For ranked mode, the board split orientation
    /// - Returns: Array of placed ships
    func generatePlacement(
        for fleetSizes: [Int],
        mode: GameMode,
        splitOrientation: BoardSplit?
    ) -> [Ship]
}

/// Factory for creating AI placement strategies
public struct AIPlacementFactory: Sendable {
    public static func strategy(for difficulty: AIDifficulty) -> AIPlacementStrategy {
        switch difficulty {
        case .easy:
            return RandomPlacement()
        case .medium:
            return HeatAvoidancePlacement()
        case .hard:
            return InvertedHeatPlacement()
        }
    }
}
