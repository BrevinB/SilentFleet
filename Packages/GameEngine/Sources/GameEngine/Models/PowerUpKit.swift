import Foundation

/// Tracks available power-ups for a player during a match
public struct PowerUpKit: Codable, Equatable, Sendable {
    public var sonarPingRemaining: Int
    public var rowScanRemaining: Int

    public init(sonarPingRemaining: Int, rowScanRemaining: Int) {
        self.sonarPingRemaining = sonarPingRemaining
        self.rowScanRemaining = rowScanRemaining
    }

    /// Creates a power-up kit for the specified game mode
    public static func forMode(_ mode: GameMode) -> PowerUpKit {
        switch mode {
        case .ranked:
            return rankedKit
        case .casual:
            return casualMaxKit
        }
    }

    /// Ranked mode: exactly 1 of each power-up per player per match
    public static let rankedKit = PowerUpKit(sonarPingRemaining: 1, rowScanRemaining: 1)

    /// Casual mode: maximum 2 of each (monetizable later, but hard cap enforced)
    public static let casualMaxKit = PowerUpKit(sonarPingRemaining: 2, rowScanRemaining: 2)

    /// Check if a power-up type is available
    public func isAvailable(_ type: PowerUpType) -> Bool {
        switch type {
        case .sonarPing:
            return sonarPingRemaining > 0
        case .rowScan:
            return rowScanRemaining > 0
        }
    }

    /// Consume one use of a power-up type
    /// - Returns: true if successful, false if none remaining
    @discardableResult
    public mutating func consume(_ type: PowerUpType) -> Bool {
        switch type {
        case .sonarPing:
            guard sonarPingRemaining > 0 else { return false }
            sonarPingRemaining -= 1
            return true
        case .rowScan:
            guard rowScanRemaining > 0 else { return false }
            rowScanRemaining -= 1
            return true
        }
    }

    /// Total power-ups remaining
    public var totalRemaining: Int {
        sonarPingRemaining + rowScanRemaining
    }

    /// List of available power-up types
    public var availableTypes: [PowerUpType] {
        PowerUpType.allCases.filter { isAvailable($0) }
    }
}
