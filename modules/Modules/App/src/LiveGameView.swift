import CRDesign
import CRModel
import SwiftUI

struct LiveGameView: View {
    @State private var viewModel: LiveGameViewModel
    let onEndGame: (GameStats) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showDoneConfirmation = false
    @State private var showSwapConfirmation = false

    private static let orderedPositions: [Position] = [.goalie, .attack, .midfield, .defense]

    init(game: Game, players: [Player], onEndGame: @escaping (GameStats) -> Void) {
        _viewModel = State(initialValue: LiveGameViewModel(game: game, players: players))
        self.onEndGame = onEndGame
    }

    private var isQuarterRotation: Bool {
        if case .byQuarter = viewModel.game.rotationStyle { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.crBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        gameClockSection
                        scoreSection
                        rotationSection
                        groundBallsSection
                    }
                    .padding()
                    .padding(.bottom, viewModel.isRotationDue ? 100 : 20)
                }
                if viewModel.isRotationDue {
                    rotationDueBanner
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.isRotationDue)
            .navigationTitle("Live — vs. \(viewModel.game.opponent)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.crSurface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        viewModel.pause()
                        showDoneConfirmation = true
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.crAccent)
                }
            }
            .alert("End Game?", isPresented: $showDoneConfirmation) {
                Button("End Game", role: .destructive) {
                    onEndGame(viewModel.buildStats())
                    dismiss()
                }
                Button("Cancel", role: .cancel) {
                    viewModel.startStop()
                }
            } message: {
                Text("This will save your stats and mark the game as complete.")
            }
            .confirmationDialog(
                "Swap in \(viewModel.pendingSwapBenchPlayerName)",
                isPresented: $showSwapConfirmation,
                titleVisibility: .visible
            ) {
                ForEach(viewModel.currentFieldPlayers, id: \.id) { player in
                    Button("Replace \(player.name)") {
                        viewModel.confirmLiveSwap(replacingPlayerID: player.id)
                    }
                }
                Button("Cancel", role: .cancel) {
                    viewModel.cancelLiveSwap()
                }
            }
        }
    }

    // MARK: - Game Clock

    private var gameClockSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("GAME CLOCK")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.crTextSecondary)
                    .tracking(1.2)
                Spacer()
                Text("Q\(viewModel.currentQuarter) of \(viewModel.game.format.quarters)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.crAccent)
            }
            Text(viewModel.formattedTime(viewModel.slotSecondsRemaining))
                .font(.system(size: 58, weight: .thin, design: .monospaced))
                .foregroundStyle(Color.crTextPrimary)
                .monospacedDigit()
            Button {
                viewModel.startStop()
            } label: {
                Label(
                    viewModel.isRunning ? "Pause" : "Start",
                    systemImage: viewModel.isRunning ? "pause.circle.fill" : "play.circle.fill"
                )
                .font(.title3.weight(.semibold))
                .foregroundStyle(viewModel.isRunning ? Color.crTextSecondary : Color.crAccent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .crSurfaceCard()
    }

    // MARK: - Score

    private var scoreSection: some View {
        VStack(spacing: 0) {
            Text("SCORE")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.crTextSecondary)
                .tracking(1.2)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, 8)
            Rectangle()
                .fill(Color.crTextSecondary.opacity(0.1))
                .frame(height: 1)
            HStack(spacing: 0) {
                scoreColumn(label: "US", value: $viewModel.usScore)
                Rectangle()
                    .fill(Color.crTextSecondary.opacity(0.2))
                    .frame(width: 1)
                    .padding(.vertical, 16)
                scoreColumn(label: "THEM", value: $viewModel.themScore)
            }
        }
        .crSurfaceCard()
    }

    private func scoreColumn(label: String, value: Binding<Int>) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.crTextSecondary)
                .tracking(1.5)
            Text("\(value.wrappedValue)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(Color.crTextPrimary)
                .monospacedDigit()
                .frame(minWidth: 68)
            HStack(spacing: 24) {
                Button {
                    if value.wrappedValue > 0 { value.wrappedValue -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundStyle(value.wrappedValue > 0 ? Color.crTextSecondary : Color.crTextSecondary.opacity(0.3))
                }
                .disabled(value.wrappedValue == 0)
                Button {
                    value.wrappedValue += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.crAccent)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }

    // MARK: - Current Rotation

    private var rotationSectionLabel: String {
        isQuarterRotation
            ? "Quarter \(viewModel.currentSlotIndex + 1) of \(viewModel.totalSlots)"
            : "Rotation \(viewModel.currentSlotIndex + 1) of \(viewModel.totalSlots)"
    }

    private var rotationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(rotationSectionLabel)
            if viewModel.currentSlot != nil {
                rotationCard
            } else {
                Text("No rotation plan")
                    .foregroundStyle(Color.crTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .crSurfaceCard()
            }
        }
    }

    private var rotationCard: some View {
        VStack(spacing: 0) {
            // Field positions — uses currentFieldAssignments so live swaps are reflected.
            ForEach(Array(Self.orderedPositions.enumerated()), id: \.element) { index, position in
                let assignments = viewModel.currentFieldAssignments.filter { $0.position == position }
                if !assignments.isEmpty {
                    if index > 0 { divider }
                    HStack(alignment: .top) {
                        Text(position.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.crTextSecondary)
                            .frame(width: 64, alignment: .leading)
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(assignments, id: \.playerID) { assignment in
                                let player = viewModel.players.first { $0.id == assignment.playerID }
                                HStack(spacing: 6) {
                                    if let jersey = player?.jerseyNumber {
                                        Text("#\(jersey)")
                                            .font(.caption2.monospacedDigit())
                                            .foregroundStyle(Color.crTextSecondary)
                                            .frame(width: 28, alignment: .leading)
                                    }
                                    Text(player?.name ?? "?")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.crTextPrimary)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }

            // Bench — players present but not in the current field lineup.
            if !viewModel.currentBenchPlayerIDs.isEmpty {
                benchSection
            }
        }
        .crSurfaceCard()
    }

    private var benchSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            divider
            HStack {
                Text("BENCH")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.crTextSecondary)
                    .tracking(1.2)
                Spacer()
                Text("Tap ↑ to swap in")
                    .font(.caption2)
                    .foregroundStyle(Color.crTextSecondary.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 6)

            ForEach(Array(viewModel.currentBenchPlayerIDs.enumerated()), id: \.element) { idx, playerID in
                let player = viewModel.players.first { $0.id == playerID }
                if idx > 0 {
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                }
                HStack(spacing: 10) {
                    if let jersey = player?.jerseyNumber {
                        Text("#\(jersey)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(Color.crTextSecondary)
                            .frame(width: 28, alignment: .leading)
                    }
                    Text(player?.name ?? "?")
                        .font(.subheadline)
                        .foregroundStyle(Color.crTextSecondary)
                    Spacer()
                    Button {
                        viewModel.initiateLiveSwap(benchPlayerID: playerID)
                        showSwapConfirmation = true
                    } label: {
                        Label("Swap In", systemImage: "arrow.up.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.crAccent)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Ground Balls

    private var groundBallsSection: some View {
        let fieldPlayers = viewModel.presentPlayers.filter { viewModel.currentFieldPlayerIDs.contains($0.id) }
        let benchPlayers = viewModel.presentPlayers.filter { !viewModel.currentFieldPlayerIDs.contains($0.id) }
        let ordered = fieldPlayers + benchPlayers

        return VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Ground Balls")
            VStack(spacing: 0) {
                opponentGBRow
                if !ordered.isEmpty {
                    divider
                }
                ForEach(Array(ordered.enumerated()), id: \.element.id) { index, player in
                    if index > 0 { divider }
                    groundBallRow(player: player, isOnField: viewModel.currentFieldPlayerIDs.contains(player.id))
                }
            }
            .crSurfaceCard()
        }
    }

    private func groundBallRow(player: Player, isOnField: Bool) -> some View {
        let count = viewModel.groundBalls[player.id] ?? 0
        return HStack(spacing: 12) {
            PlayerAvatarView(player: player, size: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text(player.name)
                    .foregroundStyle(isOnField ? Color.crTextPrimary : Color.crTextSecondary)
                    .font(.subheadline)
                Text("#\(player.jerseyNumber)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Color.crTextSecondary)
            }
            Spacer()
            counterControl(
                count: count,
                onDecrement: { viewModel.decrementGroundBalls(for: player.id) },
                onIncrement: { viewModel.incrementGroundBalls(for: player.id) }
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var opponentGBRow: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.crDanger.opacity(0.2))
                    .frame(width: 42, height: 42)
                Image(systemName: "person.fill.xmark")
                    .font(.subheadline)
                    .foregroundStyle(Color.crDanger)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("OPPONENT")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.crDanger)
                    .tracking(1.2)
                Text("Ground Balls")
                    .font(.caption)
                    .foregroundStyle(Color.crTextSecondary)
            }
            Spacer()
            HStack(spacing: 16) {
                Button {
                    if viewModel.opponentGroundBalls > 0 { viewModel.opponentGroundBalls -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(viewModel.opponentGroundBalls > 0 ? Color.crDanger.opacity(0.8) : Color.crTextSecondary.opacity(0.3))
                }
                .disabled(viewModel.opponentGroundBalls == 0)
                Text("\(viewModel.opponentGroundBalls)")
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color.crDanger)
                    .frame(minWidth: 32, alignment: .center)
                Button {
                    viewModel.opponentGroundBalls += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.crDanger)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.crDanger.opacity(0.1))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.crDanger)
                .frame(width: 3)
        }
    }

    private func counterControl(count: Int, onDecrement: @escaping () -> Void, onIncrement: @escaping () -> Void) -> some View {
        HStack(spacing: 16) {
            Button(action: onDecrement) {
                Image(systemName: "minus.circle")
                    .font(.title3)
                    .foregroundStyle(count > 0 ? Color.crTextSecondary : Color.crTextSecondary.opacity(0.3))
            }
            .disabled(count == 0)
            Text("\(count)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(Color.crTextPrimary)
                .frame(minWidth: 28, alignment: .center)
            Button(action: onIncrement) {
                Image(systemName: "plus.circle")
                    .font(.title3)
                    .foregroundStyle(Color.crAccent)
            }
        }
    }

    // MARK: - Rotation Due Banner

    private var rotationDueBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.badge.fill")
                .font(.title3)
                .foregroundStyle(Color.crWarning)
            VStack(alignment: .leading, spacing: 2) {
                Text(isQuarterRotation ? "Quarter Ended" : "Rotation Due")
                    .font(.headline)
                    .foregroundStyle(Color.crTextPrimary)
                Text(viewModel.isLastSlot
                    ? "Final rotation is active"
                    : isQuarterRotation
                    ? "Tap to start Q\(viewModel.currentSlotIndex + 2)"
                    : "Sub in the next group")
                    .font(.caption)
                    .foregroundStyle(Color.crTextSecondary)
            }
            Spacer()
            if !viewModel.isLastSlot {
                Button {
                    withAnimation { viewModel.advanceRotation() }
                } label: {
                    Text(isQuarterRotation ? "Start Q\(viewModel.currentSlotIndex + 2)" : "Next")
                        .font(.headline)
                        .foregroundStyle(Color.crBackground)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.crAccent)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color.crSurface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.crWarning.opacity(0.6))
                .frame(height: 2)
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
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
    LiveGameView(
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
        onEndGame: { _ in }
    )
}
