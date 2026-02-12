import SwiftUI
import GameEngine

struct GameContainerView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if viewModel.isPlacementPhase {
                PlacementView(viewModel: viewModel)
            } else if viewModel.isGameOver {
                MatchSummaryView(viewModel: viewModel) {
                    dismiss()
                }
            } else {
                MatchPlayView(viewModel: viewModel)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Menu")
                    }
                }
            }
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.dismissError() } }
        )) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

#Preview {
    NavigationStack {
        GameContainerView(viewModel: {
            let vm = GameViewModel()
            vm.startNewGame(mode: .casual, difficulty: .easy)
            return vm
        }())
    }
}
