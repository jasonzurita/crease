import CRModel
import Foundation

@Observable
@MainActor
final class LiveGameViewModel {
    let game: Game
    let players: [Player]

    private(set) var isRunning = false
    private(set) var slotSecondsRemaining: Int
    private(set) var currentSlotIndex: Int = 0
    private(set) var isRotationDue = false

    var usScore: Int = 0
    var themScore: Int = 0
    var opponentGroundBalls: Int = 0
    private(set) var groundBalls: [UUID: Int] = [:]

    /// Live lineup override for the current slot (nil = use plan's slot assignments).
    /// Reset to nil on each rotation advance so the next slot starts from the plan.
    private(set) var liveAssignments: [PositionAssignment]?

    /// Actual seconds each player has been on the field this game, accumulated per tick.
    private(set) var playingTimeSeconds: [UUID: Int] = [:]

    /// Pending emergency swap state
    private(set) var pendingSwapBenchPlayerID: UUID?

    private var timerTask: Task<Void, Never>?

    init(game: Game, players: [Player]) {
        self.game = game
        self.players = players
        slotSecondsRemaining = Self.slotSeconds(for: game)
        let presentIDs = Set(game.attendance.filter { $0.isPresent }.map { $0.id })
        for player in players where presentIDs.contains(player.id) {
            groundBalls[player.id] = 0
        }
    }

    private static func slotSeconds(for game: Game) -> Int {
        switch game.rotationStyle {
        case .byQuarter: return game.format.quarterLengthMinutes * 60
        case let .byTimeInterval(mins): return mins * 60
        }
    }

    var slotDurationSeconds: Int {
        Self.slotSeconds(for: game)
    }

    var totalSlots: Int {
        game.rotationPlan?.slots.count ?? 0
    }

    var currentSlot: RotationSlot? {
        guard let slots = game.rotationPlan?.slots, currentSlotIndex < slots.count else { return nil }
        return slots[currentSlotIndex]
    }

    var isLastSlot: Bool {
        currentSlotIndex >= totalSlots - 1
    }

    var currentQuarter: Int {
        currentSlot?.quarter ?? (currentSlotIndex + 1)
    }

    /// Effective field assignments for the current slot — respects live swaps.
    var currentFieldAssignments: [PositionAssignment] {
        liveAssignments ?? currentSlot?.assignments ?? []
    }

    var currentFieldPlayerIDs: Set<UUID> {
        Set(currentFieldAssignments.map(\.playerID))
    }

    /// Present players not currently on the field.
    var currentBenchPlayerIDs: [UUID] {
        presentPlayers.map(\.id).filter { !currentFieldPlayerIDs.contains($0) }
    }

    /// Field player objects for the swap confirmation dialog.
    var currentFieldPlayers: [Player] {
        currentFieldAssignments.compactMap { assignment in
            players.first { $0.id == assignment.playerID }
        }
    }

    var pendingSwapBenchPlayerName: String {
        guard let id = pendingSwapBenchPlayerID else { return "" }
        return players.first { $0.id == id }?.name ?? "?"
    }

    var presentPlayers: [Player] {
        let presentIDs = Set(game.attendance.filter { $0.isPresent }.map { $0.id })
        return players.filter { presentIDs.contains($0.id) }.sorted { $0.name < $1.name }
    }

    // MARK: - Timer control

    func startStop() {
        if isRunning { pause() } else { start() }
    }

    private func start() {
        isRunning = true
        timerTask = Task { @MainActor [weak self] in
            while let self, self.isRunning, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                self.tick()
            }
        }
    }

    func pause() {
        isRunning = false
        timerTask?.cancel()
        timerTask = nil
    }

    private func tick() {
        if slotSecondsRemaining > 0 {
            slotSecondsRemaining -= 1
            for assignment in currentFieldAssignments {
                playingTimeSeconds[assignment.playerID, default: 0] += 1
            }
            if slotSecondsRemaining == 0, !isLastSlot {
                isRotationDue = true
            }
        }
    }

    // MARK: - Rotation

    func advanceRotation() {
        guard !isLastSlot else { return }
        liveAssignments = nil
        currentSlotIndex += 1
        slotSecondsRemaining = slotDurationSeconds
        isRotationDue = false
    }

    // MARK: - Live emergency swap

    func initiateLiveSwap(benchPlayerID: UUID) {
        pendingSwapBenchPlayerID = benchPlayerID
    }

    func confirmLiveSwap(replacingPlayerID: UUID) {
        guard let benchPlayerID = pendingSwapBenchPlayerID else { return }
        var assignments = currentFieldAssignments
        guard let idx = assignments.firstIndex(where: { $0.playerID == replacingPlayerID }) else { return }
        assignments[idx] = PositionAssignment(
            position: assignments[idx].position,
            playerID: benchPlayerID,
            isLocked: false
        )
        liveAssignments = assignments
        pendingSwapBenchPlayerID = nil
    }

    func cancelLiveSwap() {
        pendingSwapBenchPlayerID = nil
    }

    // MARK: - Ground balls

    func incrementGroundBalls(for playerID: UUID) {
        groundBalls[playerID, default: 0] += 1
    }

    func decrementGroundBalls(for playerID: UUID) {
        groundBalls[playerID] = max(0, (groundBalls[playerID] ?? 0) - 1)
    }

    // MARK: - Stats output

    func buildStats() -> GameStats {
        let playerStats = presentPlayers.map { player in
            PlayerStat(
                playerID: player.id,
                goals: 0,
                groundBalls: groundBalls[player.id] ?? 0,
                playingTimeSeconds: playingTimeSeconds[player.id] ?? 0
            )
        }
        return GameStats(
            usScore: usScore,
            themScore: themScore,
            playerStats: playerStats,
            opponentGroundBalls: opponentGroundBalls
        )
    }

    // MARK: - Formatting

    func formattedTime(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
