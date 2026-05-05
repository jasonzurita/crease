import CRDesign
import CRModel
import SwiftUI

public struct GameSetupView: View {
    @State private var viewModel: GameSetupViewModel
    private let store: SeasonStore
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?
    @State private var generatedGame: Game?

    public init(store: SeasonStore) {
        self.store = store
        _viewModel = State(initialValue: GameSetupViewModel(
            formatDefaults: store.activeSeason?.gameFormatDefaults ?? .default,
            players: store.players
        ))
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.crBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    stepIndicator
                        .padding(.top, 16)
                        .padding(.horizontal, 32)
                    stepContent
                    navigationButtons
                        .padding()
                }
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.crSurface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.crTextSecondary)
                }
            }
            .navigationDestination(item: $generatedGame) { game in
                RotationOutputView(
                    game: game,
                    players: store.players,
                    store: store,
                    showDoneButton: true
                )
            }
        }
        .alert("Could Not Create Game", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var stepTitle: String {
        switch viewModel.currentStep {
        case .details: "Game Details"
        case .attendance: "Attendance"
        case .options: "Format & Options"
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 0) {
            ForEach(GameSetupViewModel.Step.allCases, id: \.rawValue) { step in
                ZStack {
                    Circle()
                        .fill(
                            step.rawValue <= viewModel.currentStep.rawValue
                                ? Color.crAccent
                                : Color.crTextSecondary.opacity(0.3)
                        )
                        .frame(width: 28, height: 28)
                    Text("\(step.rawValue)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(
                            step.rawValue <= viewModel.currentStep.rawValue
                                ? Color.crBackground
                                : Color.crTextSecondary
                        )
                }
                if step != GameSetupViewModel.Step.allCases.last {
                    Rectangle()
                        .fill(
                            step.rawValue < viewModel.currentStep.rawValue
                                ? Color.crAccent
                                : Color.crTextSecondary.opacity(0.3)
                        )
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .details:
            GameDetailsView(viewModel: viewModel)
        case .attendance:
            AttendanceView(viewModel: viewModel, players: store.players)
        case .options:
            GameOptionsView(viewModel: viewModel, players: store.players)
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if viewModel.currentStep != .details {
                Button {
                    viewModel.goBack()
                } label: {
                    Text("Back")
                        .font(.headline)
                        .foregroundStyle(Color.crAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.crAccent.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                }
            }

            if viewModel.currentStep == .options {
                Button {
                    generatePlan()
                } label: {
                    Text("Generate Plan")
                        .font(.headline)
                        .foregroundStyle(Color.crBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.crAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                }
            } else {
                Button {
                    viewModel.goNext()
                } label: {
                    Text("Next")
                        .font(.headline)
                        .foregroundStyle(Color.crBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            viewModel.isCurrentStepValid
                                ? Color.crAccent
                                : Color.crTextSecondary.opacity(0.4)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                }
                .disabled(!viewModel.isCurrentStepValid)
            }
        }
    }

    private func generatePlan() {
        do {
            let game = try viewModel.createGame(in: store)
            try store.generatePlan(for: game)
            generatedGame = store.games.first { $0.id == game.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    GameSetupView(
        store: SeasonStore(fileManagerClient: .mock(), userDefaultsClient: .noop)
    )
}
