import CRDesign
import CRModel
import SwiftUI

struct GameOptionsView: View {
    @Bindable var viewModel: GameSetupViewModel
    private let players: [Player]

    init(viewModel: GameSetupViewModel, players: [Player]) {
        self.viewModel = viewModel
        self.players = players
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                formatSection
                rotationStyleSection
                fairnessSection
                prioritiesSection
            }
            .padding()
        }
    }

    @ViewBuilder
    private var formatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Format")
                .font(.headline)
                .foregroundStyle(Color.crTextPrimary)

            VStack(spacing: 0) {
                Stepper("Quarters: \(viewModel.format.quarters)", value: $viewModel.format.quarters, in: 1...8)
                    .foregroundStyle(Color.crTextPrimary)
                    .padding(.vertical, 4)
                Divider().background(Color.crTextSecondary.opacity(0.2))
                Stepper(
                    "Quarter Length: \(viewModel.format.quarterLengthMinutes) min",
                    value: $viewModel.format.quarterLengthMinutes,
                    in: 1...60
                )
                .foregroundStyle(Color.crTextPrimary)
                .padding(.vertical, 4)
                Divider().background(Color.crTextSecondary.opacity(0.2))
                Stepper(
                    "Players Per Side: \(viewModel.format.playersPerSide)",
                    value: $viewModel.format.playersPerSide,
                    in: 1...15
                )
                .foregroundStyle(Color.crTextPrimary)
                .padding(.vertical, 4)
                Divider().background(Color.crTextSecondary.opacity(0.2))
                Toggle("Mid-Quarter Subs", isOn: $viewModel.format.midQuarterSubsEnabled)
                    .foregroundStyle(Color.crTextPrimary)
                    .padding(.vertical, 4)
            }
            .padding(.horizontal)
            .crSurfaceCard()
        }
    }

    @ViewBuilder
    private var rotationStyleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rotation Style")
                .font(.headline)
                .foregroundStyle(Color.crTextPrimary)

            VStack(spacing: 12) {
                Picker("Rotation Style", selection: rotationStyleKindBinding) {
                    Text("By Quarter").tag(RotationStyleKind.byQuarter)
                    Text("By Time Interval").tag(RotationStyleKind.byTimeInterval)
                }
                .pickerStyle(.segmented)

                if case .byTimeInterval(let minutes) = viewModel.rotationStyle {
                    VStack(spacing: 8) {
                        Stepper(
                            "Interval: \(minutes) min",
                            value: Binding(
                                get: { minutes },
                                set: { viewModel.rotationStyle = .byTimeInterval(intervalMinutes: $0) }
                            ),
                            in: 1...max(1, viewModel.format.quarterLengthMinutes)
                        )
                        .foregroundStyle(Color.crTextPrimary)

                        let subsPerQuarter = max(1, viewModel.format.quarterLengthMinutes / minutes)
                        let totalRotations = viewModel.format.quarters * subsPerQuarter
                        Text(
                            "\(subsPerQuarter) sub\(subsPerQuarter == 1 ? "" : "s") per quarter — \(totalRotations) rotations total"
                        )
                        .font(.caption)
                        .foregroundStyle(Color.crTextSecondary)
                    }
                }
            }
            .padding()
            .crSurfaceCard()
        }
    }

    @ViewBuilder
    private var fairnessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Minimum Playing Time")
                .font(.headline)
                .foregroundStyle(Color.crTextPrimary)

            VStack(spacing: 0) {
                ForEach(Tier.allCases, id: \.self) { tier in
                    Stepper(
                        "\(tier.rawValue): \(viewModel.fairnessTargets.minutes(for: tier)) min",
                        value: minutesBinding(for: tier),
                        in: 0...60
                    )
                    .foregroundStyle(Color.crTextPrimary)
                    .padding(.vertical, 4)
                    if tier != Tier.allCases.last {
                        Divider().background(Color.crTextSecondary.opacity(0.2))
                    }
                }
                Divider().background(Color.crTextSecondary.opacity(0.2))
                Toggle("Goalie time counts as field time", isOn: $viewModel.fairnessTargets.goalieTimeCountsAsFieldTime)
                    .foregroundStyle(Color.crTextPrimary)
                    .padding(.vertical, 4)
            }
            .padding(.horizontal)
            .crSurfaceCard()
        }
    }

    @ViewBuilder
    private var prioritiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("Priorities")
                    .font(.headline)
                    .foregroundStyle(Color.crTextPrimary)
                Text("Optional")
                    .font(.caption)
                    .foregroundStyle(Color.crTextSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.crTextSecondary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Competitiveness")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.crTextSecondary)
                    Picker("Mode", selection: $viewModel.competitivenessMode) {
                        ForEach(CompetitivenessMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if !players.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Player Boosts")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.crTextSecondary)
                        Text("Boosted players get elevated playing time for this game.")
                            .font(.caption)
                            .foregroundStyle(Color.crTextSecondary)
                        ForEach(players) { player in
                            let isBoosted = viewModel.boostedPlayerIDs.contains(player.id)
                            Button {
                                if isBoosted {
                                    viewModel.boostedPlayerIDs.removeAll { $0 == player.id }
                                } else {
                                    viewModel.boostedPlayerIDs.append(player.id)
                                }
                            } label: {
                                HStack {
                                    Text("#\(player.jerseyNumber) \(player.name)")
                                        .foregroundStyle(Color.crTextPrimary)
                                    Spacer()
                                    Image(systemName: isBoosted ? "bolt.fill" : "bolt")
                                        .foregroundStyle(isBoosted ? Color.crAccent : Color.crTextSecondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .padding()
            .crSurfaceCard()
        }
    }

    private var rotationStyleKindBinding: Binding<RotationStyleKind> {
        Binding(
            get: {
                if case .byTimeInterval = viewModel.rotationStyle { return .byTimeInterval }
                return .byQuarter
            },
            set: { kind in
                switch kind {
                case .byQuarter:
                    viewModel.rotationStyle = .byQuarter
                case .byTimeInterval:
                    viewModel.rotationStyle = .byTimeInterval(intervalMinutes: 5)
                }
            }
        )
    }

    private func minutesBinding(for tier: Tier) -> Binding<Int> {
        Binding(
            get: { viewModel.fairnessTargets.minutes(for: tier) },
            set: { viewModel.fairnessTargets.setMinutes($0, for: tier) }
        )
    }
}

private enum RotationStyleKind: Hashable {
    case byQuarter
    case byTimeInterval
}

#Preview {
    GameOptionsView(
        viewModel: GameSetupViewModel(formatDefaults: .default, players: []),
        players: []
    )
    .background(Color.crBackground)
}
