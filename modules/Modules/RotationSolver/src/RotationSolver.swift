import CRModel
import Foundation

public struct RotationSolver: Sendable {
    private init() {}

    public static func solve(game: Game, players: [Player]) -> RotationPlan {
        guard game.format.quarters > 0,
              game.format.playersPerSide > 0,
              game.format.quarterLengthMinutes > 0
        else {
            return RotationPlan(slots: [], violations: [])
        }
        if case let .byTimeInterval(interval) = game.rotationStyle, interval <= 0 {
            return RotationPlan(slots: [], violations: [])
        }

        let schedule = makeSchedule(format: game.format, rotationStyle: game.rotationStyle)
        let duration = rotationDuration(format: game.format, rotationStyle: game.rotationStyle)
        let counts = game.format.effectivePositionCounts
        let slotCounts: [Position: Int] = [
            .goalie: game.format.hasGoalie ? 1 : 0,
            .attack: counts.attack,
            .midfield: counts.midfield,
            .defense: counts.defense,
        ]
        let boostedIDs = Set(game.boostedPlayerIDs)

        let presentPlayers = players.filter { player in
            game.attendance.first { $0.id == player.id }?.isPresent == true
        }

        let availableSlotCounts = computeAvailableSlotCounts(
            schedule: schedule,
            attendance: game.attendance,
            playerIDs: presentPlayers.map { $0.id }
        )

        var lockedBySlot: [String: [PositionAssignment]] = [:]
        if let existing = game.rotationPlan {
            for slot in existing.slots {
                let key = slotKey(quarter: slot.quarter, subIndex: slot.subIndex)
                let locked = slot.assignments.filter { $0.isLocked }
                if !locked.isEmpty {
                    lockedBySlot[key] = locked
                }
            }
        }

        var effectiveSlotsPlayed: [UUID: Int] = [:]
        var rotationSlots: [RotationSlot] = []
        var violations: [Violation] = []

        for (quarter, subIndex) in schedule {
            let isKeySlot = game.competitivenessMode == .competitive && subIndex == 0

            let availableNow = presentPlayers.filter {
                isAvailable(playerID: $0.id, quarter: quarter, attendance: game.attendance)
            }

            var assignedIDs: Set<UUID> = []
            var assignments: [PositionAssignment] = []

            let locked = lockedBySlot[slotKey(quarter: quarter, subIndex: subIndex)] ?? []
            for lockedAssignment in locked {
                guard let player = availableNow.first(where: { $0.id == lockedAssignment.playerID }),
                      player.positions.contains(lockedAssignment.position),
                      (slotCounts[lockedAssignment.position] ?? 0) > 0
                else { continue }
                assignedIDs.insert(player.id)
                assignments.append(lockedAssignment)
            }

            for position in [Position.goalie, .attack, .midfield, .defense] {
                let total = slotCounts[position] ?? 0
                guard total > 0 else { continue }

                let alreadyFilled = assignments.filter { $0.position == position }.count
                let needed = total - alreadyFilled
                guard needed > 0 else { continue }

                let eligible = availableNow.filter {
                    !assignedIDs.contains($0.id) && $0.positions.contains(position)
                }

                let sorted = prioritized(
                    eligible,
                    effectiveSlotsPlayed: effectiveSlotsPlayed,
                    availableSlotCounts: availableSlotCounts,
                    isKeySlot: isKeySlot,
                    mode: game.competitivenessMode,
                    boostedIDs: boostedIDs
                )

                let toAssign = min(needed, sorted.count)
                for i in 0 ..< toAssign {
                    let player = sorted[i]
                    assignedIDs.insert(player.id)
                    assignments.append(
                        PositionAssignment(position: position, playerID: player.id, isLocked: false)
                    )
                }

                for _ in toAssign ..< needed {
                    violations.append(.noEligiblePlayer(position: position, quarter: quarter, subIndex: subIndex))
                }
            }

            let bench = availableNow
                .filter { !assignedIDs.contains($0.id) }
                .map { $0.id }

            rotationSlots.append(RotationSlot(
                quarter: quarter,
                subIndex: subIndex,
                assignments: assignments,
                bench: bench
            ))

            for pa in assignments {
                let counts = pa.position != .goalie || game.fairnessTargets.goalieTimeCountsAsFieldTime
                if counts {
                    effectiveSlotsPlayed[pa.playerID, default: 0] += 1
                }
            }
        }

        for player in presentPlayers {
            let played = effectiveSlotsPlayed[player.id] ?? 0
            let projectedMinutes = played * duration
            let minimumMinutes = game.fairnessTargets.minutes(for: player.tier)
            if projectedMinutes < minimumMinutes {
                violations.append(.minutesBelowMinimum(
                    playerID: player.id,
                    projectedMinutes: projectedMinutes,
                    minimumMinutes: minimumMinutes
                ))
            }
        }

        return RotationPlan(slots: rotationSlots, violations: violations)
    }

    // MARK: - Private helpers

    private static func slotKey(quarter: Int, subIndex: Int) -> String {
        "\(quarter)-\(subIndex)"
    }

    private static func makeSchedule(
        format: GameFormatDefaults,
        rotationStyle: RotationStyle
    ) -> [(quarter: Int, subIndex: Int)] {
        switch rotationStyle {
        case .byQuarter:
            return (1 ... format.quarters).map { ($0, 0) }
        case let .byTimeInterval(interval):
            let subsPerQuarter = max(1, format.quarterLengthMinutes / interval)
            return (1 ... format.quarters).flatMap { q in
                (0 ..< subsPerQuarter).map { s in (q, s) }
            }
        }
    }

    private static func rotationDuration(format: GameFormatDefaults, rotationStyle: RotationStyle) -> Int {
        switch rotationStyle {
        case .byQuarter: return format.quarterLengthMinutes
        case let .byTimeInterval(interval): return interval
        }
    }

    private static func computeAvailableSlotCounts(
        schedule: [(quarter: Int, subIndex: Int)],
        attendance: [PlayerAttendance],
        playerIDs: [UUID]
    ) -> [UUID: Int] {
        var counts: [UUID: Int] = [:]
        for id in playerIDs {
            counts[id] = schedule.filter {
                isAvailable(playerID: id, quarter: $0.quarter, attendance: attendance)
            }.count
        }
        return counts
    }

    private static func isAvailable(playerID: UUID, quarter: Int, attendance: [PlayerAttendance]) -> Bool {
        guard let att = attendance.first(where: { $0.id == playerID }) else { return false }
        guard att.isPresent else { return false }
        if let lateQ = att.lateArrivalQuarter, quarter < lateQ { return false }
        if let earlyQ = att.earlyDepartureQuarter, quarter > earlyQ { return false }
        return true
    }

    private static func prioritized(
        _ players: [Player],
        effectiveSlotsPlayed: [UUID: Int],
        availableSlotCounts: [UUID: Int],
        isKeySlot: Bool,
        mode: CompetitivenessMode,
        boostedIDs: Set<UUID>
    ) -> [Player] {
        players.sorted { a, b in
            let aBoosted = boostedIDs.contains(a.id)
            let bBoosted = boostedIDs.contains(b.id)
            if aBoosted != bBoosted { return aBoosted }

            if isKeySlot, mode == .competitive {
                let at = tierStrength(a.tier)
                let bt = tierStrength(b.tier)
                if at != bt { return at > bt }
            }

            let ar = playRatio(
                for: a.id,
                effectiveSlotsPlayed: effectiveSlotsPlayed,
                availableSlotCounts: availableSlotCounts
            )
            let br = playRatio(
                for: b.id,
                effectiveSlotsPlayed: effectiveSlotsPlayed,
                availableSlotCounts: availableSlotCounts
            )

            if abs(ar - br) < 0.001, mode == .balanced || mode == .competitive {
                let at = tierStrength(a.tier)
                let bt = tierStrength(b.tier)
                if at != bt { return at > bt }
            }

            return ar < br
        }
    }

    private static func playRatio(
        for playerID: UUID,
        effectiveSlotsPlayed: [UUID: Int],
        availableSlotCounts: [UUID: Int]
    ) -> Double {
        let played = Double(effectiveSlotsPlayed[playerID] ?? 0)
        let available = Double(availableSlotCounts[playerID] ?? 1)
        guard available > 0 else { return 1.0 }
        return played / available
    }

    private static func tierStrength(_ tier: Tier) -> Int {
        switch tier {
        case .elite: 5
        case .strong: 4
        case .developing: 3
        case .learning: 2
        case .beginner: 1
        }
    }
}
