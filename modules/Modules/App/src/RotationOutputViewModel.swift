import CRModel
import Foundation
import RotationSolver

@Observable
@MainActor
final class RotationOutputViewModel {
    struct CellID: Hashable, Identifiable {
        let slotIndex: Int
        let position: Position
        var id: String {
            "\(slotIndex)-\(position.rawValue)"
        }
    }

    enum MinutesStatus { case met, near, violation }

    private(set) var game: Game
    let players: [Player]
    private let store: SeasonStore

    private(set) var selectedCell: CellID?
    var showBenchSwapSheet = false
    private var benchSwapTarget: CellID?
    private(set) var benchSwapCandidates: [Player] = []
    private(set) var cellOptionsTarget: CellID?
    var expandedBenchSlots: Set<Int> = []
    private var previousPlan: RotationPlan?
    private(set) var canUndo = false
    private(set) var hasManualChanges = false
    var showRegenerateWarning = false

    // Phase 7 — Lineup card
    var showLineupCardOptions = false
    var lineupCardIncludesPlayingTime = true

    // Phase 8 — Completion
    var showCompletionSheet = false
    private(set) var gameWasCompleted = false

    var teamName: String {
        store.activeSeason?.teamName ?? ""
    }

    init(game: Game, players: [Player], store: SeasonStore) {
        self.game = game
        self.players = players
        self.store = store
    }

    var plan: RotationPlan? {
        game.rotationPlan
    }

    var activeViolations: [Violation] {
        game.rotationPlan?.violations.filter { !$0.isDismissed } ?? []
    }

    var presentPlayers: [Player] {
        players.filter { player in
            game.attendance.first { $0.id == player.id }?.isPresent == true
        }
        .sorted { $0.name < $1.name }
    }

    // MARK: - Playing time

    var slotDurationMinutes: Int {
        switch game.rotationStyle {
        case .byQuarter: return game.format.quarterLengthMinutes
        case let .byTimeInterval(intervalMinutes): return intervalMinutes
        }
    }

    func projectedMinutes(for playerID: UUID) -> Int {
        guard let plan = game.rotationPlan else { return 0 }
        let slots = plan.slots.filter { slot in
            slot.assignments.contains { pa in
                pa.playerID == playerID &&
                    (pa.position != .goalie || game.fairnessTargets.goalieTimeCountsAsFieldTime)
            }
        }.count
        return slots * slotDurationMinutes
    }

    func minimumMinutes(for playerID: UUID) -> Int {
        guard let player = players.first(where: { $0.id == playerID }) else { return 0 }
        return game.fairnessTargets.minutes(for: player.tier)
    }

    func minutesStatus(for playerID: UUID) -> MinutesStatus {
        let projected = projectedMinutes(for: playerID)
        let minimum = minimumMinutes(for: playerID)
        if projected >= minimum { return .met }
        if projected >= minimum - 2 { return .near }
        return .violation
    }

    func minutesFraction(for playerID: UUID) -> Double {
        guard let plan = game.rotationPlan else { return 0 }
        let total = plan.slots.count * slotDurationMinutes
        guard total > 0 else { return 0 }
        return min(1.0, Double(projectedMinutes(for: playerID)) / Double(total))
    }

    // MARK: - Helpers

    func playerName(for id: UUID) -> String {
        players.first { $0.id == id }?.name ?? "?"
    }

    func isCellLocked(_ cell: CellID) -> Bool {
        guard let plan = game.rotationPlan, cell.slotIndex < plan.slots.count else { return false }
        return plan.slots[cell.slotIndex].assignments
            .first { $0.position == cell.position }?.isLocked ?? false
    }

    func slotHeader(for slot: RotationSlot) -> String {
        switch game.rotationStyle {
        case .byQuarter: return "Q\(slot.quarter)"
        case .byTimeInterval: return "Q\(slot.quarter)·\(slot.subIndex + 1)"
        }
    }

    // MARK: - Breakdown

    enum BreakdownSort: String, CaseIterable {
        case byMinutes = "Minutes"
        case byTier = "Tier"
        case byName = "Name"
    }

    struct BreakdownRow: Identifiable {
        let player: Player
        let projectedMinutes: Int
        let minimumMinutes: Int
        let minutesFraction: Double
        let status: MinutesStatus
        let assignedPositions: [Position]
        let conflictNote: String?
        let goalMinutes: Int
        let fieldMinutes: Int

        var id: UUID {
            player.id
        }
    }

    struct BreakdownSection: Identifiable {
        let tier: Tier?
        let rows: [BreakdownRow]
        var id: String {
            tier?.rawValue ?? "all"
        }
    }

    var breakdownSort: BreakdownSort = .byMinutes
    var breakdownGroupByTier: Bool = false

    var breakdownSections: [BreakdownSection] {
        guard breakdownGroupByTier else { return [BreakdownSection(tier: nil, rows: sortedBreakdownRows)] }
        return Tier.allCases.compactMap { tier in
            let rows = sortedBreakdownRows.filter { $0.player.tier == tier }
            return rows.isEmpty ? nil : BreakdownSection(tier: tier, rows: rows)
        }
    }

    private var sortedBreakdownRows: [BreakdownRow] {
        let rows = presentPlayers.map { makeBreakdownRow(for: $0) }
        switch breakdownSort {
        case .byMinutes:
            return rows.sorted { $0.projectedMinutes > $1.projectedMinutes }
        case .byTier:
            let order = Dictionary(uniqueKeysWithValues: Tier.allCases.enumerated().map { ($1, $0) })
            return rows.sorted { (order[$0.player.tier] ?? 0) < (order[$1.player.tier] ?? 0) }
        case .byName:
            return rows.sorted { $0.player.name < $1.player.name }
        }
    }

    private func makeBreakdownRow(for player: Player) -> BreakdownRow {
        let playerID = player.id
        var goalSlots = 0
        var fieldSlots = 0
        var posSet = Set<Position>()

        game.rotationPlan?.slots.forEach { slot in
            slot.assignments.filter { $0.playerID == playerID }.forEach { pa in
                posSet.insert(pa.position)
                if pa.position == .goalie { goalSlots += 1 } else { fieldSlots += 1 }
            }
        }

        let positionOrder: [Position] = [.goalie, .attack, .midfield, .defense]
        let assignedPositions = positionOrder.filter { posSet.contains($0) }

        let attendance = game.attendance.first { $0.id == playerID }
        var notes: [String] = []
        if let q = attendance?.lateArrivalQuarter { notes.append("Arrives Q\(q)") }
        if let q = attendance?.earlyDepartureQuarter { notes.append("Leaves after Q\(q)") }

        return BreakdownRow(
            player: player,
            projectedMinutes: projectedMinutes(for: playerID),
            minimumMinutes: minimumMinutes(for: playerID),
            minutesFraction: minutesFraction(for: playerID),
            status: minutesStatus(for: playerID),
            assignedPositions: assignedPositions,
            conflictNote: notes.isEmpty ? nil : notes.joined(separator: " · "),
            goalMinutes: goalSlots * slotDurationMinutes,
            fieldMinutes: fieldSlots * slotDurationMinutes
        )
    }

    // MARK: - Summary

    var summaryPlayerCount: Int {
        game.attendance.filter { $0.isPresent }.count
    }

    var summaryMinMax: (min: Int, max: Int) {
        let ids = game.attendance.filter { $0.isPresent }.map { $0.id }
        guard !ids.isEmpty else { return (0, 0) }
        let minutes = ids.map { projectedMinutes(for: $0) }
        return (minutes.min() ?? 0, minutes.max() ?? 0)
    }

    var summaryViolationCount: Int {
        activeViolations.count
    }

    var summaryLockedCount: Int {
        game.rotationPlan?.slots.reduce(0) { sum, slot in
            sum + slot.assignments.filter { $0.isLocked }.count
        } ?? 0
    }

    // MARK: - Tap-to-swap

    func tapCell(slotIndex: Int, position: Position) {
        guard let plan = game.rotationPlan, slotIndex < plan.slots.count else { return }
        guard plan.slots[slotIndex].assignments.contains(where: { $0.position == position }) else {
            selectedCell = nil
            return
        }

        let cell = CellID(slotIndex: slotIndex, position: position)
        if let selected = selectedCell {
            if selected == cell {
                selectedCell = nil
            } else {
                performSwap(from: selected, to: cell)
                selectedCell = nil
            }
        } else {
            selectedCell = cell
        }
    }

    private func performSwap(from a: CellID, to b: CellID) {
        guard var plan = game.rotationPlan,
              a.slotIndex < plan.slots.count,
              b.slotIndex < plan.slots.count else { return }

        let playerA = plan.slots[a.slotIndex].assignments.first { $0.position == a.position }?.playerID
        let playerB = plan.slots[b.slotIndex].assignments.first { $0.position == b.position }?.playerID
        guard playerA != nil || playerB != nil else { return }

        saveUndoState()

        plan.slots[a.slotIndex].assignments.removeAll { $0.position == a.position }
        plan.slots[b.slotIndex].assignments.removeAll { $0.position == b.position }

        if let pb = playerB {
            plan.slots[a.slotIndex].assignments.append(
                PositionAssignment(position: a.position, playerID: pb, isLocked: false)
            )
        }
        if let pa = playerA {
            plan.slots[b.slotIndex].assignments.append(
                PositionAssignment(position: b.position, playerID: pa, isLocked: false)
            )
        }

        commitPlan(plan)
    }

    // MARK: - Bench swap

    func initiateBenchSwap(slotIndex: Int, position: Position) {
        guard let plan = game.rotationPlan, slotIndex < plan.slots.count else { return }
        let slot = plan.slots[slotIndex]
        benchSwapCandidates = players.filter { player in
            slot.bench.contains(player.id) && player.positions.contains(position)
        }
        guard !benchSwapCandidates.isEmpty else { return }
        benchSwapTarget = CellID(slotIndex: slotIndex, position: position)
        showBenchSwapSheet = true
    }

    func confirmBenchSwap(benchPlayerID: UUID) {
        guard let target = benchSwapTarget,
              var plan = game.rotationPlan,
              target.slotIndex < plan.slots.count else { return }

        saveUndoState()

        let displaced = plan.slots[target.slotIndex].assignments
            .first { $0.position == target.position }?.playerID

        plan.slots[target.slotIndex].assignments.removeAll { $0.position == target.position }
        plan.slots[target.slotIndex].bench.removeAll { $0 == benchPlayerID }
        plan.slots[target.slotIndex].assignments.append(
            PositionAssignment(position: target.position, playerID: benchPlayerID, isLocked: false)
        )
        if let displaced {
            plan.slots[target.slotIndex].bench.append(displaced)
        }

        showBenchSwapSheet = false
        benchSwapTarget = nil
        benchSwapCandidates = []
        commitPlan(plan)
    }

    // MARK: - Cell options (long press)

    func showCellOptions(slotIndex: Int, position: Position) {
        cellOptionsTarget = CellID(slotIndex: slotIndex, position: position)
    }

    func clearCellOptions() {
        cellOptionsTarget = nil
    }

    func toggleLock(cell: CellID) {
        guard var plan = game.rotationPlan, cell.slotIndex < plan.slots.count else { return }
        guard let index = plan.slots[cell.slotIndex].assignments
            .firstIndex(where: { $0.position == cell.position }) else { return }
        plan.slots[cell.slotIndex].assignments[index].isLocked.toggle()
        commitPlan(plan)
    }

    func removePlayer(at cell: CellID) {
        guard var plan = game.rotationPlan, cell.slotIndex < plan.slots.count else { return }
        guard let displaced = plan.slots[cell.slotIndex].assignments
            .first(where: { $0.position == cell.position })?.playerID else { return }
        saveUndoState()
        plan.slots[cell.slotIndex].assignments.removeAll { $0.position == cell.position }
        plan.slots[cell.slotIndex].bench.append(displaced)
        commitPlan(plan)
    }

    // MARK: - Undo

    private func saveUndoState() {
        previousPlan = game.rotationPlan
        canUndo = true
        hasManualChanges = true
    }

    func undo() {
        guard let prev = previousPlan else { return }
        var updated = game
        updated.rotationPlan = prev
        game = updated
        try? store.updateGame(updated)
        previousPlan = nil
        canUndo = false
    }

    // MARK: - Violations

    func dismissViolation(at index: Int) {
        guard var plan = game.rotationPlan, index < plan.violations.count else { return }
        plan.violations[index].isDismissed = true
        commitPlan(plan)
    }

    // MARK: - Bench expansion

    func toggleBenchExpansion(slotIndex: Int) {
        if expandedBenchSlots.contains(slotIndex) {
            expandedBenchSlots.remove(slotIndex)
        } else {
            expandedBenchSlots.insert(slotIndex)
        }
    }

    // MARK: - Completion

    func markComplete(stats: GameStats?) {
        try? store.completeGame(game, stats: stats)
        if let updated = store.games.first(where: { $0.id == game.id }) {
            game = updated
        }
        gameWasCompleted = true
    }

    // MARK: - Regenerate

    func requestRegenerate() {
        if hasManualChanges {
            showRegenerateWarning = true
        } else {
            doRegenerate()
        }
    }

    func confirmRegenerate() {
        showRegenerateWarning = false
        hasManualChanges = false
        doRegenerate()
    }

    private func doRegenerate() {
        try? store.generatePlan(for: game)
        if let updated = store.games.first(where: { $0.id == game.id }) {
            game = updated
        }
        previousPlan = nil
        canUndo = false
    }

    // MARK: - Private

    private func commitPlan(_ plan: RotationPlan) {
        var updated = game
        updated.rotationPlan = plan
        game = updated
        try? store.updateGame(updated)
    }
}
