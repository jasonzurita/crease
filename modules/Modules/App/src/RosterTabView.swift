import CRDesign
import CRModel
import SwiftUI

public struct RosterTabView: View {
    @Environment(SeasonStore.self) private var store
    @State private var showingAddPlayer = false
    @State private var playerToEdit: Player?
    @State private var playerToDelete: Player?
    @State private var errorMessage: String?

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.crBackground.ignoresSafeArea()
                if store.players.isEmpty {
                    emptyState
                } else {
                    playerList
                }
            }
            .navigationTitle("Roster")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.crSurface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text("Roster")
                            .font(.headline)
                            .foregroundStyle(Color.crTextPrimary)
                        if !store.players.isEmpty {
                            Text("\(store.players.count) Players")
                                .font(.caption2)
                                .foregroundStyle(Color.crTextSecondary)
                        }
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        TeamSeasonStatsView()
                    } label: {
                        Image(systemName: "chart.bar.xaxis.ascending")
                            .foregroundStyle(Color.crAccent)
                    }
                    .accessibilityLabel("Season stats")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddPlayer = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.crAccent)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddPlayer) {
            PlayerFormView(store: store, mode: .add)
        }
        .sheet(item: $playerToEdit) { player in
            PlayerFormView(store: store, mode: .edit(player))
        }
        .alert("Remove Player?", isPresented: Binding(
            get: { playerToDelete != nil },
            set: { if !$0 { playerToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) { confirmDelete() }
            Button("Cancel", role: .cancel) { playerToDelete = nil }
        } message: {
            if let player = playerToDelete {
                Text("Remove \(player.name) from the roster? This cannot be undone.")
            }
        }
        .alert("Could Not Delete Player", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 48))
                .foregroundStyle(Color.crTextSecondary)
            Text("No players yet")
                .font(.headline)
                .foregroundStyle(Color.crTextPrimary)
            Text("Tap + to add your first player.")
                .font(.subheadline)
                .foregroundStyle(Color.crTextSecondary)
            Button {
                showingAddPlayer = true
            } label: {
                Text("Add Player")
                    .font(.headline)
                    .foregroundStyle(Color.crBackground)
                    .frame(maxWidth: 200)
                    .padding(.vertical, 14)
                    .background(Color.crAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
            }
            .padding(.top, 8)
        }
        .multilineTextAlignment(.center)
        .padding()
    }

    private var playerList: some View {
        List {
            ForEach(Tier.allCases, id: \.self) { tier in
                let playersInTier = store.players.filter { $0.tier == tier }
                if !playersInTier.isEmpty {
                    Section(tier.rawValue) {
                        ForEach(playersInTier) { player in
                            PlayerRowView(player: player)
                                .listRowBackground(Color.crSurface)
                                .contentShape(Rectangle())
                                .onTapGesture { playerToEdit = player }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        playerToDelete = player
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func confirmDelete() {
        guard let player = playerToDelete else { return }
        playerToDelete = nil
        do {
            try store.deletePlayer(player)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview("Empty") {
    RosterTabView()
        .environment(SeasonStore(fileManagerClient: .mock(), userDefaultsClient: .noop))
}

#Preview("With Players") {
    let store = SeasonStore(fileManagerClient: .mock(), userDefaultsClient: .noop)
    return RosterTabView()
        .environment(store)
}
