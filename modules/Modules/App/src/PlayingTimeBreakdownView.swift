import CRDesign
import CRModel
import SwiftUI

struct PlayingTimeBreakdownView: View {
    let viewModel: RotationOutputViewModel

    private var totalMinutes: Int {
        guard let plan = viewModel.plan else { return 1 }
        return max(1, plan.slots.count * viewModel.slotDurationMinutes)
    }

    var body: some View {
        content
    }

    @ViewBuilder
    private var content: some View {
        let allRows = viewModel.breakdownSections.flatMap(\.rows)
        if allRows.isEmpty {
            emptyState
        } else {
            playerList
        }
    }

    private var playerList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                ForEach(viewModel.breakdownSections) { section in
                    Section {
                        ForEach(section.rows) { row in
                            BreakdownPlayerRow(row: row, totalMinutes: totalMinutes)
                            Divider()
                                .background(Color.crTextSecondary.opacity(0.1))
                                .padding(.leading, 16)
                        }
                    } header: {
                        if let tier = section.tier {
                            tierSectionHeader(tier)
                        }
                    }
                }
            }
        }
    }

    private func tierSectionHeader(_ tier: Tier) -> some View {
        HStack {
            Text(tier.rawValue.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.crTextSecondary)
                .tracking(1)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.crBackground)
    }

    private var emptyState: some View {
        Text("No players present")
            .font(.subheadline)
            .foregroundStyle(Color.crTextSecondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 60)
    }
}

private struct BreakdownPlayerRow: View {
    let row: RotationOutputViewModel.BreakdownRow
    let totalMinutes: Int

    private var showGoalieSplit: Bool {
        row.goalMinutes > 0 && row.fieldMinutes > 0
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            playerInfo
            Spacer(minLength: 0)
            minutesColumn
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.crBackground)
    }

    private var playerInfo: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(row.player.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.crTextPrimary)
                Text("#\(row.player.jerseyNumber)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Color.crTextSecondary)
            }
            if !row.assignedPositions.isEmpty {
                Text(row.assignedPositions.map(\.rawValue).joined(separator: " · "))
                    .font(.caption2)
                    .foregroundStyle(Color.crTextSecondary)
            } else {
                Text("No assignments")
                    .font(.caption2)
                    .foregroundStyle(Color.crTextSecondary.opacity(0.5))
            }
            if let note = row.conflictNote {
                Text(note)
                    .font(.caption2)
                    .foregroundStyle(Color.crWarning)
            }
        }
        .frame(minWidth: 110, maxWidth: 140, alignment: .leading)
    }

    private var minutesColumn: some View {
        VStack(alignment: .trailing, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.crTextSecondary.opacity(0.15))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(width: max(0, geo.size.width * row.minutesFraction))
                    if row.minimumMinutes > 0 {
                        let minFraction = min(1.0, Double(row.minimumMinutes) / Double(totalMinutes))
                        Rectangle()
                            .fill(Color.crTextPrimary.opacity(0.4))
                            .frame(width: 1.5)
                            .offset(x: geo.size.width * minFraction - 0.75)
                    }
                }
            }
            .frame(height: 12)

            if showGoalieSplit {
                HStack(spacing: 8) {
                    Text("Goal \(row.goalMinutes)m")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Color.crTextSecondary)
                    Text("Field \(row.fieldMinutes)m")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Color.crTextSecondary)
                }
            }

            Text("\(row.projectedMinutes)m")
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(barColor)
        }
        .frame(minWidth: 100)
    }

    private var barColor: Color {
        switch row.status {
        case .met: Color.crSuccess
        case .near: Color.crWarning
        case .violation: Color.crDanger
        }
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
    PlayingTimeBreakdownView(viewModel: vm)
}
