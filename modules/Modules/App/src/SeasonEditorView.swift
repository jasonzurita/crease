import CRDesign
import CRModel
import SwiftUI

struct SeasonEditorView: View {
    @State private var viewModel: SeasonEditorViewModel
    @Environment(\.dismiss) private var dismiss
    private let store: SeasonStore
    @State private var errorMessage: String?

    init(season: Season, store: SeasonStore) {
        _viewModel = State(initialValue: SeasonEditorViewModel(season: season))
        self.store = store
    }

    var body: some View {
        ZStack {
            Color.crBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    teamInfoSection
                    formatSection
                }
                .padding()
            }
        }
        .navigationTitle("Edit Season")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.crSurface, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Save") { save() }
                    .foregroundStyle(viewModel.isValid ? Color.crAccent : Color.crTextSecondary)
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isValid)
            }
        }
        .alert("Could Not Save", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var teamInfoSection: some View {
        VStack(spacing: 0) {
            formRow(label: "Team Name", text: $viewModel.teamName, placeholder: "e.g. Eagles")
            divider
            formRow(label: "Season", text: $viewModel.seasonName, placeholder: "e.g. Spring 2025")
        }
        .crSurfaceCard()
    }

    private var formatSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Game Format Defaults")
                .font(.subheadline)
                .foregroundStyle(Color.crTextSecondary)
                .padding(.horizontal, 4)
            VStack(spacing: 0) {
                stepperRow(label: "Quarters", value: $viewModel.gameFormatDefaults.quarters, range: 1 ... 8, unit: nil)
                divider
                stepperRow(label: "Quarter Length", value: $viewModel.gameFormatDefaults.quarterLengthMinutes, range: 5 ... 20, unit: "min")
                divider
                stepperRow(label: "Players Per Side", value: $viewModel.gameFormatDefaults.playersPerSide, range: 5 ... 11, unit: nil)
            }
            .crSurfaceCard()
        }
    }

    private func save() {
        do {
            try viewModel.save(in: store)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
            .padding(.horizontal)
    }

    private func formRow(label: String, text: Binding<String>, placeholder: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Color.crTextPrimary)
            Spacer()
            TextField(placeholder, text: text)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(Color.crTextPrimary)
                .tint(Color.crAccent)
        }
        .padding()
    }

    private func stepperRow(label: String, value: Binding<Int>, range: ClosedRange<Int>, unit: String?) -> some View {
        HStack {
            Text(label).foregroundStyle(Color.crTextPrimary)
            Spacer()
            Text(unit.map { "\(value.wrappedValue) \($0)" } ?? "\(value.wrappedValue)")
                .font(.body.monospacedDigit())
                .foregroundStyle(Color.crTextPrimary)
                .frame(minWidth: 52, alignment: .trailing)
            Stepper("", value: value, in: range)
                .tint(Color.crAccent)
                .labelsHidden()
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        SeasonEditorView(
            season: Season(
                id: UUID(),
                teamName: "Eagles",
                seasonName: "Spring 2025",
                gameFormatDefaults: .default,
                createdAt: Date()
            ),
            store: SeasonStore(fileManagerClient: .mock(), userDefaultsClient: .noop)
        )
    }
}
