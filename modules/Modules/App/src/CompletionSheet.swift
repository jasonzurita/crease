import CRDesign
import CRModel
import SwiftUI

struct CompletionSheet: View {
    @State private var viewModel: CompletionSheetViewModel
    let presentPlayers: [Player]
    let onComplete: (GameStats?) -> Void
    @Environment(\.dismiss) private var dismiss

    init(presentPlayers: [Player], onComplete: @escaping (GameStats?) -> Void) {
        self.presentPlayers = presentPlayers
        self.onComplete = onComplete
        _viewModel = State(initialValue: CompletionSheetViewModel(players: presentPlayers))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.crBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        scoreSection
                        if !presentPlayers.isEmpty { playerStatsSection }
                        opponentSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Mark Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.crSurface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.crTextSecondary)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        onComplete(viewModel.makeStats())
                        dismiss()
                    }
                    .foregroundStyle(Color.crAccent)
                    .fontWeight(.semibold)
                    .accessibilityLabel("Complete game and save stats")
                }
            }
        }
    }

    // MARK: - Score

    @ViewBuilder
    private var scoreSection: some View {
        @Bindable var vm = viewModel
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Final Score")
            VStack(spacing: 0) {
                scoreRow(label: "Us", value: $vm.usScore)
                divider
                scoreRow(label: "Them", value: $vm.themScore)
            }
            .crSurfaceCard()
        }
    }

    private func scoreRow(label: String, value: Binding<Int>) -> some View {
        HStack {
            Text(label).foregroundStyle(Color.crTextPrimary)
            Spacer()
            Text("\(value.wrappedValue)")
                .font(.body.monospacedDigit())
                .foregroundStyle(Color.crTextPrimary)
                .frame(minWidth: 40, alignment: .trailing)
            Stepper("", value: value, in: 0 ... 99)
                .tint(Color.crAccent)
                .labelsHidden()
        }
        .padding()
    }

    // MARK: - Player Stats

    @ViewBuilder
    private var playerStatsSection: some View {
        @Bindable var vm = viewModel
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Player Stats (optional)")
            VStack(spacing: 0) {
                ForEach(Array(presentPlayers.enumerated()), id: \.element.id) { i, player in
                    if let idx = vm.playerStats.firstIndex(where: { $0.playerID == player.id }) {
                        playerStatRow(
                            player: player,
                            goals: $vm.playerStats[idx].goals,
                            groundBalls: $vm.playerStats[idx].groundBalls
                        )
                        if i < presentPlayers.count - 1 { divider }
                    }
                }
            }
            .crSurfaceCard()
        }
    }

    private func playerStatRow(player: Player, goals: Binding<Int>, groundBalls: Binding<Int>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.subheadline)
                    .foregroundStyle(Color.crTextPrimary)
                Text("#\(player.jerseyNumber)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Color.crTextSecondary)
            }
            Spacer()
            HStack(spacing: 20) {
                statCounter(label: "Goals", abbrev: "G", value: goals)
                statCounter(label: "Ground Balls", abbrev: "GB", value: groundBalls)
            }
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(player.name): goals and ground balls")
    }

    private func statCounter(label: String, abbrev: String, value: Binding<Int>) -> some View {
        VStack(spacing: 4) {
            Text(abbrev)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.crTextSecondary)
            HStack(spacing: 6) {
                Button {
                    if value.wrappedValue > 0 { value.wrappedValue -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(Color.crTextSecondary)
                }
                .accessibilityLabel("Decrease \(label)")
                Text("\(value.wrappedValue)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Color.crTextPrimary)
                    .frame(minWidth: 20)
                Button {
                    value.wrappedValue += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.crAccent)
                }
                .accessibilityLabel("Increase \(label)")
            }
        }
    }

    // MARK: - Opponent

    @ViewBuilder
    private var opponentSection: some View {
        @Bindable var vm = viewModel
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Opponent Stats")
            HStack {
                Text("Ground Balls").foregroundStyle(Color.crTextPrimary)
                Spacer()
                Text("\(vm.opponentGroundBalls)")
                    .font(.body.monospacedDigit())
                    .foregroundStyle(Color.crTextPrimary)
                    .frame(minWidth: 40, alignment: .trailing)
                Stepper("", value: $vm.opponentGroundBalls, in: 0 ... 99)
                    .tint(Color.crAccent)
                    .labelsHidden()
            }
            .padding()
            .crSurfaceCard()
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.crTextSecondary)
            .padding(.horizontal, 4)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
            .padding(.horizontal)
    }
}

#Preview {
    CompletionSheet(presentPlayers: [], onComplete: { _ in })
}
