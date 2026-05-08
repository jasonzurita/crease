import CRDesign
import CRModel
import PhotosUI
import SwiftUI
import UIKit

public struct PlayerFormView: View {
    @State private var viewModel: PlayerFormViewModel
    @State private var errorMessage: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: FocusField?

    private let store: SeasonStore
    private let title: String

    private enum FocusField { case name, jerseyNumber }

    public init(store: SeasonStore, mode: PlayerFormViewModel.Mode) {
        self.store = store
        _viewModel = State(initialValue: PlayerFormViewModel(mode: mode))
        switch mode {
        case .add: title = "Add Player"
        case .edit: title = "Edit Player"
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.crBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        avatarSection
                        identitySection
                        positionsSection
                        tierSection
                    }
                    .padding()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.crSurface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.crAccent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { handleSave() }
                        .foregroundStyle(viewModel.isValid ? Color.crAccent : Color.crAccent.opacity(0.4))
                        .disabled(!viewModel.isValid)
                }
            }
        }
        .alert("Could Not Save Player", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .onChange(of: selectedPhotoItem) { _, item in
            Task {
                guard let item else { return }
                if let data = try? await item.loadTransferable(type: Data.self),
                   let compressed = compressImage(data) {
                    viewModel.avatarImageData = compressed
                }
            }
        }
    }

    private var avatarSection: some View {
        VStack(spacing: 12) {
            let previewPlayer = Player(
                id: UUID(),
                name: viewModel.name.isEmpty ? "?" : viewModel.name,
                jerseyNumber: Int(viewModel.jerseyNumber) ?? 0,
                positions: [],
                tier: .developing,
                avatarImageData: viewModel.avatarImageData
            )
            PlayerAvatarView(player: previewPlayer, size: 80)

            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Choose Photo", systemImage: "photo")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.crAccent)
                }

                if viewModel.avatarImageData != nil {
                    Button {
                        viewModel.avatarImageData = nil
                        selectedPhotoItem = nil
                    } label: {
                        Label("Remove", systemImage: "xmark.circle")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.crTextSecondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var identitySection: some View {
        VStack(spacing: 0) {
            nameRow
            divider
            numberRow
        }
        .crSurfaceCard()
    }

    private var nameRow: some View {
        HStack {
            Text("Name")
                .foregroundStyle(Color.crTextPrimary)
            Spacer()
            TextField("e.g. Alex Johnson", text: $viewModel.name)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(Color.crTextPrimary)
                .tint(Color.crAccent)
                .focused($focusedField, equals: .name)
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture { focusedField = .name }
    }

    private var numberRow: some View {
        HStack {
            Text("Jersey #")
                .foregroundStyle(Color.crTextPrimary)
            Spacer()
            TextField("#", text: $viewModel.jerseyNumber)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(Color.crTextPrimary)
                .tint(Color.crAccent)
                .font(.body.monospacedDigit())
                .focused($focusedField, equals: .jerseyNumber)
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture { focusedField = .jerseyNumber }
    }

    private var positionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Position Eligibility")
                .font(.subheadline)
                .foregroundStyle(Color.crTextSecondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(Position.allCases.enumerated()), id: \.element) { index, position in
                    if index > 0 { divider }
                    positionToggleRow(position)
                }
            }
            .crSurfaceCard()
        }
    }

    private func positionToggleRow(_ position: Position) -> some View {
        HStack {
            Text(position.rawValue)
                .foregroundStyle(Color.crTextPrimary)
            Spacer()
            if viewModel.positions.contains(position) {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.crAccent)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            if viewModel.positions.contains(position) {
                viewModel.positions.remove(position)
            } else {
                viewModel.positions.insert(position)
            }
        }
    }

    private var tierSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Skill Tier")
                .font(.subheadline)
                .foregroundStyle(Color.crTextSecondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(Tier.allCases.enumerated()), id: \.element) { index, tier in
                    if index > 0 { divider }
                    tierRow(tier)
                }
            }
            .crSurfaceCard()
        }
    }

    private func tierRow(_ tier: Tier) -> some View {
        HStack {
            Text(tier.rawValue)
                .foregroundStyle(Color.crTextPrimary)
            Spacer()
            if viewModel.tier == tier {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.crAccent)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture { viewModel.tier = tier }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
            .padding(.horizontal)
    }

    private func handleSave() {
        do {
            try viewModel.save(in: store)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func compressImage(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let maxDimension: CGFloat = 300
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height, 1)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        return resized.jpegData(compressionQuality: 0.7)
    }
}

#Preview("Add Player") {
    PlayerFormView(
        store: SeasonStore(fileManagerClient: .mock(), userDefaultsClient: .noop),
        mode: .add
    )
}

#Preview("Edit Player") {
    PlayerFormView(
        store: SeasonStore(fileManagerClient: .mock(), userDefaultsClient: .noop),
        mode: .edit(Player(
            id: UUID(),
            name: "Alex Johnson",
            jerseyNumber: 12,
            positions: [.midfield, .attack],
            tier: .strong
        ))
    )
}
