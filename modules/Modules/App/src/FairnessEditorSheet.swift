import CRDesign
import CRModel
import SwiftUI

struct FairnessEditorSheet: View {
    @Bindable var viewModel: RotationOutputViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.crBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        Text("Set the minimum playing time per skill tier. These thresholds are used to flag rotation violations for this game.")
                            .font(.caption)
                            .foregroundStyle(Color.crTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 0) {
                            ForEach(Array(Tier.allCases.enumerated()), id: \.element) { index, tier in
                                tierRow(tier)
                                if index < Tier.allCases.count - 1 {
                                    divider
                                }
                            }
                            divider
                            Toggle("Goalie time counts as field time", isOn: $viewModel.editedFairnessTargets.goalieTimeCountsAsFieldTime)
                                .foregroundStyle(Color.crTextPrimary)
                                .tint(Color.crAccent)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                        }
                        .crSurfaceCard()
                    }
                    .padding()
                }
            }
            .navigationTitle("Playing Time Targets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.crSurface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.showFairnessEditor = false }
                        .foregroundStyle(Color.crTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { viewModel.saveFairnessTargets() }
                        .foregroundStyle(Color.crAccent)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func tierRow(_ tier: Tier) -> some View {
        HStack {
            Text(tier.rawValue)
                .foregroundStyle(Color.crTextPrimary)
            Spacer()
            Text("\(viewModel.editedFairnessTargets.minutes(for: tier)) min")
                .font(.body.monospacedDigit())
                .foregroundStyle(Color.crTextPrimary)
                .frame(minWidth: 52, alignment: .trailing)
            Stepper("", value: minutesBinding(for: tier), in: 0 ... 60)
                .tint(Color.crAccent)
                .labelsHidden()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }

    private func minutesBinding(for tier: Tier) -> Binding<Int> {
        Binding(
            get: { viewModel.editedFairnessTargets.minutes(for: tier) },
            set: { viewModel.editedFairnessTargets.setMinutes($0, for: tier) }
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
            .padding(.horizontal, 16)
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
    FairnessEditorSheet(viewModel: vm)
}
