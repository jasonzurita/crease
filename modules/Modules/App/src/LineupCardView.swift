import CRDesign
import CRModel
import SwiftUI
import UIKit

struct LineupCardView: View {
    let game: Game
    let players: [Player]
    let teamName: String
    let includesPlayingTime: Bool
    let slotDurationMinutes: Int

    private static let cardWidth: CGFloat = 390
    private static let outerPad: CGFloat = 14
    private static let avatarSize: CGFloat = 30
    private static let ptAvatarSize: CGFloat = 22
    // Bar width computed to fill the playing-time row exactly:
    // 390 - outerPad*2 - (ptAvatarSize + 8 + nameWidth + 8 + barWidth + 8 + minutesWidth) = 0
    // 390 - 28 - (22 + 8 + 110 + 8 + bar + 8 + 28) = 0  →  bar = 390 - 28 - 184 = 178
    private static let ptBarWidth: CGFloat = 178
    private static let ptNameWidth: CGFloat = 110

    private static let orderedPositions: [Position] = [.goalie, .attack, .midfield, .defense]
    private static let positionColor: [Position: Color] = [
        .goalie: .crWarning,
        .attack: .crDanger,
        .midfield: .crAccent,
        .defense: .crSuccess,
    ]
    private static let positionLabel: [Position: String] = [
        .goalie: "Goalie",
        .attack: "Attack",
        .midfield: "Midfield",
        .defense: "Defense",
    ]

    var body: some View {
        VStack(spacing: 0) {
            cardHeader
            if let plan = game.rotationPlan {
                rotationsSection(plan)
                if includesPlayingTime {
                    playingTimeSection(plan)
                }
            }
            cardFooter
        }
        .background(Color.crBackground)
        .frame(width: Self.cardWidth)
    }

    // MARK: - Card header

    private var cardHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(teamName.uppercased())
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.crTextSecondary)
                    .tracking(1.5)
                Spacer()
                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(Color.crTextSecondary)
            }
            HStack(alignment: .firstTextBaseline) {
                Text("vs. \(game.opponent)")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.crTextPrimary)
                Spacer()
                Text(game.isHome ? "HOME" : "AWAY")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.crAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.crAccent.opacity(0.15))
                    .clipShape(Capsule())
            }
            Text(rotationDescription)
                .font(.caption)
                .foregroundStyle(Color.crTextSecondary)
        }
        .padding(Self.outerPad)
        .background(Color.crSurface)
    }

    private var rotationDescription: String {
        switch game.rotationStyle {
        case .byQuarter:
            return "\(game.format.quarters) quarters · \(game.format.quarterLengthMinutes) min each · substitute at each quarter break"
        case let .byTimeInterval(mins):
            return "\(game.format.quarters) quarters · \(game.format.quarterLengthMinutes) min each · substitute every \(mins) min"
        }
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: game.date)
    }

    // MARK: - Rotations

    private func rotationsSection(_ plan: RotationPlan) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(plan.slots.enumerated()), id: \.offset) { i, slot in
                VStack(spacing: 0) {
                    if i > 0 {
                        subAtDivider(slot: slot)
                    }
                    rotationCard(slot: slot)
                }
            }
        }
        .padding(.top, 12)
        .padding(.horizontal, Self.outerPad)
        .padding(.bottom, 12)
    }

    // MARK: - Sub-at divider

    private func subAtDivider(slot: RotationSlot) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color.crWarning.opacity(0.35))
                .frame(height: 1)
            Text("SUB AT \(formatMinute(startMinute(slot: slot)))")
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(Color.crWarning)
                .fixedSize()
            Rectangle()
                .fill(Color.crWarning.opacity(0.35))
                .frame(height: 1)
        }
        .padding(.vertical, 10)
    }

    // MARK: - Rotation card

    private func rotationCard(slot: RotationSlot) -> some View {
        VStack(spacing: 0) {
            rotationCardHeader(slot: slot)
            playerRows(slot: slot)
            if !slot.bench.isEmpty {
                benchRow(slot: slot)
            }
        }
        .background(Color.crSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func rotationCardHeader(slot: RotationSlot) -> some View {
        HStack {
            Text(slotTitle(slot))
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(Color.crTextPrimary)
            Spacer()
            Text("\(formatMinute(startMinute(slot: slot))) – \(formatMinute(endMinute(slot: slot)))")
                .font(.caption.monospacedDigit().weight(.medium))
                .foregroundStyle(Color.crTextSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1)
        }
    }

    private func slotTitle(_ slot: RotationSlot) -> String {
        switch game.rotationStyle {
        case .byQuarter:
            return "Quarter \(slot.quarter)"
        case .byTimeInterval:
            return "Quarter \(slot.quarter)  ·  Rotation \(slot.subIndex + 1)"
        }
    }

    // MARK: - Player rows

    private func playerRows(slot: RotationSlot) -> some View {
        let assignments = Self.orderedPositions.flatMap { pos in
            slot.assignments.filter { $0.position == pos }
        }
        return VStack(spacing: 0) {
            ForEach(Array(assignments.enumerated()), id: \.offset) { i, assignment in
                if i > 0 {
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 1)
                        .padding(.horizontal, 14)
                }
                playerRow(assignment: assignment)
            }
        }
    }

    private func playerRow(assignment: PositionAssignment) -> some View {
        let player = players.first { $0.id == assignment.playerID }
        let color = Self.positionColor[assignment.position] ?? .crAccent
        let posName = Self.positionLabel[assignment.position] ?? assignment.position.rawValue

        return HStack(spacing: 10) {
            inlineAvatar(player: player, size: Self.avatarSize)

            VStack(alignment: .leading, spacing: 1) {
                Text(player?.name ?? "Unknown")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.crTextPrimary)
                    .lineLimit(1)
                if let jersey = player?.jerseyNumber {
                    Text("#\(jersey)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Color.crTextSecondary)
                }
            }

            Spacer()

            Text(posName)
                .font(.caption2.weight(.bold))
                .foregroundStyle(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.14))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Bench row

    private func benchRow(slot: RotationSlot) -> some View {
        let names = slot.bench
            .compactMap { id in players.first { $0.id == id }?.name }
            .joined(separator: " · ")

        return HStack(alignment: .top, spacing: 6) {
            Text("BENCH")
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(Color.crTextSecondary)
                .padding(.top, 1)
            Text(names.isEmpty ? "—" : names)
                .font(.caption2)
                .foregroundStyle(Color.crTextSecondary.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.025))
        .overlay(alignment: .top) {
            Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1)
        }
    }

    // MARK: - Playing time

    @ViewBuilder
    private func playingTimeSection(_ plan: RotationPlan) -> some View {
        let total = max(1, plan.slots.count * slotDurationMinutes)
        let present = players
            .filter { p in game.attendance.first { $0.id == p.id }?.isPresent == true }
            .sorted { minutesOn(player: $0, plan: plan) > minutesOn(player: $1, plan: plan) }

        if !present.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("PLAYING TIME")
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.crTextSecondary)
                        .tracking(1)
                    Spacer()
                    Text("Total \(total) min")
                        .font(.caption2)
                        .foregroundStyle(Color.crTextSecondary.opacity(0.55))
                }
                .padding(.horizontal, Self.outerPad)
                .padding(.top, 14)
                .padding(.bottom, 8)

                VStack(spacing: 5) {
                    ForEach(present) { player in
                        let mins = minutesOn(player: player, plan: plan)
                        let fraction = min(1.0, Double(mins) / Double(total))
                        HStack(spacing: 8) {
                            inlineAvatar(player: player, size: Self.ptAvatarSize)
                            Text(player.name)
                                .font(.caption2)
                                .foregroundStyle(Color.crTextPrimary)
                                .frame(width: Self.ptNameWidth, alignment: .leading)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.crTextSecondary.opacity(0.15))
                                    .frame(width: Self.ptBarWidth, height: 8)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.crAccent)
                                    .frame(width: max(0, Self.ptBarWidth * fraction), height: 8)
                            }
                            Text("\(mins)m")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(Color.crTextSecondary)
                                .frame(width: 28, alignment: .trailing)
                        }
                        .padding(.horizontal, Self.outerPad)
                    }
                }
                .padding(.bottom, 14)
            }
            .background(Color.crSurface)
            .padding(.top, 2)
        }
    }

    private func minutesOn(player: Player, plan: RotationPlan) -> Int {
        plan.slots.filter { slot in
            slot.assignments.contains { pa in
                pa.playerID == player.id &&
                    (pa.position != .goalie || game.fairnessTargets.goalieTimeCountsAsFieldTime)
            }
        }.count * slotDurationMinutes
    }

    // MARK: - Inline avatar (synchronous — safe for ImageRenderer)

    private func inlineAvatar(player: Player?, size: CGFloat) -> some View {
        Group {
            if let data = player?.avatarImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                initialsCircle(player: player, size: size)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private func initialsCircle(player: Player?, size: CGFloat) -> some View {
        let palette: [Color] = [.blue, .indigo, .purple, .pink, .orange, .green, .teal, .cyan]
        let bg = player.map { palette[abs($0.name.hashValue) % palette.count].opacity(0.85) } ?? Color.gray.opacity(0.5)
        let label: String
        if let p = player {
            label = p.initials.isEmpty ? "#\(p.jerseyNumber)" : p.initials
        } else {
            label = "?"
        }
        return ZStack {
            Circle().fill(bg)
            Text(label)
                .font(.system(size: size * 0.36, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
        }
    }

    // MARK: - Time helpers

    private func startMinute(slot: RotationSlot) -> Int {
        switch game.rotationStyle {
        case .byQuarter:
            return (slot.quarter - 1) * game.format.quarterLengthMinutes
        case let .byTimeInterval(mins):
            return (slot.quarter - 1) * game.format.quarterLengthMinutes + slot.subIndex * mins
        }
    }

    private func endMinute(slot: RotationSlot) -> Int {
        switch game.rotationStyle {
        case .byQuarter:
            return slot.quarter * game.format.quarterLengthMinutes
        case let .byTimeInterval(mins):
            return startMinute(slot: slot) + mins
        }
    }

    private func formatMinute(_ minutes: Int) -> String {
        "\(minutes):00"
    }

    // MARK: - Footer

    private var cardFooter: some View {
        HStack {
            Spacer()
            Text("Made with Crease")
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.crTextSecondary.opacity(0.3))
        }
        .padding(.horizontal, Self.outerPad)
        .padding(.vertical, 10)
        .background(Color.crBackground)
    }
}

#Preview {
    ScrollView {
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
    .background(Color.black)
}
