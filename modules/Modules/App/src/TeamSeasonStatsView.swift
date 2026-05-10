import CRDesign
import CRModel
import SwiftUI

struct TeamSeasonStatsView: View {
    @Environment(SeasonStore.self) private var store

    private enum SortColumn { case gamesPlayed, goals, groundBalls }

    private struct PlayerRow: Identifiable {
        let player: Player
        let goals: Int
        let groundBalls: Int
        let gamesPlayed: Int
        var id: UUID {
            player.id
        }
    }

    @State private var sortColumn: SortColumn = .groundBalls
    @State private var sortAscending = false

    private let gpColWidth: CGFloat = 36
    private let gColWidth: CGFloat = 28
    private let gbColWidth: CGFloat = 36

    private var rows: [PlayerRow] {
        let unsorted = store.players.compactMap { player -> PlayerRow? in
            var goals = 0
            var groundBalls = 0
            var gamesPlayed = 0
            for game in store.games where game.status == .complete {
                let isPresent = game.attendance.first { $0.id == player.id }?.isPresent == true
                if isPresent { gamesPlayed += 1 }
                if let stat = game.stats?.playerStats.first(where: { $0.playerID == player.id }) {
                    goals += stat.goals
                    groundBalls += stat.groundBalls
                }
            }
            guard gamesPlayed > 0 else { return nil }
            return PlayerRow(player: player, goals: goals, groundBalls: groundBalls, gamesPlayed: gamesPlayed)
        }

        return unsorted.sorted { a, b in
            let av: Int
            let bv: Int
            switch sortColumn {
            case .gamesPlayed: av = a.gamesPlayed; bv = b.gamesPlayed
            case .goals: av = a.goals; bv = b.goals
            case .groundBalls: av = a.groundBalls; bv = b.groundBalls
            }
            return sortAscending ? av < bv : av > bv
        }
    }

    var body: some View {
        ZStack {
            Color.crBackground.ignoresSafeArea()
            if rows.isEmpty {
                emptyState
            } else {
                statsList
            }
        }
        .navigationTitle("Season Stats")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.crSurface, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - List

    private var statsList: some View {
        List {
            Section {
                columnHeader
                ForEach(rows) { row in
                    statsRow(row)
                }
                legendRow
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .animation(.easeInOut(duration: 0.2), value: sortColumn)
        .animation(.easeInOut(duration: 0.2), value: sortAscending)
    }

    // MARK: - Column header

    private var columnHeader: some View {
        HStack {
            Text("Player")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.crTextSecondary)
            Spacer(minLength: 8)
            HStack(spacing: 0) {
                sortButton(.gamesPlayed, label: "GP", width: gpColWidth)
                sortButton(.goals, label: "G", width: gColWidth)
                sortButton(.groundBalls, label: "GB", width: gbColWidth)
            }
        }
        .listRowBackground(Color.crSurface)
        .padding(.vertical, 2)
    }

    private func sortButton(_ col: SortColumn, label: String, width: CGFloat) -> some View {
        let active = sortColumn == col
        return Button {
            if active {
                sortAscending.toggle()
            } else {
                sortColumn = col
                sortAscending = false
            }
        } label: {
            HStack(spacing: 2) {
                Text(label)
                    .lineLimit(1)
                if active {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .imageScale(.small)
                }
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(active ? Color.crAccent : Color.crTextSecondary)
            .frame(width: width, alignment: .trailing)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data row

    private func statsRow(_ row: PlayerRow) -> some View {
        HStack {
            HStack(spacing: 10) {
                PlayerAvatarView(player: row.player, size: 32)
                VStack(alignment: .leading, spacing: 1) {
                    Text(row.player.name)
                        .font(.subheadline)
                        .foregroundStyle(Color.crTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("#\(row.player.jerseyNumber)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Color.crTextSecondary)
                }
            }
            Spacer(minLength: 8)
            Text("\(row.gamesPlayed)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(
                    sortColumn == .gamesPlayed ? Color.crAccent : Color.crTextSecondary
                )
                .frame(width: gpColWidth, alignment: .trailing)
            Text("\(row.goals)")
                .font(.subheadline.monospacedDigit().weight(row.goals > 0 ? .semibold : .regular))
                .foregroundStyle(
                    sortColumn == .goals
                        ? (row.goals > 0 ? Color.crAccent : Color.crAccent.opacity(0.4))
                        : (row.goals > 0 ? Color.crSuccess : Color.crTextSecondary.opacity(0.4))
                )
                .frame(width: gColWidth, alignment: .trailing)
            Text("\(row.groundBalls)")
                .font(.subheadline.monospacedDigit().weight(row.groundBalls > 0 ? .semibold : .regular))
                .foregroundStyle(
                    sortColumn == .groundBalls
                        ? (row.groundBalls > 0 ? Color.crAccent : Color.crAccent.opacity(0.4))
                        : (row.groundBalls > 0 ? Color.crAccent : Color.crTextSecondary.opacity(0.4))
                )
                .frame(width: gbColWidth, alignment: .trailing)
        }
        .listRowBackground(Color.crSurface)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(row.player.name): \(row.gamesPlayed) games, \(row.goals) goals, \(row.groundBalls) ground balls"
        )
    }

    // MARK: - Legend

    private var legendRow: some View {
        HStack(spacing: 0) {
            legendItem(abbrev: "GP", full: "Games Played")
            Spacer()
            legendItem(abbrev: "G", full: "Goals")
            Spacer()
            legendItem(abbrev: "GB", full: "Ground Balls")
        }
        .listRowBackground(Color.crSurface.opacity(0.5))
        .padding(.vertical, 6)
    }

    private func legendItem(abbrev: String, full: String) -> some View {
        HStack(spacing: 4) {
            Text(abbrev)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.crTextSecondary)
            Text("·")
                .font(.caption2)
                .foregroundStyle(Color.crTextSecondary.opacity(0.4))
            Text(full)
                .font(.caption2)
                .foregroundStyle(Color.crTextSecondary.opacity(0.6))
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis.ascending")
                .font(.system(size: 48))
                .foregroundStyle(Color.crTextSecondary)
            Text("No stats yet")
                .font(.headline)
                .foregroundStyle(Color.crTextPrimary)
            Text("Stats appear here once games are completed.")
                .font(.subheadline)
                .foregroundStyle(Color.crTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        TeamSeasonStatsView()
            .environment(SeasonStore(fileManagerClient: .mock(), userDefaultsClient: .noop))
    }
}
