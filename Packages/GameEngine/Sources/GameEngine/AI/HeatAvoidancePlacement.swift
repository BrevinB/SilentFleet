import Foundation

/// Medium AI: Avoids common attack patterns using heat map avoidance
/// Places ships in less commonly attacked areas
public struct HeatAvoidancePlacement: AIPlacementStrategy, Sendable {

    public init() {}

    public func generatePlacement(
        for fleetSizes: [Int],
        mode: GameMode,
        splitOrientation: BoardSplit?
    ) -> [Ship] {
        let sortedSizes = fleetSizes.sorted(by: >)
        var placedShips: [Ship] = []

        // Generate heat map (common attack patterns)
        let heatMap = generateAttackHeatMap()

        for size in sortedSizes {
            // Get all valid placements
            let validPlacements = PlacementValidator.validPlacements(
                forShipOfSize: size,
                existingShips: placedShips,
                mode: mode,
                splitOrientation: splitOrientation
            )

            guard !validPlacements.isEmpty else { continue }

            // Score each placement (lower heat = better)
            let scoredPlacements = validPlacements.map { ship -> (Ship, Double) in
                let score = calculateHeatScore(for: ship, heatMap: heatMap)
                return (ship, score)
            }

            // Sort by score ascending (prefer lower heat)
            let sorted = scoredPlacements.sorted { $0.1 < $1.1 }

            // Pick from top 25% with some randomness
            let topCount = max(1, sorted.count / 4)
            let topPlacements = Array(sorted.prefix(topCount))

            if let (selectedShip, _) = topPlacements.randomElement() {
                placedShips.append(selectedShip)
            }
        }

        // Validate ranked constraints
        if mode == .ranked, let split = splitOrientation {
            if case .failure = PlacementValidator.validate(ships: placedShips, mode: mode, splitOrientation: split) {
                // Fallback to random placement with constraints
                return RandomPlacement().generatePlacement(for: fleetSizes, mode: mode, splitOrientation: split)
            }
        }

        return placedShips
    }

    /// Generate a heat map based on common human attack patterns
    private func generateAttackHeatMap() -> [[Double]] {
        var heatMap = Array(repeating: Array(repeating: 0.0, count: Board.size), count: Board.size)

        // Pattern 1: Center is often attacked first (probability-based hunting)
        let centerRow = Board.size / 2
        let centerCol = Board.size / 2
        for row in 0..<Board.size {
            for col in 0..<Board.size {
                let distFromCenter = abs(row - centerRow) + abs(col - centerCol)
                heatMap[row][col] += Double(max(0, 10 - distFromCenter)) * 0.5
            }
        }

        // Pattern 2: Checkerboard pattern (parity hunting)
        for row in 0..<Board.size {
            for col in 0..<Board.size {
                if (row + col) % 2 == 0 {
                    heatMap[row][col] += 3.0
                }
            }
        }

        // Pattern 3: Edges are attacked less frequently
        for row in 0..<Board.size {
            for col in 0..<Board.size {
                if row == 0 || row == Board.size - 1 || col == 0 || col == Board.size - 1 {
                    heatMap[row][col] -= 2.0
                }
            }
        }

        // Pattern 4: Corners rarely attacked early
        let corners = [
            (0, 0), (0, Board.size - 1),
            (Board.size - 1, 0), (Board.size - 1, Board.size - 1)
        ]
        for (row, col) in corners {
            heatMap[row][col] -= 3.0
        }

        return heatMap
    }

    /// Calculate the total heat score for a ship placement
    private func calculateHeatScore(for ship: Ship, heatMap: [[Double]]) -> Double {
        var total = 0.0
        for coord in ship.coordinates {
            if coord.isValid {
                total += heatMap[coord.row][coord.col]
            }
        }
        return total
    }
}
