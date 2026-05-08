import CRModel
import Foundation

@Observable
@MainActor
final class LiveGameViewModel {
    let game: Game
    let players: [Player]

    private(set) var isRunning = false
    private(set) var gameSecondsRemaining: Int
    private(set) var slotSecondsRemaining: Int
    private(set) var currentSlotIndex: Int = 0
    private(set) var isRotationDue = false

    var usScore: Int = 0
    var themScore: Int = 0
    var opponentGroundBalls: Int = 0
    private(set) var groundBalls: [UUID: Int] = [:]

    private var timerTask: Task<Void, Never>?

    init(game: Game, players: [Player]) {
        self.game = game
        self.players = players
        gameSecondsRemaining = game.format.quarters * game.format.quarterLengthMinutes * 60
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

    var nextSlot: RotationSlot? {
        guard let slots = game.rotationPlan?.slots, currentSlotIndex + 1 < slots.count else { return nil }
        return slots[currentSlotIndex + 1]
    }

    var isLastSlot: Bool {
        currentSlotIndex >= totalSlots - 1
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
        if gameSecondsRemaining > 0 {
            gameSecondsRemaining -= 1
        }
        if slotSecondsRemaining > 0 {
            slotSecondsRemaining -= 1
            if slotSecondsRemaining == 0, !isLastSlot {
                isRotationDue = true
            }
        }
    }

    // MARK: - Rotation

    func advanceRotation() {
        guard !isLastSlot else { return }
        currentSlotIndex += 1
        slotSecondsRemaining = slotDurationSeconds
        isRotationDue = false
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
            PlayerStat(playerID: player.id, goals: 0, groundBalls: groundBalls[player.id] ?? 0)
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
