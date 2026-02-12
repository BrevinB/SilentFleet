# Silent Fleet - Battleship Game

An iOS Battleship game MVP built with SwiftUI and a pure Swift game engine.

## Project Structure

```
SilentFleet/
├── Packages/
│   └── GameEngine/              # Pure Swift game logic package
│       ├── Sources/GameEngine/
│       │   ├── Models/          # Core data types (Codable)
│       │   ├── Validation/      # Placement rules validator
│       │   ├── Engine/          # Turn processing logic
│       │   └── AI/              # AI placement strategies
│       └── Tests/GameEngineTests/
├── SilentFleet/                 # SwiftUI iOS app
│   ├── Views/                   # UI components
│   ├── ViewModels/              # MVVM view models
│   └── Services/                # Persistence layer
└── SilentFleet.xcodeproj
```

## Build & Run

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ simulator or device
- macOS 14.0+ (for development)

### Steps

1. **Clone the repository**
   ```bash
   git clone <repo-url>
   cd SilentFleet
   ```

2. **Add the local Swift Package to Xcode**
   - Open `SilentFleet.xcodeproj` in Xcode
   - File → Add Package Dependencies
   - Click "Add Local..."
   - Select the `Packages/GameEngine` folder
   - Add to the SilentFleet target

3. **Build and Run**
   - Select an iOS simulator or device
   - Press ⌘+R to build and run

### Running Tests

```bash
cd Packages/GameEngine
swift test
```

Or in Xcode: Product → Test (⌘+U)

## Architecture Overview

### GameEngine Package

A pure, deterministic Swift package with no UI dependencies. All game state is `Codable` for serialization.

**Key Components:**

| Component | Description |
|-----------|-------------|
| `Coordinate` | Grid position (row, col) on 10x10 board |
| `Ship` | Ship with size, position, orientation, hit tracking |
| `Board` | 10x10 grid with ships and shot history |
| `GameState` | Complete serializable game state |
| `PlacementValidator` | Enforces placement rules |
| `TurnEngine` | Processes turns, handles power-ups |
| `AIPlacementStrategy` | Protocol for AI ship placement |

**AI Placement Strategies:**

| Difficulty | Strategy |
|------------|----------|
| Easy | Random valid placement |
| Medium | Heat avoidance (avoids common attack patterns) |
| Hard | Inverted heatmap with multiple profiles |

**AI Targeting Strategies:**

| Difficulty | Strategy |
|------------|----------|
| Easy | Random targeting |
| Medium | Hunt/Target with 70% accuracy, checkerboard pattern |
| Hard | Hunt/Target with 90% accuracy + probability density |

### Game Rules

**Board & Fleet:**
- 10x10 grid
- Fleet sizes: [5, 4, 3, 3, 2, 2, 1, 1, 1] (23 tiles total)
- Ships cannot touch (no orthogonal or diagonal adjacency)

**Ranked Mode Constraints:**
- At least one ship of size ≥3 must have tiles in each half of the board
- Player chooses split orientation: Top/Bottom or Left/Right
- Coin flip determines first player
- First player cannot use power-ups on turn 1
- Ship sizes hidden when sunk

**Power-ups:**

| Power-up | Effect | Ranked Limit | Casual Limit |
|----------|--------|--------------|--------------|
| Sonar Ping | 3x3 area presence check (YES/NO) | 1 | 2 |
| Row Scan | Row presence check (YES/NO) | 1 | 2 |

- Must be used before shot
- Max 1 power-up per turn

**Turn Flow:**
1. (Optional) Use one power-up
2. Fire exactly one shot
3. No extra turn on hit
4. Turn passes to opponent

### SwiftUI App

**Views:**
- `MainMenuView` - Game entry point
- `GameSetupView` - Mode/difficulty selection
- `PlacementView` - Ship placement phase
- `MatchPlayView` - Active gameplay
- `MatchSummaryView` - Game results

**MatchStore Protocol:**
Abstraction for game persistence, designed for future Game Center integration.

```swift
public protocol MatchStore {
    func save(_ state: GameState) async throws
    func load(id: UUID) async throws -> GameState?
    func loadAll() async throws -> [GameState]
    func delete(id: UUID) async throws
}
```

## Completed Features (V1)

### AI Targeting
- [x] Smart AI shot selection with hunt/target mode
- [x] Checkerboard pattern hunting for efficiency
- [x] Line continuation after multiple hits
- [x] Probability density targeting (hard mode)
- [x] Difficulty-based targeting accuracy

### Polish
- [x] Hit/miss/sunk animations with ripple effects
- [x] Haptic feedback for all game events
- [x] AI thinking overlay with animated indicator
- [x] Save/resume in-progress games
- [x] Improved ship placement UX with preview highlighting

## TODO: Next Milestones

### Phase 3: Game Center Integration
- [ ] Async multiplayer matches via Game Center
- [ ] Turn-based notifications
- [ ] Leaderboards
- [ ] Achievements

### Phase 4: Cosmetics & Monetization
- [ ] Ship skins
- [ ] Board themes
- [ ] Coin system for casual power-up purchases
- [ ] In-app purchases

### Phase 5: Additional Polish
- [ ] Sound effects
- [ ] Tutorial/onboarding
- [ ] Settings screen

## Test Coverage

117 unit tests covering:
- Coordinate validation and neighbors
- Ship placement and hit tracking
- Placement validator (bounds, overlap, adjacency, ranked constraints)
- Turn engine (shots, power-ups, restrictions, win conditions)
- Power-up kit management
- AI placement strategies (all difficulties)
- AI targeting strategies (hunt/target mode, probability density)
- Game state serialization

## License

MIT
