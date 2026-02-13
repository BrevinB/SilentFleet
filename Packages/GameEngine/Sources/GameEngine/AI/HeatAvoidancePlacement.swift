import Foundation

/// Medium AI: Avoids common attack patterns using heat map avoidance
/// Places ships in less commonly attacked areas
public struct HeatAvoidancePlacement: AIPlacementStrategy, Sendable {

    public init() {}

    public func generatePlacement(
        for fleetSizes: [Int],
        mode: GameMode,
        splitOrientation: BoardSplit?,
        boardSize: Int
    ) -> [Ship] {
        let sortedSizes = fleetSizes.sorted(by: >)
        var placedShips: [Ship] = []

        // Generate heat map (common attack patterns)
        let heatMap = generateAttackHeatMap(boardSize: boardSize)

        for size in sortedSizes {
            // Get all valid placements
            let validPlacements = PlacementValidator.validPlacements(
                forShipOfSize: size,
                existingShips: placedShips,
                mode: mode,
                splitOrientation: splitOrientation,
                boardSize: boardSize
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
            let gridSize = GridSize.allCases.first { $0.boardSize == boardSize } ?? .large
            if case .failure = PlacementValidator.validate(ships: placedShips, mode: mode, splitOrientation: split, gridSize: gridSize) {
                // Fallback to random placement with constraints
                return RandomPlacement().generatePlacement(for: fleetSizes, mode: mode, splitOrientation: split, boardSize: boardSize)
            }
        }

        return placedShips
    }

    /// Generate a heat map based on common human attack patterns
    private func generateAttackHeatMap(boardSize: Int) -> [[Double]] {
        var heatMap = Array(repeating: Array(repeating: 0.0, count: boardSize), count: boardSize)

        // Pattern 1: Center is often attacked first (probability-based hunting)
        let centerRow = boardSize / 2
        let centerCol = boardSize / 2
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                let distFromCenter = abs(row - centerRow) + abs(col - centerCol)
                heatMap[row][col] += Double(max(0, boardSize - distFromCenter)) * 0.5
            }
        }

        // Pattern 2: Checkerboard pattern (parity hunting)
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                if (row + col) % 2 == 0 {
                    heatMap[row][col] += 3.0
                }
            }
        }

        // Pattern 3: Edges are attacked less frequently
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                if row == 0 || row == boardSize - 1 || col == 0 || col == boardSize - 1 {
                    heatMap[row][col] -= 2.0
                }
            }
        }

        // Pattern 4: Corners rarely attacked early
        let corners = [
            (0, 0), (0, boardSize - 1),
            (boardSize - 1, 0), (boardSize - 1, boardSize - 1)
        ]
        for (row, col) in corners {
            heatMap[row][col] -= 3.0
        }

        return heatMap
    }

    /// Calculate the total heat score for a ship placement
    private func calculateHeatScore(for ship: Ship, heatMap: [[Double]]) -> Double {
        var total = 0.0
        let boardSize = heatMap.count
        for coord in ship.coordinates {
            if coord.isValid(forBoardSize: boardSize) {
                total += heatMap[coord.row][coord.col]
            }
        }
        return total
    }
}
