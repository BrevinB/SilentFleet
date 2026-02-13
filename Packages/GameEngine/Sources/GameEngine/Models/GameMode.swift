import Foundation

/// Game mode determining rules and power-up limits
public enum GameMode: String, Codable, CaseIterable, Sendable {
    case ranked
    case casual
}

/// AI difficulty level for solo play
public enum AIDifficulty: String, Codable, CaseIterable, Sendable {
    case easy
    case medium
    case hard
}

/// Board split orientation for ranked placement constraint
/// At least one ship of size >= 3 must be in each half
public enum BoardSplit: String, Codable, CaseIterable, Sendable {
    case topBottom   // Top half: rows 0..<half, Bottom half: rows half..<size
    case leftRight   // Left half: cols 0..<half, Right half: cols half..<size

    /// Returns true if the coordinate is in the first half (top or left) for default 10x10
    public func isInFirstHalf(_ coord: Coordinate) -> Bool {
        isInFirstHalf(coord, boardSize: Board.size)
    }

    /// Returns true if the coordinate is in the first half (top or left) for given board size
    public func isInFirstHalf(_ coord: Coordinate, boardSize: Int) -> Bool {
        let half = boardSize / 2
        switch self {
        case .topBottom:
            return coord.row < half
        case .leftRight:
            return coord.col < half
        }
    }

    /// Returns true if the coordinate is in the second half (bottom or right) for default 10x10
    public func isInSecondHalf(_ coord: Coordinate) -> Bool {
        !isInFirstHalf(coord)
    }

    /// Returns true if the coordinate is in the second half (bottom or right) for given board size
    public func isInSecondHalf(_ coord: Coordinate, boardSize: Int) -> Bool {
        !isInFirstHalf(coord, boardSize: boardSize)
    }

    public var firstHalfName: String {
        switch self {
        case .topBottom: return "top"
        case .leftRight: return "left"
        }
    }

    public var secondHalfName: String {
        switch self {
        case .topBottom: return "bottom"
        case .leftRight: return "right"
        }
    }
}
