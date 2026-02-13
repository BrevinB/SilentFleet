import Foundation

/// Hard AI: Uses inverted heatmap with multiple placement profiles
/// No cheating - respects all constraints but uses sophisticated placement strategies
public struct InvertedHeatPlacement: AIPlacementStrategy, Sendable {

    /// Different placement profiles for variety
    private enum PlacementProfile: CaseIterable, Sendable {
        case edgeHugger       // Prefers edges and corners
        case centerMass       // Clusters ships in center (reverse psychology)
        case diagonal         // Places along diagonals
        case scattered        // Maximizes distance between ships
        case halfBoard        // Concentrates in one half
    }

    public init() {}

    public func generatePlacement(
        for fleetSizes: [Int],
        mode: GameMode,
        splitOrientation: BoardSplit?,
        boardSize: Int
    ) -> [Ship] {
        // Randomly select a placement profile
        let profile = PlacementProfile.allCases.randomElement() ?? .scattered

        return generateWithProfile(
            profile: profile,
            fleetSizes: fleetSizes,
            mode: mode,
            splitOrientation: splitOrientation,
            boardSize: boardSize
        )
    }

    private func generateWithProfile(
        profile: PlacementProfile,
        fleetSizes: [Int],
        mode: GameMode,
        splitOrientation: BoardSplit?,
        boardSize: Int
    ) -> [Ship] {
        let sortedSizes = fleetSizes.sorted(by: >)
        var placedShips: [Ship] = []

        // Generate scoring map based on profile
        let scoreMap = generateScoreMap(for: profile, boardSize: boardSize)

        for size in sortedSizes {
            let validPlacements = PlacementValidator.validPlacements(
                forShipOfSize: size,
                existingShips: placedShips,
                mode: mode,
                splitOrientation: splitOrientation,
                boardSize: boardSize
            )

            guard !validPlacements.isEmpty else { continue }

            // Score placements based on profile
            var scoredPlacements = validPlacements.map { ship -> (Ship, Double) in
                var score = calculateBaseScore(for: ship, scoreMap: scoreMap)

                // Profile-specific adjustments
                switch profile {
                case .scattered:
                    score += scatteredBonus(for: ship, existingShips: placedShips)
                case .halfBoard:
                    score += halfBoardBonus(for: ship, boardSize: boardSize)
                default:
                    break
                }

                return (ship, score)
            }

            // Sort by score descending (higher = better)
            scoredPlacements.sort { $0.1 > $1.1 }

            // Add randomness: pick from top 20% with weighted random
            let topCount = max(1, scoredPlacements.count / 5)
            let topPlacements = Array(scoredPlacements.prefix(topCount))

            // Weighted random selection
            if let selected = weightedRandomSelect(from: topPlacements) {
                placedShips.append(selected)
            }
        }

        // Validate ranked constraints
        if mode == .ranked, let split = splitOrientation {
            let gridSize = GridSize.allCases.first { $0.boardSize == boardSize } ?? .large
            if case .failure = PlacementValidator.validate(ships: placedShips, mode: mode, splitOrientation: split, gridSize: gridSize) {
                // Retry with different profile or fallback
                let alternateProfile = PlacementProfile.allCases.filter { $0 != profile }.randomElement() ?? .scattered
                return generateWithProfile(
                    profile: alternateProfile,
                    fleetSizes: fleetSizes,
                    mode: mode,
                    splitOrientation: split,
                    boardSize: boardSize
                )
            }
        }

        return placedShips
    }

    private func generateScoreMap(for profile: PlacementProfile, boardSize: Int) -> [[Double]] {
        var map = Array(repeating: Array(repeating: 5.0, count: boardSize), count: boardSize)
        let center = Double(boardSize - 1) / 2.0
        let half = boardSize / 2

        switch profile {
        case .edgeHugger:
            // High scores on edges and corners
            for row in 0..<boardSize {
                for col in 0..<boardSize {
                    if row == 0 || row == boardSize - 1 || col == 0 || col == boardSize - 1 {
                        map[row][col] += 8.0
                    }
                    // Extra bonus for corners
                    if (row == 0 || row == boardSize - 1) && (col == 0 || col == boardSize - 1) {
                        map[row][col] += 5.0
                    }
                    // Penalty for center
                    let centerDist = abs(Double(row) - center) + abs(Double(col) - center)
                    if centerDist < 3 {
                        map[row][col] -= 4.0
                    }
                }
            }

        case .centerMass:
            // High scores in center (reverse psychology)
            for row in 0..<boardSize {
                for col in 0..<boardSize {
                    let centerDist = abs(Double(row) - center) + abs(Double(col) - center)
                    map[row][col] += max(0, 8 - centerDist)
                }
            }

        case .diagonal:
            // High scores along diagonals
            for row in 0..<boardSize {
                for col in 0..<boardSize {
                    // Main diagonal
                    if row == col {
                        map[row][col] += 6.0
                    }
                    // Anti-diagonal
                    if row + col == boardSize - 1 {
                        map[row][col] += 6.0
                    }
                    // Near diagonals
                    if abs(row - col) == 1 || abs(row + col - (boardSize - 1)) == 1 {
                        map[row][col] += 3.0
                    }
                }
            }

        case .scattered:
            // Even distribution - base map is fine
            // Actual scattering is handled in bonus calculation
            break

        case .halfBoard:
            // Randomly prefer one half
            let preferFirst = Bool.random()
            for row in 0..<boardSize {
                for col in 0..<boardSize {
                    let inFirstHalf = row < half
                    if inFirstHalf == preferFirst {
                        map[row][col] += 5.0
                    }
                }
            }
        }

        // Add anti-checkerboard bias (avoid parity hunting)
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                if (row + col) % 2 == 1 {
                    map[row][col] += 2.0
                }
            }
        }

        return map
    }

    private func calculateBaseScore(for ship: Ship, scoreMap: [[Double]]) -> Double {
        var total = 0.0
        let boardSize = scoreMap.count
        for coord in ship.coordinates {
            if coord.isValid(forBoardSize: boardSize) {
                total += scoreMap[coord.row][coord.col]
            }
        }
        return total / Double(ship.size)  // Normalize by size
    }

    private func scatteredBonus(for ship: Ship, existingShips: [Ship]) -> Double {
        guard !existingShips.isEmpty else { return 0 }

        // Calculate minimum distance to any existing ship
        var minDist = Double.infinity
        for coord in ship.coordinates {
            for existing in existingShips {
                for existingCoord in existing.coordinates {
                    let dist = Double(abs(coord.row - existingCoord.row) + abs(coord.col - existingCoord.col))
                    minDist = min(minDist, dist)
                }
            }
        }

        // Reward greater distance
        return min(minDist * 2, 20)
    }

    private func halfBoardBonus(for ship: Ship, boardSize: Int) -> Double {
        let half = boardSize / 2
        // Reward ships that are entirely in one half
        let inTop = ship.coordinates.allSatisfy { $0.row < half }
        let inBottom = ship.coordinates.allSatisfy { $0.row >= half }
        let inLeft = ship.coordinates.allSatisfy { $0.col < half }
        let inRight = ship.coordinates.allSatisfy { $0.col >= half }

        if inTop || inBottom || inLeft || inRight {
            return 5.0
        }
        return 0
    }

    private func weightedRandomSelect(from placements: [(Ship, Double)]) -> Ship? {
        guard !placements.isEmpty else { return nil }

        // Normalize scores to positive values
        let minScore = placements.map { $0.1 }.min() ?? 0
        let adjusted = placements.map { ($0.0, $0.1 - minScore + 1) }

        let totalWeight = adjusted.reduce(0) { $0 + $1.1 }
        var random = Double.random(in: 0..<totalWeight)

        for (ship, weight) in adjusted {
            random -= weight
            if random <= 0 {
                return ship
            }
        }

        return placements.first?.0
    }
}
