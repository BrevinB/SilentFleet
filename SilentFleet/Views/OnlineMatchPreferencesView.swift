import SwiftUI
import GameEngine

/// Pre-matchmaker preferences screen. The values chosen here become the
/// match's persistent configuration once the first turn is committed.
struct OnlineMatchPreferencesView: View {
    @Binding var preferences: OnlineMatchPreferences
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Match Settings")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.top, 12)

                modeSection
                gridSection
                if preferences.mode == .ranked {
                    splitSection
                }

                Button {
                    HapticManager.shared.buttonTap()
                    onContinue()
                } label: {
                    Label("Find a Match", systemImage: "magnifyingglass")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
            .padding(.bottom, 24)
        }
        .onChange(of: preferences.mode) { _, mode in
            preferences.split = mode == .ranked ? (preferences.split ?? .topBottom) : nil
        }
    }

    private var modeSection: some View {
        sectionCard(title: "Mode") {
            VStack(spacing: 10) {
                modeOption(.casual, title: "Casual", subtitle: "Relaxed rules. Player 1 fires first.")
                modeOption(.ranked, title: "Ranked", subtitle: "Split-board placement + coin flip for first turn.")
            }
        }
    }

    private func modeOption(_ mode: GameMode, title: String, subtitle: String) -> some View {
        let isSelected = preferences.mode == mode
        return Button {
            HapticManager.shared.buttonTap()
            preferences.mode = mode
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).foregroundStyle(.white)
                    Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .green : .white.opacity(0.4))
                    .font(.title3)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(isSelected ? 0.18 : 0.08))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? .green : .clear, lineWidth: 2))
            )
        }
        .buttonStyle(.plain)
    }

    private var gridSection: some View {
        sectionCard(title: "Grid Size") {
            HStack(spacing: 8) {
                ForEach(GridSize.allCases, id: \.self) { size in
                    gridOption(size)
                }
            }
        }
    }

    private func gridOption(_ size: GridSize) -> some View {
        let isSelected = preferences.gridSize == size
        return Button {
            HapticManager.shared.buttonTap()
            preferences.gridSize = size
        } label: {
            VStack(spacing: 4) {
                Text(size.displayName).font(.headline).foregroundStyle(.white)
                Text(size.gridDescription).font(.caption2).foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.white.opacity(isSelected ? 0.18 : 0.08))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? .green : .clear, lineWidth: 2))
            )
        }
        .buttonStyle(.plain)
    }

    private var splitSection: some View {
        sectionCard(title: "Board Split") {
            HStack(spacing: 12) {
                splitOption(.topBottom, title: "Top / Bottom", icon: "rectangle.split.1x2")
                splitOption(.leftRight, title: "Left / Right", icon: "rectangle.split.2x1")
            }
        }
    }

    private func splitOption(_ split: BoardSplit, title: String, icon: String) -> some View {
        let isSelected = preferences.split == split
        return Button {
            HapticManager.shared.buttonTap()
            preferences.split = split
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.title2).foregroundStyle(isSelected ? .green : .white.opacity(0.6))
                Text(title).font(.caption.weight(.medium)).foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.white.opacity(isSelected ? 0.18 : 0.08))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? .green : .clear, lineWidth: 2))
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.6))
            content()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.07)))
        .padding(.horizontal, 16)
    }
}
