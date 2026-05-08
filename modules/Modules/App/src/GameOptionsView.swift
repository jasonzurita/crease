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
            VStack(spacing: 24) {
                formatSection
                rotationStyleSection
                fairnessSection
                prioritiesSection
            }
            .padding()
        }
    }

    // MARK: - Format

    private var formatSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Format")
            VStack(spacing: 0) {
                stepperRow("Quarters", value: $viewModel.format.quarters, range: 1 ... 8)
                divider
                stepperRow("Quarter Length", value: $viewModel.format.quarterLengthMinutes, range: 5 ... 20, unit: "min")
                divider
                Toggle("Include Goalie", isOn: $viewModel.format.hasGoalie)
                    .foregroundStyle(Color.crTextPrimary)
                    .tint(Color.crAccent)
                    .padding()
                divider
                stepperRow("Attack", value: attackCountBinding, range: 0 ... 10)
                divider
                stepperRow("Midfield", value: midfieldCountBinding, range: 0 ... 10)
                divider
                stepperRow("Defense", value: defenseCountBinding, range: 0 ... 10)
                divider
                positionTotalRow
            }
            .crSurfaceCard()
        }
    }

    private var positionTotalRow: some View {
        let total = viewModel.format.derivedPlayersPerSide
        return HStack {
            Text("Players on field")
                .foregroundStyle(Color.crTextSecondary)
            Spacer()
            Text("\(total)")
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(Color.crTextPrimary)
        }
        .padding()
    }

    private var attackCountBinding: Binding<Int> {
        Binding(
            get: { viewModel.format.effectivePositionCounts.attack },
            set: {
                var counts = viewModel.format.positionCounts ?? viewModel.format.effectivePositionCounts
                counts.attack = $0
                viewModel.format.positionCounts = counts
            }
        )
    }

    private var midfieldCountBinding: Binding<Int> {
        Binding(
            get: { viewModel.format.effectivePositionCounts.midfield },
            set: {
                var counts = viewModel.format.positionCounts ?? viewModel.format.effectivePositionCounts
                counts.midfield = $0
                viewModel.format.positionCounts = counts
            }
        )
    }

    private var defenseCountBinding: Binding<Int> {
        Binding(
            get: { viewModel.format.effectivePositionCounts.defense },
            set: {
                var counts = viewModel.format.positionCounts ?? viewModel.format.effectivePositionCounts
                counts.defense = $0
                viewModel.format.positionCounts = counts
            }
        )
    }

    // MARK: - Rotation Style

    private var rotationStyleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Rotation Style")
            VStack(spacing: 0) {
                Picker("Rotation Style", selection: rotationStyleKindBinding) {
                    Text("By Quarter").tag(RotationStyleKind.byQuarter)
                    Text("By Time Interval").tag(RotationStyleKind.byTimeInterval)
                }
                .pickerStyle(.segmented)
                .padding()

                if case let .byTimeInterval(minutes) = viewModel.rotationStyle {
                    divider
                    stepperRow(
                        "Interval",
                        value: Binding(
                            get: { minutes },
                            set: { viewModel.rotationStyle = .byTimeInterval(intervalMinutes: $0) }
                        ),
                        range: 1 ... max(1, viewModel.format.quarterLengthMinutes),
                        unit: "min"
                    )
                    let subsPerQuarter = max(1, viewModel.format.quarterLengthMinutes / minutes)
                    let totalRotations = viewModel.format.quarters * subsPerQuarter
                    Text(
                        "\(subsPerQuarter) sub\(subsPerQuarter == 1 ? "" : "s") per quarter — \(totalRotations) rotations total"
                    )
                    .font(.caption)
                    .foregroundStyle(Color.crTextSecondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
            .crSurfaceCard()
        }
    }

    // MARK: - Fairness

    private var fairnessSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Minimum Playing Time")
            VStack(spacing: 0) {
                ForEach(Array(Tier.allCases.enumerated()), id: \.element) { index, tier in
                    if index > 0 { divider }
                    stepperRow(tier.rawValue, value: minutesBinding(for: tier), range: 0 ... 60, unit: "min")
                }
                divider
                Toggle("Goalie time counts as field time", isOn: $viewModel.fairnessTargets.goalieTimeCountsAsFieldTime)
                    .foregroundStyle(Color.crTextPrimary)
                    .tint(Color.crAccent)
                    .padding()
            }
            .crSurfaceCard()
        }
    }

    // MARK: - Priorities

    private var prioritiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                sectionLabel("Priorities")
                Text("Optional")
                    .font(.caption)
                    .foregroundStyle(Color.crTextSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.crTextSecondary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Competitiveness")
                Picker("Mode", selection: $viewModel.competitivenessMode) {
                    ForEach(CompetitivenessMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            if !players.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    sectionLabel("Player Boosts")
                    Text("Boosted players get elevated playing time for this game.")
                        .font(.caption)
                        .foregroundStyle(Color.crTextSecondary)
                        .padding(.horizontal, 4)
                    VStack(spacing: 0) {
                        ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                            if index > 0 { divider }
                            boostRow(player: player)
                        }
                    }
                    .crSurfaceCard()
                }
            }
        }
    }

    private func boostRow(player: Player) -> some View {
        let isBoosted = viewModel.boostedPlayerIDs.contains(player.id)
        return Button {
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
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Color.crTextSecondary)
            .padding(.horizontal, 4)
    }

    private func stepperRow(_ label: String, value: Binding<Int>, range: ClosedRange<Int>, unit: String? = nil) -> some View {
        HStack {
            Text(label).foregroundStyle(Color.crTextPrimary)
            Spacer()
            Text(unit.map { "\(value.wrappedValue) \($0)" } ?? "\(value.wrappedValue)")
                .font(.body.monospacedDigit())
                .foregroundStyle(Color.crTextPrimary)
                .frame(minWidth: 52, alignment: .trailing)
            Stepper("", value: value, in: range)
                .tint(Color.crAccent)
                .labelsHidden()
        }
        .padding()
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
            .padding(.horizontal)
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
