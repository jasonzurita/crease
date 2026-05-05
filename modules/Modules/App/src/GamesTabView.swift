import CRDesign
import CRModel
import SwiftUI

public struct GamesTabView: View {
    @Environment(SeasonStore.self) private var store
    @State private var showingGameSetup = false
    @State private var gameToDelete: Game?
    @State private var errorMessage: String?

    public init() {}

    private var activeGames: [Game] {
        store.games.filter { $0.status != .complete }
    }

    private var completedGames: [Game] {
        store.games.filter { $0.status == .complete }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.crBackground.ignoresSafeArea()
                if store.games.isEmpty {
                    emptyState
                } else {
                    gameList
                }
            }
            .navigationTitle("Games")
            .navigationDestination(for: Game.self) { game in
                RotationOutputView(
                    game: game,
                    players: store.players,
                    store: store,
                    showDoneButton: false
                )
            }
            .toolbarBackground(Color.crSurface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingGameSetup = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.crAccent)
                    }
                }
            }
        }
        .sheet(isPresented: $showingGameSetup) {
            GameSetupView(store: store)
        }
        .alert("Remove Game?", isPresented: Binding(
            get: { gameToDelete != nil },
            set: { if !$0 { gameToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) { confirmDelete() }
            Button("Cancel", role: .cancel) { gameToDelete = nil }
        } message: {
            if let game = gameToDelete {
                Text("Remove the game against \(game.opponent)? This cannot be undone.")
            }
        }
        .alert("Could Not Delete Game", isPresented: Binding(
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
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundStyle(Color.crTextSecondary)
            Text("No games yet")
                .font(.headline)
                .foregroundStyle(Color.crTextPrimary)
            Text("Tap + to schedule your first game.")
                .font(.subheadline)
                .foregroundStyle(Color.crTextSecondary)
            Button {
                showingGameSetup = true
            } label: {
                Text("New Game")
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

    @ViewBuilder
    private var gameList: some View {
        List {
            if !activeGames.isEmpty {
                Section("Upcoming") {
                    ForEach(activeGames) { game in
                        NavigationLink(value: game) {
                            GameRowView(game: game)
                        }
                        .listRowBackground(Color.crSurface)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                gameToDelete = game
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            if !completedGames.isEmpty {
                Section("Completed") {
                    ForEach(completedGames) { game in
                        NavigationLink(value: game) {
                            GameRowView(game: game)
                        }
                        .listRowBackground(Color.crSurface)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                gameToDelete = game
                            } label: {
                                Label("Delete", systemImage: "trash")
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
        guard let game = gameToDelete else { return }
        gameToDelete = nil
        do {
            try store.deleteGame(game)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview("Empty") {
    GamesTabView()
        .environment(SeasonStore(fileManagerClient: .mock(), userDefaultsClient: .noop))
}

#Preview("With Games") {
    GamesTabView()
        .environment(SeasonStore(fileManagerClient: .mock(), userDefaultsClient: .noop))
}
