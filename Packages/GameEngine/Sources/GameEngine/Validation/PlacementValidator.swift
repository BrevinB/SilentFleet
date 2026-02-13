import Foundation

/// Validates ship placements according to game rules
public struct PlacementValidator: Sendable {

    // MARK: - Single Ship Validation

    /// Validate that a ship can be placed given existing ships on the board
    /// - Parameters:
    ///   - ship: The ship to validate
    ///   - existingShips: Ships already placed on the board
    ///   - boardSize: Size of the board (defaults to 10)
    /// - Returns: Success or a PlacementError
    public static func canPlace(
        ship: Ship,
        on existingShips: [Ship],
        boardSize: Int = Board.size
    ) -> Result<Void, PlacementError> {
        // Check bounds
        if !ship.isWithinBounds(boardSize: boardSize) {
            return .failure(.outOfBounds(ship: ship))
        }

        let shipCoords = Set(ship.coordinates)

        for existing in existingShips {
            let existingCoords = Set(existing.coordinates)

            // Check overlap
            let overlapping = shipCoords.intersection(existingCoords)
            if let overlapCoord = overlapping.first {
                return .failure(.overlap(ship: ship, existingShip: existing, at: overlapCoord))
            }

            // Check adjacency (no touching allowed)
            let existingAdjacent = existing.adjacentCoordinates(boardSize: boardSize)
            let adjacentConflict = shipCoords.intersection(existingAdjacent)
            if let conflictCoord = adjacentConflict.first {
                return .failure(.adjacentToShip(ship: ship, existingShip: existing, at: conflictCoord))
            }

            // Also check the reverse: if any of ship's adjacent coords touch existing
            let shipAdjacent = ship.adjacentCoordinates(boardSize: boardSize)
            let reverseConflict = existingCoords.intersection(shipAdjacent)
            if let conflictCoord = reverseConflict.first {
                return .failure(.adjacentToShip(ship: ship, existingShip: existing, at: conflictCoord))
            }
        }

        return .success(())
    }

    // MARK: - Full Fleet Validation

    /// Validate a complete fleet placement
    /// - Parameters:
    ///   - ships: All ships in the fleet
    ///   - mode: Game mode (affects ranked-specific rules)
    ///   - splitOrientation: For ranked mode, the board split orientation
    ///   - gridSize: Grid size configuration (defaults to .large for classic)
    /// - Returns: Success or a PlacementError
    public static func validate(
        ships: [Ship],
        mode: GameMode,
        splitOrientation: BoardSplit? = nil,
        gridSize: GridSize = .large
    ) -> Result<Void, PlacementError> {
        let boardSize = gridSize.boardSize

        // Check for duplicate IDs
        let ids = ships.map { $0.id }
        let uniqueIDs = Set(ids)
        if ids.count != uniqueIDs.count {
            // Find the duplicate
            var seen = Set<UUID>()
            for id in ids {
                if seen.contains(id) {
                    return .failure(.duplicateShipID(id: id))
                }
                seen.insert(id)
            }
        }

        // Check fleet composition
        let expectedSizes = gridSize.fleetSizes.sorted()
        let actualSizes = ships.map { $0.size }.sorted()
        if expectedSizes != actualSizes {
            return .failure(.fleetIncomplete(expected: expectedSizes, got: actualSizes))
        }

        // Validate each ship individually and against others
        for (index, ship) in ships.enumerated() {
            // Validate ship size
            if !gridSize.fleetSizes.contains(ship.size) {
                return .failure(.invalidShipSize(size: ship.size))
            }

            // Validate bounds
            if !ship.isWithinBounds(boardSize: boardSize) {
                return .failure(.outOfBounds(ship: ship))
            }

            // Validate against all previous ships (to avoid duplicate checks)
            let previousShips = Array(ships[0..<index])
            if case .failure(let error) = canPlace(ship: ship, on: previousShips, boardSize: boardSize) {
                return .failure(error)
            }
        }

        // Ranked mode: validate half-board constraint
        if mode == .ranked {
            if let split = splitOrientation {
                if case .failure(let error) = validateRankedHalfConstraint(ships: ships, split: split, boardSize: boardSize) {
                    return .failure(error)
                }
            }
        }

        return .success(())
    }

    // MARK: - Ranked Half-Board Constraint

    /// Validates that at least one ship of size >= 3 is in each half of the board
    /// A ship is considered "in" a half if ANY of its tiles are in that half
    private static func validateRankedHalfConstraint(
        ships: [Ship],
        split: BoardSplit,
        boardSize: Int = Board.size
    ) -> Result<Void, PlacementError> {
        let largeShips = ships.filter { $0.size >= 3 }

        // Check if any large ship has tiles in the first half
        let hasLargeInFirstHalf = largeShips.contains { ship in
            ship.coordinates.contains { split.isInFirstHalf($0, boardSize: boardSize) }
        }

        // Check if any large ship has tiles in the second half
        let hasLargeInSecondHalf = largeShips.contains { ship in
            ship.coordinates.contains { split.isInSecondHalf($0, boardSize: boardSize) }
        }

        if !hasLargeInFirstHalf {
            return .failure(.rankedHalfConstraintViolation(
                half: split.firstHalfName,
                message: "No ship of size >= 3 has any tiles in the \(split.firstHalfName) half"
            ))
        }

        if !hasLargeInSecondHalf {
            return .failure(.rankedHalfConstraintViolation(
                half: split.secondHalfName,
                message: "No ship of size >= 3 has any tiles in the \(split.secondHalfName) half"
            ))
        }

        return .success(())
    }

    // MARK: - Helper Methods

    /// Get all valid placements for a ship of given size on a board with existing ships
    public static func validPlacements(
        forShipOfSize size: Int,
        existingShips: [Ship],
        mode: GameMode = .casual,
        splitOrientation: BoardSplit? = nil,
        boardSize: Int = Board.size
    ) -> [Ship] {
        var valid: [Ship] = []

        for row in 0..<boardSize {
            for col in 0..<boardSize {
                for orientation in Orientation.allCases {
                    let ship = Ship(
                        size: size,
                        origin: Coordinate(row: row, col: col),
                        orientation: orientation
                    )

                    if case .success = canPlace(ship: ship, on: existingShips, boardSize: boardSize) {
                        valid.append(ship)
                    }
                }
            }
        }

        return valid
    }

    /// Check if a coordinate is safe to place any ship (not occupied and not adjacent to any ship)
    public static func isSafeCoordinate(
        _ coord: Coordinate,
        existingShips: [Ship],
        boardSize: Int = Board.size
    ) -> Bool {
        guard coord.isValid(forBoardSize: boardSize) else { return false }

        for ship in existingShips {
            if ship.occupies(coord) {
                return false
            }
            if ship.adjacentCoordinates(boardSize: boardSize).contains(coord) {
                return false
            }
        }

        return true
    }
}
