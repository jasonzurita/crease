import CRDesign
import CRModel
import SwiftUI

public struct PostGameSummaryView: View {
    private let game: Game
    private let players: [Player]
    private let teamName: String
    @State private var rotationExpanded = false
    @State private var isSharing = false
    @State private var shareImage: UIImage?

    private var slotDurationMinutes: Int {
        switch game.rotationStyle {
        case .byQuarter: return game.format.quarterLengthMinutes
        case let .byTimeInterval(m): return m
        }
    }

    private var presentPlayers: [Player] {
        players
            .filter { p in game.attendance.first { $0.id == p.id }?.isPresent == true }
            .sorted { projectedMinutes($0) > projectedMinutes($1) }
    }

    public init(game: Game, players: [Player], teamName: String) {
        self.game = game
        self.players = players
        self.teamName = teamName
    }

    public var body: some View {
        ZStack {
            Color.crBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    scoreHeader
                    Divider().background(Color.crTextSecondary.opacity(0.2))
                    playingTimeSection
                    if hasStats { statsSection }
                    rotationSection
                }
            }
        }
        .navigationTitle("vs. \(game.opponent)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.crSurface, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    generateShareImage()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .foregroundStyle(Color.crAccent)
                .accessibilityLabel("Share game summary")
            }
        }
        .sheet(isPresented: $isSharing) {
            if let image = shareImage {
                ActivityView(items: [image])
            }
        }
    }

    // MARK: - Score Header

    private var scoreHeader: some View {
        VStack(spacing: 8) {
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
            if let stats = game.stats {
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    scoreDisplay(label: teamName, score: stats.usScore, isUs: true)
                    Text("—")
                        .font(.title2)
                        .foregroundStyle(Color.crTextSecondary)
                    scoreDisplay(label: game.opponent, score: stats.themScore, isUs: false)
                }
                .frame(maxWidth: .infinity)
            } else {
                Text("vs. \(game.opponent)")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.crTextPrimary)
            }
            Text(game.isHome ? "Home" : "Away")
                .font(.caption)
                .foregroundStyle(Color.crTextSecondary)
        }
        .padding(16)
        .background(Color.crSurface)
    }

    private func scoreDisplay(label: String, score: Int, isUs: Bool) -> some View {
        VStack(spacing: 2) {
            Text("\(score)")
                .font(.system(size: 48, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(isUs ? Color.crTextPrimary : Color.crTextSecondary)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.crTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: 120)
        }
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: game.date)
    }

    // MARK: - Playing Time

    private var playingTimeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Playing Time")
            let total = max(1, (game.rotationPlan?.slots.count ?? 0) * slotDurationMinutes)
            VStack(spacing: 6) {
                ForEach(presentPlayers) { player in
                    playingTimeRow(player: player, totalMinutes: total)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(Color.crBackground)
    }

    private func playingTimeRow(player: Player, totalMinutes: Int) -> some View {
        let mins = projectedMinutes(player)
        let minimum = game.fairnessTargets.minutes(for: player.tier)
        let fraction = min(1.0, Double(mins) / Double(totalMinutes))
        let belowMin = mins < minimum

        return HStack(spacing: 10) {
            Text(player.name)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.crTextPrimary)
                .frame(width: 110, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.crTextSecondary.opacity(0.15))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(belowMin ? Color.crDanger : Color.crSuccess)
                        .frame(width: max(0, geo.size.width * fraction))
                }
            }
            .frame(height: 12)
            Text("\(mins)m")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(belowMin ? Color.crDanger : Color.crTextSecondary)
                .frame(width: 30, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(player.name): \(mins) minutes\(belowMin ? ", below minimum" : "")")
    }

    private func projectedMinutes(_ player: Player) -> Int {
        guard let plan = game.rotationPlan else { return 0 }
        let count = plan.slots.filter { slot in
            slot.assignments.contains { pa in
                pa.playerID == player.id &&
                    (pa.position != .goalie || game.fairnessTargets.goalieTimeCountsAsFieldTime)
            }
        }.count
        return count * slotDurationMinutes
    }

    // MARK: - Stats

    private var hasStats: Bool {
        guard let stats = game.stats else { return false }
        return stats.playerStats.contains { $0.goals > 0 || $0.groundBalls > 0 }
            || stats.opponentGroundBalls > 0
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Stats")
            VStack(spacing: 0) {
                if let stats = game.stats {
                    let scorers = presentPlayers.filter { player in
                        stats.playerStats.first { $0.playerID == player.id }
                            .map { $0.goals > 0 || $0.groundBalls > 0 } ?? false
                    }
                    ForEach(Array(scorers.enumerated()), id: \.element.id) { i, player in
                        if let stat = stats.playerStats.first(where: { $0.playerID == player.id }) {
                            playerStatRow(player: player, stat: stat)
                            if i < scorers.count - 1 {
                                Rectangle()
                                    .fill(Color.white.opacity(0.06))
                                    .frame(height: 1)
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    if stats.opponentGroundBalls > 0 {
                        Rectangle()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 1)
                            .padding(.horizontal, 16)
                        HStack {
                            Text("\(game.opponent) Ground Balls")
                                .font(.subheadline)
                                .foregroundStyle(Color.crTextSecondary)
                            Spacer()
                            Text("\(stats.opponentGroundBalls)")
                                .font(.subheadline.monospacedDigit().weight(.semibold))
                                .foregroundStyle(Color.crTextSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                }
            }
            .background(Color.crSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.crBackground)
    }

    private func playerStatRow(player: Player, stat: PlayerStat) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(player.name)
                    .font(.subheadline)
                    .foregroundStyle(Color.crTextPrimary)
                Text("#\(player.jerseyNumber)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Color.crTextSecondary)
            }
            Spacer()
            if stat.goals > 0 {
                statPill(value: stat.goals, label: "G")
            }
            if stat.groundBalls > 0 {
                statPill(value: stat.groundBalls, label: "GB")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(player.name): \(stat.goals) goals, \(stat.groundBalls) ground balls"
        )
    }

    private func statPill(value: Int, label: String) -> some View {
        HStack(spacing: 4) {
            Text("\(value)")
                .font(.subheadline.monospacedDigit().weight(.bold))
                .foregroundStyle(Color.crTextPrimary)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.crTextSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.crTextSecondary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Rotation

    private var rotationSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { rotationExpanded.toggle() }
            } label: {
                HStack {
                    Text("Rotation")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.crTextPrimary)
                    Spacer()
                    Image(systemName: rotationExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.crTextSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(rotationExpanded ? "Collapse rotation" : "Expand rotation")

            if rotationExpanded, let plan = game.rotationPlan {
                collapsedGrid(plan)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.crSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
        .background(Color.crBackground)
    }

    private func collapsedGrid(_ plan: RotationPlan) -> some View {
        let positions: [Position] = [.goalie, .attack, .midfield, .defense]
        let posLabel: [Position: String] = [.goalie: "G", .attack: "A", .midfield: "M", .defense: "D"]
        let labelW: CGFloat = 48
        let slotCount = max(1, plan.slots.count)

        return GeometryReader { proxy in
            let colW = max(60, (proxy.size.width - 32 - labelW) / CGFloat(slotCount))
            scrollableGrid(plan: plan, positions: positions, posLabel: posLabel, labelW: labelW, colW: colW)
        }
        .frame(height: 160)
    }

    private func scrollableGrid(plan: RotationPlan, positions: [Position], posLabel: [Position: String], labelW: CGFloat, colW: CGFloat) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Color.clear.frame(width: labelW, height: 24)
                    ForEach(Array(plan.slots.enumerated()), id: \.offset) { _, slot in
                        Text(slotLabel(slot))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.crTextPrimary)
                            .frame(width: colW, height: 24)
                    }
                }
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Color.crTextSecondary.opacity(0.15)).frame(height: 1)
                }

                ForEach(positions, id: \.self) { position in
                    HStack(spacing: 0) {
                        Text(posLabel[position] ?? "")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.crTextSecondary)
                            .frame(width: labelW, height: 30, alignment: .leading)
                            .padding(.leading, 8)
                        ForEach(Array(plan.slots.enumerated()), id: \.offset) { _, slot in
                            let name = slot.assignments
                                .first { $0.position == position }
                                .flatMap { pa in players.first { $0.id == pa.playerID } }
                                .map { shortName($0.name) } ?? "—"
                            Text(name)
                                .font(.caption2)
                                .foregroundStyle(name == "—" ? Color.crTextSecondary.opacity(0.35) : Color.crTextPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(width: colW, height: 30)
                        }
                    }
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(Color.crTextSecondary.opacity(0.08)).frame(height: 1)
                    }
                }
            }
        }
        .padding(.bottom, 8)
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

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption2.weight(.bold))
            .foregroundStyle(Color.crTextSecondary)
            .tracking(1)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)
    }

    // MARK: - Share

    private func generateShareImage() {
        let card = PostGameShareCard(
            game: game,
            players: players,
            teamName: teamName,
            slotDurationMinutes: slotDurationMinutes
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        shareImage = renderer.uiImage
        isSharing = true
    }
}

// MARK: - Share Card

private struct PostGameShareCard: View {
    let game: Game
    let players: [Player]
    let teamName: String
    let slotDurationMinutes: Int

    private static let cardWidth: CGFloat = 390
    private static let barWidth: CGFloat = 180

    private var presentPlayers: [Player] {
        players
            .filter { p in game.attendance.first { $0.id == p.id }?.isPresent == true }
            .sorted { projectedMinutes($0) > projectedMinutes($1) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            playingTimeBars
            if let stats = game.stats,
               stats.playerStats.contains(where: { $0.goals > 0 || $0.groundBalls > 0 }) {
                statsRows(stats: stats)
            }
            footer
        }
        .background(Color.crBackground)
        .frame(width: Self.cardWidth)
    }

    private var header: some View {
        VStack(spacing: 6) {
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
            if let stats = game.stats {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("\(stats.usScore)")
                        .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Color.crTextPrimary)
                    Text("vs. \(game.opponent)")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.crTextPrimary)
                    Text("\(stats.themScore)")
                        .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Color.crTextSecondary)
                }
            } else {
                Text("vs. \(game.opponent)")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.crTextPrimary)
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

    private var playingTimeBars: some View {
        let total = max(1, (game.rotationPlan?.slots.count ?? 0) * slotDurationMinutes)
        return VStack(alignment: .leading, spacing: 0) {
            Text("PLAYING TIME")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Color.crTextSecondary)
                .tracking(1)
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 6)
            VStack(spacing: 0) {
                ForEach(presentPlayers) { player in
                    let mins = projectedMinutes(player)
                    let fraction = min(1.0, Double(mins) / Double(total))
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
                                .frame(width: Self.barWidth, height: 8)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.crAccent)
                                .frame(width: max(0, Self.barWidth * fraction), height: 8)
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

    private func statsRows(stats: GameStats) -> some View {
        let scorers = presentPlayers.filter { p in
            stats.playerStats.first { $0.playerID == p.id }
                .map { $0.goals > 0 || $0.groundBalls > 0 } ?? false
        }
        return VStack(alignment: .leading, spacing: 0) {
            Rectangle().fill(Color.crTextSecondary.opacity(0.15)).frame(height: 1)
            Text("STATS")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Color.crTextSecondary)
                .tracking(1)
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 6)
            ForEach(scorers) { player in
                if let stat = stats.playerStats.first(where: { $0.playerID == player.id }) {
                    HStack {
                        Text(player.name)
                            .font(.caption2)
                            .foregroundStyle(Color.crTextPrimary)
                        Spacer()
                        if stat.goals > 0 {
                            Text("\(stat.goals)G")
                                .font(.caption2.weight(.semibold).monospacedDigit())
                                .foregroundStyle(Color.crSuccess)
                        }
                        if stat.groundBalls > 0 {
                            Text("\(stat.groundBalls)GB")
                                .font(.caption2.weight(.semibold).monospacedDigit())
                                .foregroundStyle(Color.crTextSecondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 3)
                }
            }
            Spacer(minLength: 10)
        }
        .background(Color.crSurface)
    }

    private func projectedMinutes(_ player: Player) -> Int {
        guard let plan = game.rotationPlan else { return 0 }
        let count = plan.slots.filter { slot in
            slot.assignments.contains { pa in
                pa.playerID == player.id &&
                    (pa.position != .goalie || game.fairnessTargets.goalieTimeCountsAsFieldTime)
            }
        }.count
        return count * slotDurationMinutes
    }

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
    NavigationStack {
        PostGameSummaryView(
            game: Game(
                id: UUID(),
                opponent: "Hawks",
                date: Date(),
                isHome: true,
                status: .complete,
                attendance: [],
                format: .default,
                rotationStyle: .byQuarter,
                fairnessTargets: .default,
                competitivenessMode: .balanced,
                boostedPlayerIDs: [],
                stats: GameStats(usScore: 7, themScore: 4, playerStats: [], opponentGroundBalls: 3),
                createdAt: Date()
            ),
            players: [],
            teamName: "Eagles"
        )
    }
}
