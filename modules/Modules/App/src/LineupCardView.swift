import CRDesign
import CRModel
import SwiftUI

struct LineupCardView: View {
    let game: Game
    let players: [Player]
    let teamName: String
    let includesPlayingTime: Bool
    let slotDurationMinutes: Int

    private static let positions: [Position] = [.goalie, .attack, .midfield, .defense]
    private static let posLabel: [Position: String] = [
        .goalie: "G", .attack: "A", .midfield: "M", .defense: "D",
    ]
    private static let cardWidth: CGFloat = 390
    private static let labelWidth: CGFloat = 52
    private static let ptBarWidth: CGFloat = 210

    var body: some View {
        VStack(spacing: 0) {
            header
            if let plan = game.rotationPlan {
                rotationGrid(plan)
                if includesPlayingTime {
                    playingTimeSection(plan)
                }
            }
            footer
        }
        .background(Color.crBackground)
        .frame(width: Self.cardWidth)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(teamName.uppercased())
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.crTextSecondary)
                    .tracking(1.5)
                Spacer()
                Text(formattedDate)
                    .font(.caption2)
                    .foregroundStyle(Color.crTextSecondary)
            }
            HStack(alignment: .firstTextBaseline) {
                Text("vs. \(game.opponent)")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.crTextPrimary)
                Spacer()
                Text(game.isHome ? "HOME" : "AWAY")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.crAccent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.crAccent.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.crSurface)
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: game.date)
    }

    // MARK: - Rotation Grid

    private func rotationGrid(_ plan: RotationPlan) -> some View {
        let slotCount = max(1, plan.slots.count)
        let colW = (Self.cardWidth - Self.labelWidth) / CGFloat(slotCount)

        return VStack(spacing: 0) {
            headerRow(plan: plan, colW: colW)
            Rectangle()
                .fill(Color.crTextSecondary.opacity(0.2))
                .frame(height: 1)
            ForEach(Self.positions, id: \.self) { position in
                positionRow(position: position, plan: plan, colW: colW)
                Rectangle()
                    .fill(Color.crTextSecondary.opacity(0.1))
                    .frame(height: 1)
            }
        }
        .padding(.vertical, 6)
    }

    private func headerRow(plan: RotationPlan, colW: CGFloat) -> some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: Self.labelWidth, height: 26)
                .overlay(alignment: .trailing) {
                    Rectangle().fill(Color.crTextSecondary.opacity(0.2)).frame(width: 1)
                }
            ForEach(Array(plan.slots.enumerated()), id: \.offset) { i, slot in
                Text(slotLabel(slot))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.crTextPrimary)
                    .frame(width: colW, height: 26)
                    .background(i.isMultiple(of: 2) ? Color.crSurface : Color.crBackground)
                    .overlay(alignment: .trailing) {
                        Rectangle().fill(Color.crTextSecondary.opacity(0.1)).frame(width: 1)
                    }
            }
        }
    }

    private func positionRow(position: Position, plan: RotationPlan, colW: CGFloat) -> some View {
        HStack(spacing: 0) {
            Text(Self.posLabel[position] ?? "")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.crTextSecondary)
                .frame(width: Self.labelWidth, height: 34, alignment: .leading)
                .padding(.leading, 10)
                .overlay(alignment: .trailing) {
                    Rectangle().fill(Color.crTextSecondary.opacity(0.2)).frame(width: 1)
                }
            ForEach(Array(plan.slots.enumerated()), id: \.offset) { i, slot in
                let name = slot.assignments
                    .first { $0.position == position }
                    .flatMap { pa in players.first { $0.id == pa.playerID } }
                    .map { shortName($0.name) } ?? "—"
                Text(name)
                    .font(.caption2)
                    .foregroundStyle(name == "—" ? Color.crTextSecondary.opacity(0.35) : Color.crTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: colW, height: 34)
                    .background(i.isMultiple(of: 2) ? Color.crSurface.opacity(0.4) : Color.clear)
                    .overlay(alignment: .trailing) {
                        Rectangle().fill(Color.crTextSecondary.opacity(0.1)).frame(width: 1)
                    }
            }
        }
    }

    private func slotLabel(_ slot: RotationSlot) -> String {
        switch game.rotationStyle {
        case .byQuarter: return "Q\(slot.quarter)"
        case .byTimeInterval: return "Q\(slot.quarter)·\(slot.subIndex + 1)"
        }
    }

    private func shortName(_ full: String) -> String {
        full.split(separator: " ").first.map(String.init) ?? full
    }

    // MARK: - Playing Time

    @ViewBuilder
    private func playingTimeSection(_ plan: RotationPlan) -> some View {
        let totalMinutes = plan.slots.count * slotDurationMinutes
        let present = players
            .filter { p in game.attendance.first { $0.id == p.id }?.isPresent == true }
            .sorted { minutesOn(player: $0, plan: plan) > minutesOn(player: $1, plan: plan) }

        Rectangle().fill(Color.crTextSecondary.opacity(0.2)).frame(height: 1)

        VStack(alignment: .leading, spacing: 0) {
            Text("PLAYING TIME")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Color.crTextSecondary)
                .tracking(1)
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 6)

            VStack(spacing: 0) {
                ForEach(present) { player in
                    let mins = minutesOn(player: player, plan: plan)
                    let fraction = totalMinutes > 0 ? min(1.0, Double(mins) / Double(totalMinutes)) : 0
                    HStack(spacing: 10) {
                        Text(player.name)
                            .font(.caption2)
                            .foregroundStyle(Color.crTextPrimary)
                            .frame(width: 100, alignment: .leading)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.crTextSecondary.opacity(0.15))
                                .frame(width: Self.ptBarWidth, height: 8)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.crAccent)
                                .frame(width: max(0, Self.ptBarWidth * fraction), height: 8)
                        }
                        Text("\(mins)m")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(Color.crTextSecondary)
                            .frame(width: 28, alignment: .trailing)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 3)
                }
            }
            .padding(.bottom, 10)
        }
        .background(Color.crSurface)
    }

    private func minutesOn(player: Player, plan: RotationPlan) -> Int {
        let count = plan.slots.filter { slot in
            slot.assignments.contains { pa in
                pa.playerID == player.id &&
                    (pa.position != .goalie || game.fairnessTargets.goalieTimeCountsAsFieldTime)
            }
        }.count
        return count * slotDurationMinutes
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Spacer()
            Text("Crease")
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.crTextSecondary.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.crBackground)
    }
}

#Preview {
    LineupCardView(
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
        teamName: "Eagles",
        includesPlayingTime: true,
        slotDurationMinutes: 10
    )
}
