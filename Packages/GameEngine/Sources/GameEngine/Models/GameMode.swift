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
    case topBottom   // Top half: rows 0-4, Bottom half: rows 5-9
    case leftRight   // Left half: cols 0-4, Right half: cols 5-9

    /// Returns true if the coordinate is in the first half (top or left)
    public func isInFirstHalf(_ coord: Coordinate) -> Bool {
        switch self {
        case .topBottom:
            return coord.row < 5
        case .leftRight:
            return coord.col < 5
        }
    }

    /// Returns true if the coordinate is in the second half (bottom or right)
    public func isInSecondHalf(_ coord: Coordinate) -> Bool {
        !isInFirstHalf(coord)
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
