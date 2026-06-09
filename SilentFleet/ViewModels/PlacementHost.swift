import Foundation
import GameEngine

/// Surface required by `PlacementView` so it can be used by either the
/// single-player `GameViewModel` or the online `OnlineGameViewModel`.
@MainActor
protocol PlacementHost: ObservableObject {
    var placedShips: [Ship] { get set }
    var selectedShip: Ship? { get set }
    var placementOrientation: Orientation { get set }
    var remainingFleetSizes: [Int] { get set }
    var errorMessage: String? { get set }

    var currentBoardSize: Int { get }
    var gameMode: GameMode { get }
    var boardSplit: BoardSplit? { get }
    var gridSize: GridSize { get }

    func selectShipSize(_ size: Int)
    func toggleOrientation()
    func canPlaceShip(at coordinate: Coordinate) -> Bool
    func placeShip(at coordinate: Coordinate) -> Bool
    func removeShip(_ ship: Ship)
    func autoPopulateShips()
    /// Returns true if the host accepted placement and the view should
    /// proceed to the next phase (or end its own task in the online case).
    func commitPlacement() async -> Bool
}
