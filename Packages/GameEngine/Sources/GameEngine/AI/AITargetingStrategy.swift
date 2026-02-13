import Foundation

/// Protocol for AI shot selection strategies
public protocol AITargetingStrategy: Sendable {
    /// Select the next coordinate to fire at
    /// - Parameters:
    ///   - board: The opponent's board (with shot history visible)
    ///   - previousResults: History of shot results on this board
    /// - Returns: The coordinate to fire at
    func selectTarget(
        board: Board,
        previousResults: [TurnResult]
    ) -> Coordinate
}

/// AI targeting mode
public enum TargetingMode: Sendable {
    case hunt      // Searching for ships
    case target    // Found a hit, targeting adjacent cells
}

/// Factory for creating AI targeting strategies
public struct AITargetingFactory: Sendable {
    public static func strategy(for difficulty: AIDifficulty) -> AITargetingStrategy {
        switch difficulty {
        case .easy:
            return RandomTargeting()
        case .medium:
            return HuntTargetStrategy(accuracy: 0.7)
        case .hard:
            return HuntTargetStrategy(accuracy: 0.9, useProbabilityDensity: true)
        }
    }
}

// MARK: - Random Targeting (Easy)

/// Simple random targeting - picks any unshot cell
public struct RandomTargeting: AITargetingStrategy, Sendable {
    public init() {}

    public func selectTarget(board: Board, previousResults: [TurnResult]) -> Coordinate {
        let boardSize = board.boardSize
        var unshot: [Coordinate] = []
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                let coord = Coordinate(row: row, col: col)
                if !board.hasBeenShot(at: coord) {
                    unshot.append(coord)
                }
            }
        }
        return unshot.randomElement() ?? Coordinate(row: 0, col: 0)
    }
}

// MARK: - Hunt/Target Strategy (Medium/Hard)

/// Smart targeting that hunts for ships and targets after hits
public struct HuntTargetStrategy: AITargetingStrategy, Sendable {
    /// Probability of making the "smart" choice vs random
    let accuracy: Double

    /// Whether to use probability density for hunt mode
    let useProbabilityDensity: Bool

    public init(accuracy: Double = 0.8, useProbabilityDensity: Bool = false) {
        self.accuracy = accuracy
        self.useProbabilityDensity = useProbabilityDensity
    }

    public func selectTarget(board: Board, previousResults: [TurnResult]) -> Coordinate {
        let boardSize = board.boardSize

        // Get all unshot coordinates
        let unshotCoords = getUnshotCoordinates(board: board, boardSize: boardSize)
        guard !unshotCoords.isEmpty else {
            return Coordinate(row: 0, col: 0)
        }

        // Find unhit hits (hits that aren't part of a sunk ship)
        let activeHits = getActiveHits(board: board, boardSize: boardSize)

        // If we have active hits, ALWAYS pursue them (no ship left behind!)
        // The accuracy only affects hunt mode decisions
        if !activeHits.isEmpty {
            // TARGET MODE: We have active hits to follow up on
            // Accuracy affects whether we make optimal vs random adjacent choice
            let makeSmartChoice = Double.random(in: 0...1) < accuracy
            if makeSmartChoice {
                return selectTargetModeShot(activeHits: activeHits, board: board, unshotCoords: unshotCoords, boardSize: boardSize)
            } else {
                // Even when "not smart", still target near hits, just pick randomly among them
                let randomHit = activeHits.randomElement()!
                let neighbors = randomHit.orthogonalNeighbors(boardSize: boardSize).filter { unshotCoords.contains($0) }
                if let target = neighbors.randomElement() {
                    return target
                }
                // If no neighbors available, use smart targeting anyway
                return selectTargetModeShot(activeHits: activeHits, board: board, unshotCoords: unshotCoords, boardSize: boardSize)
            }
        }

        // HUNT MODE: Looking for ships
        let makeSmartChoice = Double.random(in: 0...1) < accuracy
        if useProbabilityDensity && makeSmartChoice {
            return selectProbabilityBasedShot(board: board, unshotCoords: unshotCoords, boardSize: boardSize)
        } else if makeSmartChoice {
            return selectCheckerboardShot(unshotCoords: unshotCoords)
        } else {
            // Random hunt
            return unshotCoords.randomElement() ?? Coordinate(row: 0, col: 0)
        }
    }

    // MARK: - Target Mode

    private func selectTargetModeShot(
        activeHits: [Coordinate],
        board: Board,
        unshotCoords: Set<Coordinate>,
        boardSize: Int
    ) -> Coordinate {
        // Group hits into clusters (adjacent hits likely from same ship)
        let clusters = groupHitsIntoClusters(activeHits, boardSize: boardSize)

        // Prioritize clusters with 2+ hits (we know the ship's orientation)
        let sortedClusters = clusters.sorted { $0.count > $1.count }

        for cluster in sortedClusters {
            if cluster.count >= 2 {
                // Try to continue this line
                if let lineShot = continueHitLine(hits: cluster, unshotCoords: unshotCoords, boardSize: boardSize) {
                    return lineShot
                }
            }
        }

        // For single-hit clusters or when line extension fails, try adjacent cells
        for cluster in sortedClusters {
            for hit in cluster {
                let neighbors = hit.orthogonalNeighbors(boardSize: boardSize).filter { unshotCoords.contains($0) }
                if let target = neighbors.randomElement() {
                    return target
                }
            }
        }

        // Fallback to any unshot
        return unshotCoords.randomElement() ?? Coordinate(row: 0, col: 0)
    }

    /// Groups hits into clusters of adjacent coordinates (likely from same ship)
    private func groupHitsIntoClusters(_ hits: [Coordinate], boardSize: Int) -> [[Coordinate]] {
        guard !hits.isEmpty else { return [] }

        var remaining = Set(hits)
        var clusters: [[Coordinate]] = []

        while !remaining.isEmpty {
            var cluster: [Coordinate] = []
            var toProcess: [Coordinate] = [remaining.removeFirst()]

            while !toProcess.isEmpty {
                let current = toProcess.removeFirst()
                cluster.append(current)

                // Find adjacent hits
                for neighbor in current.orthogonalNeighbors(boardSize: boardSize) {
                    if remaining.contains(neighbor) {
                        remaining.remove(neighbor)
                        toProcess.append(neighbor)
                    }
                }
            }

            clusters.append(cluster)
        }

        return clusters
    }

    private func continueHitLine(hits: [Coordinate], unshotCoords: Set<Coordinate>, boardSize: Int) -> Coordinate? {
        // Check if hits form a horizontal line (all same row)
        let sortedByCol = hits.sorted { $0.col < $1.col }
        if sortedByCol.allSatisfy({ $0.row == sortedByCol[0].row }) {
            let row = sortedByCol[0].row

            // First check for gaps in the line - these are high priority targets
            for i in 0..<(sortedByCol.count - 1) {
                let currentCol = sortedByCol[i].col
                let nextCol = sortedByCol[i + 1].col
                // If there's a gap, target the first cell in the gap
                if nextCol - currentCol > 1 {
                    let gapCoord = Coordinate(row: row, col: currentCol + 1)
                    if unshotCoords.contains(gapCoord) {
                        return gapCoord
                    }
                }
            }

            // No gaps - try extending at both ends
            // Try extending left
            let leftCol = sortedByCol.first!.col - 1
            if leftCol >= 0 {
                let leftCoord = Coordinate(row: row, col: leftCol)
                if unshotCoords.contains(leftCoord) {
                    return leftCoord
                }
            }
            // Try extending right
            let rightCol = sortedByCol.last!.col + 1
            if rightCol < boardSize {
                let rightCoord = Coordinate(row: row, col: rightCol)
                if unshotCoords.contains(rightCoord) {
                    return rightCoord
                }
            }
        }

        // Check if hits form a vertical line (all same column)
        let sortedByRow = hits.sorted { $0.row < $1.row }
        if sortedByRow.allSatisfy({ $0.col == sortedByRow[0].col }) {
            let col = sortedByRow[0].col

            // First check for gaps in the line
            for i in 0..<(sortedByRow.count - 1) {
                let currentRow = sortedByRow[i].row
                let nextRow = sortedByRow[i + 1].row
                if nextRow - currentRow > 1 {
                    let gapCoord = Coordinate(row: currentRow + 1, col: col)
                    if unshotCoords.contains(gapCoord) {
                        return gapCoord
                    }
                }
            }

            // No gaps - try extending at both ends
            // Try extending up
            let upRow = sortedByRow.first!.row - 1
            if upRow >= 0 {
                let upCoord = Coordinate(row: upRow, col: col)
                if unshotCoords.contains(upCoord) {
                    return upCoord
                }
            }
            // Try extending down
            let downRow = sortedByRow.last!.row + 1
            if downRow < boardSize {
                let downCoord = Coordinate(row: downRow, col: col)
                if unshotCoords.contains(downCoord) {
                    return downCoord
                }
            }
        }

        return nil
    }

    // MARK: - Hunt Mode

    private func selectCheckerboardShot(unshotCoords: Set<Coordinate>) -> Coordinate {
        // Prefer checkerboard pattern (parity hunting) for efficiency
        let parityCoords = unshotCoords.filter { ($0.row + $0.col) % 2 == 0 }

        if !parityCoords.isEmpty {
            return parityCoords.randomElement()!
        }

        return unshotCoords.randomElement() ?? Coordinate(row: 0, col: 0)
    }

    private func selectProbabilityBasedShot(board: Board, unshotCoords: Set<Coordinate>, boardSize: Int) -> Coordinate {
        // Calculate probability density based on where ships could fit
        var density: [Coordinate: Int] = [:]

        for coord in unshotCoords {
            density[coord] = 0
        }

        // For each remaining ship size, count how many ways it could be placed
        // touching each unshot coordinate
        let remainingShipSizes = getRemainingShipSizes(board: board)

        for size in remainingShipSizes {
            for coord in unshotCoords {
                // Check horizontal placement starting at various positions
                for startCol in max(0, coord.col - size + 1)...min(boardSize - size, coord.col) {
                    if canPlaceShip(row: coord.row, col: startCol, size: size, horizontal: true, board: board, boardSize: boardSize) {
                        // This placement would cover `coord`
                        density[coord, default: 0] += 1
                    }
                }

                // Check vertical placement
                for startRow in max(0, coord.row - size + 1)...min(boardSize - size, coord.row) {
                    if canPlaceShip(row: startRow, col: coord.col, size: size, horizontal: false, board: board, boardSize: boardSize) {
                        density[coord, default: 0] += 1
                    }
                }
            }
        }

        // Select coordinate with highest density (with some randomness among top candidates)
        let sorted = density.sorted { $0.value > $1.value }
        let maxDensity = sorted.first?.value ?? 0
        let topCandidates = sorted.filter { $0.value >= maxDensity - 2 }.map { $0.key }

        return topCandidates.randomElement() ?? unshotCoords.randomElement() ?? Coordinate(row: 0, col: 0)
    }

    private func canPlaceShip(row: Int, col: Int, size: Int, horizontal: Bool, board: Board, boardSize: Int) -> Bool {
        for i in 0..<size {
            let checkRow = horizontal ? row : row + i
            let checkCol = horizontal ? col + i : col

            guard checkRow >= 0, checkRow < boardSize, checkCol >= 0, checkCol < boardSize else {
                return false
            }

            let coord = Coordinate(row: checkRow, col: checkCol)

            // Can't place through a miss (we know no ship is there)
            if board.hasBeenShot(at: coord) && !board.hasShip(at: coord) {
                return false
            }
        }
        return true
    }

    private func getRemainingShipSizes(board: Board) -> [Int] {
        // Get sizes of ships not yet sunk
        return board.ships.filter { !$0.isSunk }.map { $0.size }
    }

    // MARK: - Helpers

    private func getUnshotCoordinates(board: Board, boardSize: Int) -> Set<Coordinate> {
        var unshot = Set<Coordinate>()
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                let coord = Coordinate(row: row, col: col)
                if !board.hasBeenShot(at: coord) {
                    unshot.insert(coord)
                }
            }
        }
        return unshot
    }

    private func getActiveHits(board: Board, boardSize: Int) -> [Coordinate] {
        // Find coordinates that have been hit but the ship isn't sunk yet
        var activeHits: [Coordinate] = []

        for row in 0..<boardSize {
            for col in 0..<boardSize {
                let coord = Coordinate(row: row, col: col)
                if board.hasBeenShot(at: coord) {
                    if let ship = board.ship(at: coord), !ship.isSunk {
                        activeHits.append(coord)
                    }
                }
            }
        }

        return activeHits
    }
}
