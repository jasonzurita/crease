import CRDesign
import SwiftUI

public struct SeasonCreationView: View {
    @State private var viewModel = SeasonCreationViewModel()
    @State private var errorMessage: String?

    private let store: SeasonStore
    private let onCreated: () -> Void

    public init(store: SeasonStore, onCreated: @escaping () -> Void) {
        self.store = store
        self.onCreated = onCreated
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.crBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        teamInfoSection
                        formatSection
                        createButton
                    }
                    .padding()
                }
            }
            .navigationBarBackButtonHidden(true)
        }
        .alert("Could Not Create Season", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var headerSection: some View {
        Text("Let's get your\nseason set up.")
            .font(.system(.largeTitle, design: .rounded, weight: .bold))
            .foregroundStyle(Color.crTextPrimary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
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
                divider
                HStack {
                    Text("Mid-Quarter Subs")
                        .foregroundStyle(Color.crTextPrimary)
                    Spacer()
                    Toggle("", isOn: $viewModel.gameFormatDefaults.midQuarterSubsEnabled)
                        .tint(Color.crAccent)
                        .labelsHidden()
                }
                .padding()
            }
            .crSurfaceCard()
        }
    }

    private var createButton: some View {
        Button {
            do {
                try viewModel.create(in: store)
                onCreated()
            } catch {
                errorMessage = error.localizedDescription
            }
        } label: {
            Text("Create Season")
                .font(.headline)
                .foregroundStyle(Color.crBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(viewModel.isValid ? Color.crAccent : Color.crAccent.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 28))
        }
        .disabled(!viewModel.isValid)
        .padding(.top, 8)
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

    private func stepperRow(label: String, value: Binding<Int>, range: ClosedRange<Int>, unit: String?) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(Color.crTextPrimary)
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
    SeasonCreationView(
        store: SeasonStore(fileManagerClient: .mock(), userDefaultsClient: .noop),
        onCreated: {}
    )
}
