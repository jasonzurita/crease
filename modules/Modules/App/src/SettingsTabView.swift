import CRDesign
import CRModel
import SwiftUI

public struct SettingsTabView: View {
    @Environment(SeasonStore.self) private var store
    @AppStorage("cr_color_scheme") private var colorSchemePreference = "system"
    @State private var showingExportError: String?
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var confirmDeleteShowing = false
    @State private var finalDeleteShowing = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.crBackground.ignoresSafeArea()
                List {
                    activeSeasonSection
                    seasonsSection
                    dataSection
                    appearanceSection
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .toolbarBackground(Color.crSurface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(isPresented: $isExporting) {
            if let url = exportURL {
                ActivityView(items: [url])
            }
        }
        .alert("Export Failed", isPresented: Binding(
            get: { showingExportError != nil },
            set: { if !$0 { showingExportError = nil } }
        )) {
            Button("OK") { showingExportError = nil }
        } message: {
            Text(showingExportError ?? "")
        }
        .alert("Delete Active Season?", isPresented: $confirmDeleteShowing) {
            Button("Continue", role: .destructive) { finalDeleteShowing = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let s = store.activeSeason {
                Text("Delete \"\(s.seasonName)\" and all its games? This cannot be undone.")
            }
        }
        .alert("Delete Forever?", isPresented: $finalDeleteShowing) {
            Button("Delete Forever", role: .destructive) { deleteActiveSeason() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All game data for this season will be permanently removed.")
        }
    }

    // MARK: - Sections

    private var activeSeasonSection: some View {
        Section("Active Season") {
            if let season = store.activeSeason {
                NavigationLink {
                    SeasonEditorView(season: season, store: store)
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(season.seasonName)
                            .font(.headline)
                            .foregroundStyle(Color.crTextPrimary)
                        Text(season.teamName)
                            .font(.caption)
                            .foregroundStyle(Color.crTextSecondary)
                    }
                    .padding(.vertical, 2)
                }
                .listRowBackground(Color.crSurface)
                .accessibilityHint("Edit season name and format defaults")
            }
        }
    }

    private var seasonsSection: some View {
        Section("All Seasons") {
            NavigationLink {
                SeasonSwitcherView().environment(store)
            } label: {
                HStack {
                    Label("Manage Seasons", systemImage: "calendar.badge.clock")
                        .foregroundStyle(Color.crTextPrimary)
                    Spacer()
                    Text("\(store.seasons.count)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Color.crTextSecondary)
                }
            }
            .listRowBackground(Color.crSurface)
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Button {
                exportSeason()
            } label: {
                Label("Export Season", systemImage: "square.and.arrow.up")
                    .foregroundStyle(Color.crAccent)
            }
            .listRowBackground(Color.crSurface)
            .disabled(store.activeSeason == nil)
            .accessibilityLabel("Export active season as a zip file")

            Button(role: .destructive) {
                confirmDeleteShowing = true
            } label: {
                Label("Delete Active Season", systemImage: "trash")
                    .foregroundStyle(Color.crDanger)
            }
            .listRowBackground(Color.crSurface)
            .disabled(store.activeSeason == nil)
            .accessibilityLabel("Permanently delete active season and all its games")
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Color Scheme", selection: $colorSchemePreference) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .foregroundStyle(Color.crTextPrimary)
            .tint(Color.crAccent)
            .listRowBackground(Color.crSurface)
        }
    }

    // MARK: - Actions

    private func exportSeason() {
        guard let season = store.activeSeason else { return }
        do {
            exportURL = try store.exportSeasonZip(season)
            isExporting = true
        } catch {
            showingExportError = error.localizedDescription
        }
    }

    private func deleteActiveSeason() {
        guard let season = store.activeSeason else { return }
        try? store.deleteSeason(season)
    }
}

#Preview {
    SettingsTabView()
        .environment(SeasonStore(fileManagerClient: .mock(), userDefaultsClient: .noop))
}
