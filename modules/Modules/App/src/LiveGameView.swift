import CRDesign
import CRModel
import SwiftUI

struct LiveGameView: View {
    @State private var viewModel: LiveGameViewModel
    let onSaveStats: (GameStats) -> Void
    @Environment(\.dismiss) private var dismiss

    private static let orderedPositions: [Position] = [.goalie, .attack, .midfield, .defense]

    init(game: Game, players: [Player], onSaveStats: @escaping (GameStats) -> Void) {
        _viewModel = State(initialValue: LiveGameViewModel(game: game, players: players))
        self.onSaveStats = onSaveStats
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
                        onSaveStats(viewModel.buildStats())
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.crAccent)
                }
            }
        }
    }

    // MARK: - Game Clock

    private var gameClockSection: some View {
        VStack(spacing: 12) {
            Text(viewModel.formattedTime(viewModel.gameSecondsRemaining))
                .font(.system(size: 72, weight: .thin, design: .monospaced))
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
        .padding(.vertical, 24)
        .crSurfaceCard()
    }

    // MARK: - Score

    private var scoreSection: some View {
        HStack(spacing: 0) {
            scoreColumn(label: "US", value: $viewModel.usScore)
            Rectangle()
                .fill(Color.crTextSecondary.opacity(0.2))
                .frame(width: 1)
                .padding(.vertical, 16)
            scoreColumn(label: "THEM", value: $viewModel.themScore)
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
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(Color.crTextPrimary)
                .monospacedDigit()
                .frame(minWidth: 80)
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
        .padding(.vertical, 20)
    }

    // MARK: - Current Rotation

    private var rotationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionLabel("Rotation \(viewModel.currentSlotIndex + 1) of \(viewModel.totalSlots)")
                Spacer()
                Text(viewModel.formattedTime(viewModel.slotSecondsRemaining))
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(
                        viewModel.slotSecondsRemaining < 60 && viewModel.slotSecondsRemaining > 0
                            ? Color.crWarning
                            : Color.crTextSecondary
                    )
            }
            if let slot = viewModel.currentSlot {
                rotationCard(slot: slot)
            } else {
                Text("No rotation plan")
                    .foregroundStyle(Color.crTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .crSurfaceCard()
            }
        }
    }

    private func rotationCard(slot: RotationSlot) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(Self.orderedPositions.enumerated()), id: \.element) { index, position in
                let assignments = slot.assignments.filter { $0.position == position }
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
        }
        .crSurfaceCard()
    }

    // MARK: - Ground Balls

    private var groundBallsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Ground Balls")
            VStack(spacing: 0) {
                ForEach(Array(viewModel.presentPlayers.enumerated()), id: \.element.id) { index, player in
                    if index > 0 { divider }
                    groundBallRow(player: player)
                }
                divider
                opponentGBRow
            }
            .crSurfaceCard()
        }
    }

    private func groundBallRow(player: Player) -> some View {
        let count = viewModel.groundBalls[player.id] ?? 0
        return HStack(spacing: 12) {
            PlayerAvatarView(player: player, size: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text(player.name)
                    .foregroundStyle(Color.crTextPrimary)
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
        HStack {
            Image(systemName: "person.fill.xmark")
                .font(.caption)
                .foregroundStyle(Color.crDanger)
                .frame(width: 36)
            Text("Opponent")
                .foregroundStyle(Color.crTextSecondary)
            Spacer()
            counterControl(
                count: viewModel.opponentGroundBalls,
                onDecrement: { if viewModel.opponentGroundBalls > 0 { viewModel.opponentGroundBalls -= 1 } },
                onIncrement: { viewModel.opponentGroundBalls += 1 }
            )
        }
        .padding()
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
                Text("Rotation Due")
                    .font(.headline)
                    .foregroundStyle(Color.crTextPrimary)
                Text(viewModel.isLastSlot ? "Final rotation is active" : "Sub in the next group")
                    .font(.caption)
                    .foregroundStyle(Color.crTextSecondary)
            }
            Spacer()
            if !viewModel.isLastSlot {
                Button {
                    withAnimation { viewModel.advanceRotation() }
                } label: {
                    Text("Next")
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
        onSaveStats: { _ in }
    )
}
