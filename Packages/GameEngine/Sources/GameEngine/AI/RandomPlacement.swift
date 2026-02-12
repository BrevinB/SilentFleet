import Foundation

/// Easy AI: Pure random valid placement
public struct RandomPlacement: AIPlacementStrategy, Sendable {

    public init() {}

    public func generatePlacement(
        for fleetSizes: [Int],
        mode: GameMode,
        splitOrientation: BoardSplit?
    ) -> [Ship] {
        // Sort by size descending (place larger ships first for better success rate)
        let sortedSizes = fleetSizes.sorted(by: >)

        var placedShips: [Ship] = []
        var attempts = 0
        let maxAttempts = 1000

        for size in sortedSizes {
            var placed = false

            while !placed && attempts < maxAttempts {
                attempts += 1

                // Random position and orientation
                let row = Int.random(in: 0..<Board.size)
                let col = Int.random(in: 0..<Board.size)
                let orientation = Orientation.allCases.randomElement()!

                let ship = Ship(
                    size: size,
                    origin: Coordinate(row: row, col: col),
                    orientation: orientation
                )

                // Check if valid placement
                if case .success = PlacementValidator.canPlace(ship: ship, on: placedShips) {
                    placedShips.append(ship)
                    placed = true
                }
            }

            if !placed {
                // Fallback: try all positions systematically
                if let ship = findAnyValidPlacement(size: size, existingShips: placedShips) {
                    placedShips.append(ship)
                }
            }
        }

        // Validate ranked constraints if applicable
        if mode == .ranked, let split = splitOrientation {
            if case .failure = PlacementValidator.validate(ships: placedShips, mode: mode, splitOrientation: split) {
                // Retry with constraint awareness
                return generateWithRankedConstraint(fleetSizes: sortedSizes, split: split)
            }
        }

        return placedShips
    }

    private func findAnyValidPlacement(size: Int, existingShips: [Ship]) -> Ship? {
        let validPlacements = PlacementValidator.validPlacements(
            forShipOfSize: size,
            existingShips: existingShips
        )
        return validPlacements.randomElement()
    }

    private func generateWithRankedConstraint(fleetSizes: [Int], split: BoardSplit) -> [Ship] {
        // Ensure at least one large ship (size >= 3) in each half
        let largeSizes = fleetSizes.filter { $0 >= 3 }
        let smallSizes = fleetSizes.filter { $0 < 3 }

        var placedShips: [Ship] = []

        // Place one large ship in first half
        if let firstLargeSize = largeSizes.first {
            if let ship = placeInHalf(size: firstLargeSize, half: .first, split: split, existingShips: placedShips) {
                placedShips.append(ship)
            }
        }

        // Place one large ship in second half
        if largeSizes.count > 1 {
            if let ship = placeInHalf(size: largeSizes[1], half: .second, split: split, existingShips: placedShips) {
                placedShips.append(ship)
            }
        }

        // Place remaining large ships randomly
        for size in largeSizes.dropFirst(2) {
            if let ship = findAnyValidPlacement(size: size, existingShips: placedShips) {
                placedShips.append(ship)
            }
        }

        // Place small ships randomly
        for size in smallSizes {
            if let ship = findAnyValidPlacement(size: size, existingShips: placedShips) {
                placedShips.append(ship)
            }
        }

        return placedShips
    }

    private enum BoardHalf {
        case first
        case second
    }

    private func placeInHalf(size: Int, half: BoardHalf, split: BoardSplit, existingShips: [Ship]) -> Ship? {
        let validPlacements = PlacementValidator.validPlacements(
            forShipOfSize: size,
            existingShips: existingShips
        )

        let filtered = validPlacements.filter { ship in
            switch half {
            case .first:
                return ship.coordinates.contains { split.isInFirstHalf($0) }
            case .second:
                return ship.coordinates.contains { split.isInSecondHalf($0) }
            }
        }

        return filtered.randomElement()
    }
}
