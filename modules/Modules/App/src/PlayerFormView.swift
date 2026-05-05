import CRDesign
import CRModel
import SwiftUI

public struct PlayerFormView: View {
    @State private var viewModel: PlayerFormViewModel
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    private let store: SeasonStore
    private let title: String

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
    }

    private var identitySection: some View {
        VStack(spacing: 0) {
            formRow(label: "Name", text: $viewModel.name, placeholder: "e.g. Alex Johnson")
            divider
            numberRow
        }
        .crSurfaceCard()
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
        }
        .padding()
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

    private func formRow(label: String, text: Binding<String>, placeholder: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(Color.crTextPrimary)
            Spacer()
            TextField(placeholder, text: text)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(Color.crTextPrimary)
                .tint(Color.crAccent)
        }
        .padding()
    }

    private func handleSave() {
        do {
            try viewModel.save(in: store)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
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
