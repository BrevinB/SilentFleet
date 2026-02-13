import Foundation

/// Represents a position on the game board
public struct Coordinate: Codable, Hashable, Equatable, Sendable {
    public let row: Int
    public let col: Int

    public init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }

    /// Check if coordinate is within valid board bounds (default 10x10)
    public var isValid: Bool {
        isValid(forBoardSize: Board.size)
    }

    /// Check if coordinate is within valid board bounds for a given board size
    public func isValid(forBoardSize size: Int) -> Bool {
        row >= 0 && row < size && col >= 0 && col < size
    }

    /// Returns all orthogonally adjacent coordinates (up, down, left, right)
    public var orthogonalNeighbors: [Coordinate] {
        orthogonalNeighbors(boardSize: Board.size)
    }

    /// Returns all orthogonally adjacent coordinates for a given board size
    public func orthogonalNeighbors(boardSize: Int) -> [Coordinate] {
        [
            Coordinate(row: row - 1, col: col),
            Coordinate(row: row + 1, col: col),
            Coordinate(row: row, col: col - 1),
            Coordinate(row: row, col: col + 1)
        ].filter { $0.isValid(forBoardSize: boardSize) }
    }

    /// Returns all diagonally adjacent coordinates
    public var diagonalNeighbors: [Coordinate] {
        diagonalNeighbors(boardSize: Board.size)
    }

    /// Returns all diagonally adjacent coordinates for a given board size
    public func diagonalNeighbors(boardSize: Int) -> [Coordinate] {
        [
            Coordinate(row: row - 1, col: col - 1),
            Coordinate(row: row - 1, col: col + 1),
            Coordinate(row: row + 1, col: col - 1),
            Coordinate(row: row + 1, col: col + 1)
        ].filter { $0.isValid(forBoardSize: boardSize) }
    }

    /// Returns all adjacent coordinates (orthogonal + diagonal)
    public var allNeighbors: [Coordinate] {
        orthogonalNeighbors + diagonalNeighbors
    }

    /// Returns all adjacent coordinates for a given board size
    public func allNeighbors(boardSize: Int) -> [Coordinate] {
        orthogonalNeighbors(boardSize: boardSize) + diagonalNeighbors(boardSize: boardSize)
    }
}

extension Coordinate: CustomStringConvertible {
    public var description: String {
        "(\(row), \(col))"
    }
}
