import Foundation

/// Represents a complete turn action: optional power-up followed by exactly one shot
public struct TurnAction: Codable, Equatable, Sendable {
    /// Optional power-up to use before shooting (max 1 per turn)
    public let powerUp: PowerUpAction?

    /// Required: coordinate to shoot at
    public let shot: Coordinate

    public init(powerUp: PowerUpAction? = nil, shot: Coordinate) {
        self.powerUp = powerUp
        self.shot = shot
    }

    /// Create a turn with only a shot (no power-up)
    public static func shotOnly(_ coordinate: Coordinate) -> TurnAction {
        TurnAction(shot: coordinate)
    }

    /// Create a turn with sonar ping and shot
    public static func withSonar(center: Coordinate, shot: Coordinate) -> TurnAction {
        TurnAction(powerUp: .sonarPing(center: center), shot: shot)
    }

    /// Create a turn with row scan and shot
    public static func withRowScan(row: Int, shot: Coordinate) -> TurnAction {
        TurnAction(powerUp: .rowScan(row: row), shot: shot)
    }
}
