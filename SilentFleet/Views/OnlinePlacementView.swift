import SwiftUI
import GameEngine

/// Online placement just wires the shared generic `PlacementView` to the
/// online view model so drag-to-place + manual layout work the same as
/// in solo play.
struct OnlinePlacementView: View {
    @ObservedObject var viewModel: OnlineGameViewModel

    var body: some View {
        PlacementView<OnlineGameViewModel>(viewModel: viewModel)
    }
}
