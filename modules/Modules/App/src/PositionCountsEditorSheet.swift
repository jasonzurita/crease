import CRDesign
import CRModel
import SwiftUI

struct PositionCountsEditorSheet: View {
    @Bindable var viewModel: RotationOutputViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.crBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        Text("Set how many players line up at each position. The total (including 1 goalie) should equal players per side.")
                            .font(.caption)
                            .foregroundStyle(Color.crTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 0) {
                            countRow("Attack", binding: attackBinding)
                            divider
                            countRow("Midfield", binding: midfieldBinding)
                            divider
                            countRow("Defense", binding: defenseBinding)
                            divider
                            totalRow
                        }
                        .crSurfaceCard()
                    }
                    .padding()
                }
            }
            .navigationTitle("Field Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.crSurface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.showPositionCountsEditor = false }
                        .foregroundStyle(Color.crTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save & Regenerate") { viewModel.savePositionCounts() }
                        .foregroundStyle(Color.crAccent)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func countRow(_ label: String, binding: Binding<Int>) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(Color.crTextPrimary)
            Spacer()
            Text("\(binding.wrappedValue)")
                .font(.body.monospacedDigit())
                .foregroundStyle(Color.crTextPrimary)
                .frame(minWidth: 52, alignment: .trailing)
            Stepper("", value: binding, in: 0 ... 10)
                .tint(Color.crAccent)
                .labelsHidden()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }

    private var totalRow: some View {
        let total = (viewModel.editedPositionCounts?.fieldTotal ?? 0) + 1
        let playersPerSide = viewModel.game.format.playersPerSide
        let isValid = total == playersPerSide

        return HStack {
            Text("Total on field")
                .foregroundStyle(Color.crTextSecondary)
                .font(.subheadline)
            Spacer()
            Text("\(total) of \(playersPerSide)")
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(isValid ? Color.crSuccess : Color.crDanger)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
            .padding(.horizontal, 16)
    }

    private var attackBinding: Binding<Int> {
        Binding(
            get: { viewModel.editedPositionCounts?.attack ?? 0 },
            set: {
                var counts = viewModel.editedPositionCounts ?? PositionCounts(attack: 0, midfield: 0, defense: 0)
                counts.attack = $0
                viewModel.editedPositionCounts = counts
            }
        )
    }

    private var midfieldBinding: Binding<Int> {
        Binding(
            get: { viewModel.editedPositionCounts?.midfield ?? 0 },
            set: {
                var counts = viewModel.editedPositionCounts ?? PositionCounts(attack: 0, midfield: 0, defense: 0)
                counts.midfield = $0
                viewModel.editedPositionCounts = counts
            }
        )
    }

    private var defenseBinding: Binding<Int> {
        Binding(
            get: { viewModel.editedPositionCounts?.defense ?? 0 },
            set: {
                var counts = viewModel.editedPositionCounts ?? PositionCounts(attack: 0, midfield: 0, defense: 0)
                counts.defense = $0
                viewModel.editedPositionCounts = counts
            }
        )
    }
}

#Preview {
    let store = SeasonStore(fileManagerClient: .mock(), userDefaultsClient: .noop)
    let vm = RotationOutputViewModel(
        game: Game(
            id: UUID(),
            opponent: "Hawks",
            date: Date(),
            isHome: true,
            status: .ready,
            attendance: [],
            format: .default,
            rotationStyle: .byQuarter,
            fairnessTargets: .default,
            competitivenessMode: .balanced,
            boostedPlayerIDs: [],
            createdAt: Date()
        ),
        players: [],
        store: store
    )
    PositionCountsEditorSheet(viewModel: vm)
}
