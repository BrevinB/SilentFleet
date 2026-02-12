import Foundation

/// Represents a position on the 10x10 game board
public struct Coordinate: Codable, Hashable, Equatable, Sendable {
    public let row: Int
    public let col: Int

    public init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }

    /// Check if coordinate is within valid board bounds (0-9)
    public var isValid: Bool {
        row >= 0 && row < Board.size && col >= 0 && col < Board.size
    }

    /// Returns all orthogonally adjacent coordinates (up, down, left, right)
    public var orthogonalNeighbors: [Coordinate] {
        [
            Coordinate(row: row - 1, col: col),
            Coordinate(row: row + 1, col: col),
            Coordinate(row: row, col: col - 1),
            Coordinate(row: row, col: col + 1)
        ].filter { $0.isValid }
    }

    /// Returns all diagonally adjacent coordinates
    public var diagonalNeighbors: [Coordinate] {
        [
            Coordinate(row: row - 1, col: col - 1),
            Coordinate(row: row - 1, col: col + 1),
            Coordinate(row: row + 1, col: col - 1),
            Coordinate(row: row + 1, col: col + 1)
        ].filter { $0.isValid }
    }

    /// Returns all adjacent coordinates (orthogonal + diagonal)
    public var allNeighbors: [Coordinate] {
        orthogonalNeighbors + diagonalNeighbors
    }
}

extension Coordinate: CustomStringConvertible {
    public var description: String {
        "(\(row), \(col))"
    }
}
