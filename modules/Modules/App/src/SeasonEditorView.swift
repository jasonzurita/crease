import CRDesign
import CRModel
import SwiftUI

struct SeasonEditorView: View {
    @State private var viewModel: SeasonEditorViewModel
    @Environment(\.dismiss) private var dismiss
    private let store: SeasonStore
    @State private var errorMessage: String?
    @FocusState private var focusedField: FocusField?

    private enum FocusField { case teamName, seasonName }

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
            formRow(label: "Team Name", text: $viewModel.teamName, placeholder: "e.g. Eagles", field: .teamName)
            divider
            formRow(label: "Season", text: $viewModel.seasonName, placeholder: "e.g. Spring 2025", field: .seasonName)
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
                divider
                stepperRow(label: "Attack", value: attackCountBinding, range: 0 ... 10, unit: nil)
                divider
                stepperRow(label: "Midfield", value: midfieldCountBinding, range: 0 ... 10, unit: nil)
                divider
                stepperRow(label: "Defense", value: defenseCountBinding, range: 0 ... 10, unit: nil)
                divider
                positionTotalRow
            }
            .crSurfaceCard()
        }
    }

    private var positionTotalRow: some View {
        let counts = viewModel.gameFormatDefaults.effectivePositionCounts
        let total = counts.fieldTotal + 1
        let isValid = total == viewModel.gameFormatDefaults.playersPerSide
        return HStack {
            Text("Total on field")
                .foregroundStyle(Color.crTextSecondary)
            Spacer()
            Text("\(total) of \(viewModel.gameFormatDefaults.playersPerSide)")
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(isValid ? Color.crSuccess : Color.crDanger)
        }
        .padding()
    }

    private var attackCountBinding: Binding<Int> {
        Binding(
            get: { viewModel.gameFormatDefaults.effectivePositionCounts.attack },
            set: {
                var counts = viewModel.gameFormatDefaults.positionCounts ?? viewModel.gameFormatDefaults.effectivePositionCounts
                counts.attack = $0
                viewModel.gameFormatDefaults.positionCounts = counts
            }
        )
    }

    private var midfieldCountBinding: Binding<Int> {
        Binding(
            get: { viewModel.gameFormatDefaults.effectivePositionCounts.midfield },
            set: {
                var counts = viewModel.gameFormatDefaults.positionCounts ?? viewModel.gameFormatDefaults.effectivePositionCounts
                counts.midfield = $0
                viewModel.gameFormatDefaults.positionCounts = counts
            }
        )
    }

    private var defenseCountBinding: Binding<Int> {
        Binding(
            get: { viewModel.gameFormatDefaults.effectivePositionCounts.defense },
            set: {
                var counts = viewModel.gameFormatDefaults.positionCounts ?? viewModel.gameFormatDefaults.effectivePositionCounts
                counts.defense = $0
                viewModel.gameFormatDefaults.positionCounts = counts
            }
        )
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

    private func formRow(label: String, text: Binding<String>, placeholder: String, field: FocusField) -> some View {
        HStack {
            Text(label).foregroundStyle(Color.crTextPrimary)
            Spacer()
            TextField(placeholder, text: text)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(Color.crTextPrimary)
                .tint(Color.crAccent)
                .focused($focusedField, equals: field)
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture { focusedField = field }
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
