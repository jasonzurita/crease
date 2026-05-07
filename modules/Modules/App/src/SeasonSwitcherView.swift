import CRDesign
import CRModel
import SwiftUI

struct SeasonSwitcherView: View {
    @Environment(SeasonStore.self) private var store
    @State private var showingNewSeason = false
    @State private var seasonToDelete: Season?
    @State private var confirmDeleteShowing = false
    @State private var finalDeleteShowing = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.crBackground.ignoresSafeArea()
            if store.seasons.isEmpty {
                emptyState
            } else {
                seasonList
            }
        }
        .navigationTitle("Seasons")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.crSurface, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewSeason = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.crAccent)
                }
                .accessibilityLabel("Create new season")
            }
        }
        .sheet(isPresented: $showingNewSeason) {
            SeasonCreationView(store: store, onCreated: { showingNewSeason = false })
        }
        .alert("Delete Season?", isPresented: $confirmDeleteShowing) {
            Button("Continue", role: .destructive) { finalDeleteShowing = true }
            Button("Cancel", role: .cancel) { seasonToDelete = nil }
        } message: {
            if let s = seasonToDelete {
                Text("Delete \"\(s.seasonName)\" and all its games? This cannot be undone.")
            }
        }
        .alert("Delete Forever?", isPresented: $finalDeleteShowing) {
            Button("Delete Forever", role: .destructive) { confirmDelete() }
            Button("Cancel", role: .cancel) { seasonToDelete = nil }
        } message: {
            Text("All game data for this season will be permanently removed.")
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var seasonList: some View {
        List {
            ForEach(store.seasons.sorted { $0.createdAt > $1.createdAt }) { season in
                seasonRow(season)
                    .listRowBackground(Color.crSurface)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            seasonToDelete = season
                            confirmDeleteShowing = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func seasonRow(_ season: Season) -> some View {
        let isActive = store.activeSeason?.id == season.id
        return Button {
            if !isActive { store.setActive(season) }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(season.seasonName)
                        .font(.headline)
                        .foregroundStyle(Color.crTextPrimary)
                    Text(season.teamName)
                        .font(.caption)
                        .foregroundStyle(Color.crTextSecondary)
                }
                Spacer()
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.crAccent)
                        .accessibilityLabel("Active season")
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(season.seasonName) — \(season.teamName)\(isActive ? ", active" : "")")
        .accessibilityHint(isActive ? "" : "Double tap to switch to this season")
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(Color.crTextSecondary)
            Text("No seasons yet")
                .font(.headline)
                .foregroundStyle(Color.crTextPrimary)
        }
    }

    private func confirmDelete() {
        guard let season = seasonToDelete else { return }
        seasonToDelete = nil
        do {
            try store.deleteSeason(season)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        SeasonSwitcherView()
            .environment(SeasonStore(fileManagerClient: .mock(), userDefaultsClient: .noop))
    }
}
