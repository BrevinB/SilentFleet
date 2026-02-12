// GameEngine - Public API
// This file re-exports all public types for easy access

// MARK: - Models
// All models are defined in the Models/ directory and are automatically
// available through the module's public interface.

// Key Types:
// - Coordinate: Grid position (row, col)
// - Orientation: Ship orientation (horizontal/vertical)
// - Ship: Ship with position, size, and hit tracking
// - Board: 10x10 grid with ships and shot history
// - Player: Player state including board and power-ups
// - GameState: Complete serializable game state

// Configuration:
// - GameMode: Ranked vs Casual
// - AIDifficulty: Easy, Medium, Hard
// - BoardSplit: Top/Bottom or Left/Right for ranked constraints

// Power-ups:
// - PowerUpType: Sonar Ping, Row Scan
// - PowerUpAction: Specific power-up use with parameters
// - PowerUpKit: Player's available power-ups
// - PowerUpResult: Result of using a power-up

// Turn System:
// - TurnAction: Power-up (optional) + Shot
// - TurnResult: Complete turn outcome
// - ShotResult: Hit/Miss/Sunk

// Validation:
// - PlacementValidator: Ship placement rule validation
// - PlacementError: Placement validation errors

// Engine:
// - TurnEngine: Turn processing logic
// - TurnError: Turn validation errors

// AI:
// - AIPlacementStrategy: Protocol for AI ship placement
// - AIPlacementFactory: Factory for creating AI strategies
