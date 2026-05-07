import CRDesign
import CRModel
import SwiftUI

struct LineupCardOptionsSheet: View {
    @Bindable var viewModel: RotationOutputViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var shareImage: UIImage?
    @State private var isSharing = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.crBackground.ignoresSafeArea()
                VStack(spacing: 24) {
                    cardPreview
                    optionsSection
                    shareButton
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Lineup Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.crSurface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.crTextSecondary)
                }
            }
        }
        .sheet(isPresented: $isSharing) {
            if let image = shareImage {
                ActivityView(items: [image])
            }
        }
    }

    private var cardPreview: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LineupCardView(
                game: viewModel.game,
                players: viewModel.players,
                teamName: viewModel.teamName,
                includesPlayingTime: viewModel.lineupCardIncludesPlayingTime,
                slotDurationMinutes: viewModel.slotDurationMinutes
            )
            .scaleEffect(0.75, anchor: .top)
            .frame(height: 280)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var optionsSection: some View {
        Toggle(isOn: $viewModel.lineupCardIncludesPlayingTime) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Include Playing Time")
                    .foregroundStyle(Color.crTextPrimary)
                Text("Shows a bar chart of each player's projected minutes")
                    .font(.caption)
                    .foregroundStyle(Color.crTextSecondary)
            }
        }
        .tint(Color.crAccent)
        .padding()
        .crSurfaceCard()
    }

    private var shareButton: some View {
        Button {
            generateAndShare()
        } label: {
            Label("Share Lineup Card", systemImage: "square.and.arrow.up")
                .font(.headline)
                .foregroundStyle(Color.crBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.crAccent)
                .clipShape(RoundedRectangle(cornerRadius: 28))
        }
        .accessibilityLabel("Share lineup card as image")
    }

    private func generateAndShare() {
        let card = LineupCardView(
            game: viewModel.game,
            players: viewModel.players,
            teamName: viewModel.teamName,
            includesPlayingTime: viewModel.lineupCardIncludesPlayingTime,
            slotDurationMinutes: viewModel.slotDurationMinutes
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        shareImage = renderer.uiImage
        isSharing = true
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
    LineupCardOptionsSheet(viewModel: vm)
}
