import CRModel
import Foundation
import RotationSolver
import Testing

@Suite("RotationSolver")
struct RotationSolverTests {
    // MARK: - Helpers

    private func makePlayer(
        id: UUID = UUID(),
        name: String = "Player",
        number: Int = 1,
        positions: Set<Position>,
        tier: Tier = .developing
    ) -> Player {
        Player(id: id, name: name, jerseyNumber: number, positions: positions, tier: tier)
    }

    private func attendAll(_ players: [Player]) -> [PlayerAttendance] {
        players.map { PlayerAttendance(id: $0.id, isPresent: true, lateArrivalQuarter: nil, earlyDepartureQuarter: nil) }
    }

    private func makeGame(
        players: [Player],
        attendance: [PlayerAttendance]? = nil,
        format: GameFormatDefaults = GameFormatDefaults(quarters: 4, quarterLengthMinutes: 10, playersPerSide: 7, midQuarterSubsEnabled: true),
        rotationStyle: RotationStyle = .byQuarter,
        fairnessTargets: FairnessTargets = FairnessTargets(eliteMinutes: 20, strongMinutes: 18, developingMinutes: 15, learningMinutes: 12, beginnerMinutes: 10, goalieTimeCountsAsFieldTime: true),
        mode: CompetitivenessMode = .fair,
        boostedPlayerIDs: [UUID] = []
    ) -> Game {
        let att = attendance ?? attendAll(players)
        return Game(
            id: UUID(),
            opponent: "Test",
            date: Date(timeIntervalSince1970: 1_700_000_000),
            isHome: true,
            status: .planned,
            attendance: att,
            format: format,
            rotationStyle: rotationStyle,
            fairnessTargets: fairnessTargets,
            competitivenessMode: mode,
            boostedPlayerIDs: boostedPlayerIDs,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    private func allPositionPlayers(count: Int, tier: Tier = .developing) -> [Player] {
        (0 ..< count).map { i in
            makePlayer(
                id: UUID(),
                name: "P\(i)",
                number: i,
                positions: [.attack, .midfield, .defense, .goalie],
                tier: tier
            )
        }
    }

    // MARK: - Schedule generation

    @Test func byQuarterProducesOneSlotPerQuarter() {
        let players = allPositionPlayers(count: 7)
        let game = makeGame(
            players: players,
            format: GameFormatDefaults(quarters: 4, quarterLengthMinutes: 10, playersPerSide: 7, midQuarterSubsEnabled: true)
        )
        let plan = RotationSolver.solve(game: game, players: players)
        #expect(plan.slots.count == 4)
        #expect(plan.slots.map { $0.quarter } == [1, 2, 3, 4])
        #expect(plan.slots.allSatisfy { $0.subIndex == 0 })
    }

    @Test func byTimeIntervalProducesCorrectSlotCount() {
        let players = allPositionPlayers(count: 7)
        let game = makeGame(
            players: players,
            format: GameFormatDefaults(quarters: 2, quarterLengthMinutes: 10, playersPerSide: 7, midQuarterSubsEnabled: true),
            rotationStyle: .byTimeInterval(intervalMinutes: 5)
        )
        let plan = RotationSolver.solve(game: game, players: players)
        #expect(plan.slots.count == 4) // 2 quarters × 2 subs per quarter
        #expect(plan.slots.filter { $0.quarter == 1 }.count == 2)
        #expect(plan.slots.filter { $0.quarter == 2 }.count == 2)
    }

    @Test func byTimeIntervalSubIndicesAreCorrect() {
        let players = allPositionPlayers(count: 7)
        let game = makeGame(
            players: players,
            format: GameFormatDefaults(quarters: 1, quarterLengthMinutes: 9, playersPerSide: 7, midQuarterSubsEnabled: true),
            rotationStyle: .byTimeInterval(intervalMinutes: 3)
        )
        let plan = RotationSolver.solve(game: game, players: players)
        #expect(plan.slots.count == 3)
        #expect(plan.slots[0].subIndex == 0)
        #expect(plan.slots[1].subIndex == 1)
        #expect(plan.slots[2].subIndex == 2)
    }

    // MARK: - Position eligibility

    @Test func positionEligibilityEnforced() {
        // Attack-only player must never appear in a non-attack slot
        let attackOnly = makePlayer(positions: [.attack])
        // Fill remaining positions with all-eligible players
        let fillers = allPositionPlayers(count: 6)
        let players = [attackOnly] + fillers
        let game = makeGame(players: players)
        let plan = RotationSolver.solve(game: game, players: players)

        for slot in plan.slots {
            for assignment in slot.assignments where assignment.playerID == attackOnly.id {
                #expect(assignment.position == .attack)
            }
        }
    }

    @Test func goalieOnlyPlayerNeverAssignedToFieldPosition() {
        let goalieOnly = makePlayer(positions: [.goalie])
        let fillers = allPositionPlayers(count: 6)
        let players = [goalieOnly] + fillers
        let game = makeGame(players: players)
        let plan = RotationSolver.solve(game: game, players: players)

        for slot in plan.slots {
            for assignment in slot.assignments where assignment.playerID == goalieOnly.id {
                #expect(assignment.position == .goalie)
            }
        }
    }

    @Test func allSevenSlotsFilledWhenSufficientPlayers() {
        let players = allPositionPlayers(count: 7)
        let game = makeGame(players: players)
        let plan = RotationSolver.solve(game: game, players: players)

        for slot in plan.slots {
            #expect(slot.assignments.count == 7)
            #expect(slot.bench.isEmpty)
        }
    }

    // MARK: - Attendance and availability

    @Test func absentPlayerNotAssigned() {
        let absent = makePlayer(positions: [.attack, .midfield, .defense, .goalie])
        let others = allPositionPlayers(count: 7)
        let players = [absent] + others
        var att = attendAll(players)
        att[0] = PlayerAttendance(id: absent.id, isPresent: false, lateArrivalQuarter: nil, earlyDepartureQuarter: nil)
        let game = makeGame(players: players, attendance: att)
        let plan = RotationSolver.solve(game: game, players: players)

        for slot in plan.slots {
            let allAssignedIDs = slot.assignments.map { $0.playerID }
            #expect(!allAssignedIDs.contains(absent.id))
            #expect(!slot.bench.contains(absent.id))
        }
    }

    @Test func lateArrivalPlayerNotInEarlyQuarters() {
        let latePlayer = makePlayer(positions: [.attack, .midfield, .defense, .goalie])
        let fillers = allPositionPlayers(count: 7)
        let players = [latePlayer] + fillers
        var att = attendAll(players)
        att[0] = PlayerAttendance(id: latePlayer.id, isPresent: true, lateArrivalQuarter: 3, earlyDepartureQuarter: nil)
        let game = makeGame(players: players, attendance: att)
        let plan = RotationSolver.solve(game: game, players: players)

        for slot in plan.slots where slot.quarter < 3 {
            let allIDs = slot.assignments.map { $0.playerID } + slot.bench
            #expect(!allIDs.contains(latePlayer.id))
        }
        let laterSlots = plan.slots.filter { $0.quarter >= 3 }
        let appearsLate = laterSlots.contains { slot in
            slot.assignments.contains { $0.playerID == latePlayer.id } || slot.bench.contains(latePlayer.id)
        }
        #expect(appearsLate)
    }

    @Test func earlyDeparturePlayerNotInLaterQuarters() {
        let earlyLeaver = makePlayer(positions: [.attack, .midfield, .defense, .goalie])
        let fillers = allPositionPlayers(count: 7)
        let players = [earlyLeaver] + fillers
        var att = attendAll(players)
        att[0] = PlayerAttendance(id: earlyLeaver.id, isPresent: true, lateArrivalQuarter: nil, earlyDepartureQuarter: 2)
        let game = makeGame(players: players, attendance: att)
        let plan = RotationSolver.solve(game: game, players: players)

        for slot in plan.slots where slot.quarter > 2 {
            let allIDs = slot.assignments.map { $0.playerID } + slot.bench
            #expect(!allIDs.contains(earlyLeaver.id))
        }
    }

    @Test func playerWithBothConflictsRespected() {
        let restricted = makePlayer(positions: [.attack, .midfield, .defense, .goalie])
        let fillers = allPositionPlayers(count: 7)
        let players = [restricted] + fillers
        var att = attendAll(players)
        att[0] = PlayerAttendance(id: restricted.id, isPresent: true, lateArrivalQuarter: 2, earlyDepartureQuarter: 3)
        let game = makeGame(players: players, attendance: att)
        let plan = RotationSolver.solve(game: game, players: players)

        for slot in plan.slots where slot.quarter < 2 || slot.quarter > 3 {
            let allIDs = slot.assignments.map { $0.playerID } + slot.bench
            #expect(!allIDs.contains(restricted.id))
        }
    }

    // MARK: - Goalie slot

    @Test func goalieSlotFilledByEligiblePlayer() {
        let goalie = makePlayer(positions: [.goalie])
        let fillers = (0 ..< 6).map { i in makePlayer(number: i + 10, positions: [.attack, .midfield, .defense]) }
        let players = [goalie] + fillers
        let game = makeGame(players: players)
        let plan = RotationSolver.solve(game: game, players: players)

        for slot in plan.slots {
            let goalieAssignments = slot.assignments.filter { $0.position == .goalie }
            #expect(goalieAssignments.count == 1)
            #expect(goalieAssignments.first?.playerID == goalie.id)
        }
    }

    @Test func noEligibleGoalieCreatesViolation() {
        let players = (0 ..< 7).map { i in makePlayer(number: i, positions: [.attack, .midfield, .defense]) }
        let game = makeGame(players: players)
        let plan = RotationSolver.solve(game: game, players: players)

        let goalieViolations = plan.violations.filter { $0.kind == .noEligiblePlayer && $0.position == .goalie }
        #expect(goalieViolations.count == 4) // one per quarter
    }

    // MARK: - Violations

    @Test func noEligiblePlayerForPositionCreatesViolation() {
        // Only goalie-eligible players — no field eligibility
        let players = (0 ..< 7).map { i in makePlayer(number: i, positions: [.goalie]) }
        let game = makeGame(players: players)
        let plan = RotationSolver.solve(game: game, players: players)

        let fieldViolations = plan.violations.filter {
            $0.kind == .noEligiblePlayer && $0.position != .goalie
        }
        #expect(!fieldViolations.isEmpty)
    }

    @Test func playerBelowMinimumCreatesViolation() {
        // 14 players competing for 7 slots over 2 rotations
        // Each player gets at most 1 rotation × 10 min = 10 min < 20 min minimum
        let players = allPositionPlayers(count: 14, tier: .elite)
        let game = makeGame(
            players: players,
            format: GameFormatDefaults(quarters: 2, quarterLengthMinutes: 10, playersPerSide: 7, midQuarterSubsEnabled: false),
            fairnessTargets: FairnessTargets(eliteMinutes: 20, strongMinutes: 18, developingMinutes: 15, learningMinutes: 12, beginnerMinutes: 10, goalieTimeCountsAsFieldTime: true)
        )
        let plan = RotationSolver.solve(game: game, players: players)

        let minViolations = plan.violations.filter { $0.kind == .minutesBelowMinimum }
        #expect(!minViolations.isEmpty)
    }

    @Test func noViolationsWhenEnoughRotationsForMinimum() {
        // 7 players, 4 quarters: each plays all 4 rotations = 40 min > 20 min Elite minimum
        let players = allPositionPlayers(count: 7, tier: .elite)
        let game = makeGame(
            players: players,
            format: GameFormatDefaults(quarters: 4, quarterLengthMinutes: 10, playersPerSide: 7, midQuarterSubsEnabled: true),
            fairnessTargets: FairnessTargets(eliteMinutes: 20, strongMinutes: 18, developingMinutes: 15, learningMinutes: 12, beginnerMinutes: 10, goalieTimeCountsAsFieldTime: true)
        )
        let plan = RotationSolver.solve(game: game, players: players)

        let minViolations = plan.violations.filter { $0.kind == .minutesBelowMinimum }
        #expect(minViolations.isEmpty)
    }

    @Test func allAbsentProducesNoEligiblePlayerViolations() {
        let players = allPositionPlayers(count: 7)
        var att = attendAll(players)
        att = att.map { PlayerAttendance(id: $0.id, isPresent: false, lateArrivalQuarter: nil, earlyDepartureQuarter: nil) }
        let game = makeGame(players: players, attendance: att)
        let plan = RotationSolver.solve(game: game, players: players)

        #expect(plan.slots.allSatisfy { $0.assignments.isEmpty && $0.bench.isEmpty })
        let fieldViolations = plan.violations.filter { $0.kind == .noEligiblePlayer }
        #expect(!fieldViolations.isEmpty)
    }

    @Test func emptyRosterProducesNoEligiblePlayerViolations() {
        let game = makeGame(players: [])
        let plan = RotationSolver.solve(game: game, players: [])

        #expect(plan.slots.allSatisfy { $0.assignments.isEmpty })
        #expect(plan.violations.contains(where: { $0.kind == .noEligiblePlayer }))
    }

    // MARK: - Fairness

    @Test func fairModeDistributesPlayingTimeEvenly() {
        // 14 players, 4 quarters, 7v7: expect no player plays more than 1 extra rotation beyond others
        let players = allPositionPlayers(count: 14)
        let game = makeGame(players: players, mode: .fair)
        let plan = RotationSolver.solve(game: game, players: players)

        var playCount: [UUID: Int] = [:]
        for slot in plan.slots {
            for assignment in slot.assignments {
                playCount[assignment.playerID, default: 0] += 1
            }
        }
        let counts = Array(playCount.values)
        let minCount = counts.min() ?? 0
        let maxCount = counts.max() ?? 0
        #expect(maxCount - minCount <= 1)
    }

    @Test func boostedPlayerGetsPriorityAssignment() {
        // 14 players, 4 quarters, 7v7, one boosted
        let players = allPositionPlayers(count: 14)
        let boosted = players[0]
        let game = makeGame(players: players, mode: .fair, boostedPlayerIDs: [boosted.id])
        let plan = RotationSolver.solve(game: game, players: players)

        var playCount: [UUID: Int] = [:]
        for slot in plan.slots {
            for assignment in slot.assignments {
                playCount[assignment.playerID, default: 0] += 1
            }
        }
        let boostedCount = playCount[boosted.id] ?? 0
        let unboostedCounts = players.dropFirst().map { playCount[$0.id] ?? 0 }
        let maxUnboosted = unboostedCounts.max() ?? 0
        #expect(boostedCount >= maxUnboosted)
    }

    // MARK: - Goalie time counting

    @Test func goalieTimeCountedTowardMinimumWhenEnabled() {
        // 1 goalie-only player, 4 quarters, goalieTimeCountsAsFieldTime = true
        // Goalie plays all 4 slots × 10 min = 40 min >= 20 min → no violation
        let goalie = makePlayer(positions: [.goalie], tier: .elite)
        let fillers = (0 ..< 6).map { i in makePlayer(number: i + 10, positions: [.attack, .midfield, .defense], tier: .developing) }
        let players = [goalie] + fillers
        let game = makeGame(
            players: players,
            fairnessTargets: FairnessTargets(eliteMinutes: 20, strongMinutes: 18, developingMinutes: 15, learningMinutes: 12, beginnerMinutes: 10, goalieTimeCountsAsFieldTime: true)
        )
        let plan = RotationSolver.solve(game: game, players: players)

        let goalieViolation = plan.violations.first {
            $0.kind == .minutesBelowMinimum && $0.playerID == goalie.id
        }
        #expect(goalieViolation == nil)
    }

    @Test func goalieTimeNotCountedTowardMinimumWhenDisabled() {
        // Same setup but goalieTimeCountsAsFieldTime = false
        // Goalie-only player gets 0 effective field minutes → violation
        let goalie = makePlayer(positions: [.goalie], tier: .elite)
        let fillers = (0 ..< 6).map { i in makePlayer(number: i + 10, positions: [.attack, .midfield, .defense], tier: .developing) }
        let players = [goalie] + fillers
        let game = makeGame(
            players: players,
            fairnessTargets: FairnessTargets(eliteMinutes: 20, strongMinutes: 18, developingMinutes: 15, learningMinutes: 12, beginnerMinutes: 10, goalieTimeCountsAsFieldTime: false)
        )
        let plan = RotationSolver.solve(game: game, players: players)

        let goalieViolation = plan.violations.first {
            $0.kind == .minutesBelowMinimum && $0.playerID == goalie.id
        }
        #expect(goalieViolation != nil)
        #expect(goalieViolation?.projectedMinutes == 0)
    }

    // MARK: - Competitiveness modes

    @Test func competitiveModePacksTopTierInKeySlot() {
        // 4 elite + 10 developing players, 2 quarters, 7v7, competitive mode
        // Sub-index 0 of each quarter is the "key" slot → expect elites prioritized there
        let elites = (0 ..< 4).map { i in makePlayer(number: i, positions: [.attack, .midfield, .defense, .goalie], tier: .elite) }
        let developing = (0 ..< 10).map { i in makePlayer(number: i + 10, positions: [.attack, .midfield, .defense, .goalie], tier: .developing) }
        let players = elites + developing
        let game = makeGame(
            players: players,
            format: GameFormatDefaults(quarters: 2, quarterLengthMinutes: 10, playersPerSide: 7, midQuarterSubsEnabled: true),
            mode: .competitive
        )
        let plan = RotationSolver.solve(game: game, players: players)

        let keySlots = plan.slots.filter { $0.subIndex == 0 }
        let eliteIDs = Set(elites.map { $0.id })
        for slot in keySlots {
            let assignedElites = slot.assignments.filter { eliteIDs.contains($0.playerID) }.count
            // All 4 elites should be assigned in the key slot (we have 7 slots and 4 elites)
            #expect(assignedElites == elites.count)
        }
    }

    @Test func benchPlayersAreAvailableNotAssigned() {
        // 14 players, 7v7, 1 quarter: 7 play, 7 bench
        let players = allPositionPlayers(count: 14)
        let game = makeGame(
            players: players,
            format: GameFormatDefaults(quarters: 1, quarterLengthMinutes: 10, playersPerSide: 7, midQuarterSubsEnabled: true)
        )
        let plan = RotationSolver.solve(game: game, players: players)

        #expect(plan.slots.count == 1)
        let slot = plan.slots[0]
        #expect(slot.assignments.count == 7)
        #expect(slot.bench.count == 7)
        #expect(Set(slot.assignments.map { $0.playerID }).isDisjoint(with: Set(slot.bench)))
    }

    @Test func zeroPlayersPerSideProducesEmptyPlan() {
        let players = allPositionPlayers(count: 7)
        let game = makeGame(
            players: players,
            format: GameFormatDefaults(quarters: 4, quarterLengthMinutes: 10, playersPerSide: 0, midQuarterSubsEnabled: true)
        )
        let plan = RotationSolver.solve(game: game, players: players)
        #expect(plan.slots.isEmpty)
    }

    // MARK: - Locked cells

    @Test func lockedCellPreservedDuringRegeneration() {
        let players = allPositionPlayers(count: 7)
        var game = makeGame(players: players)
        var initialPlan = RotationSolver.solve(game: game, players: players)

        guard let goalieIndex = initialPlan.slots[0].assignments
            .firstIndex(where: { $0.position == .goalie }) else {
            Issue.record("No goalie assignment found")
            return
        }
        let lockedGoalieID = initialPlan.slots[0].assignments[goalieIndex].playerID
        initialPlan.slots[0].assignments[goalieIndex].isLocked = true
        game.rotationPlan = initialPlan

        let newPlan = RotationSolver.solve(game: game, players: players)

        let newGoalieID = newPlan.slots[0].assignments.first { $0.position == .goalie }?.playerID
        #expect(newGoalieID == lockedGoalieID)
        let stillLocked = newPlan.slots[0].assignments.first { $0.position == .goalie }?.isLocked ?? false
        #expect(stillLocked == true)
    }

    @Test func lockedAbsentPlayerIsNotPreserved() {
        let players = allPositionPlayers(count: 7)
        var game = makeGame(players: players)
        var initialPlan = RotationSolver.solve(game: game, players: players)

        guard let goalieIndex = initialPlan.slots[0].assignments
            .firstIndex(where: { $0.position == .goalie }) else {
            Issue.record("No goalie assignment found")
            return
        }
        let absentGoalieID = initialPlan.slots[0].assignments[goalieIndex].playerID
        initialPlan.slots[0].assignments[goalieIndex].isLocked = true
        game.rotationPlan = initialPlan

        var attendance = game.attendance
        if let attIdx = attendance.firstIndex(where: { $0.id == absentGoalieID }) {
            attendance[attIdx] = PlayerAttendance(
                id: absentGoalieID, isPresent: false,
                lateArrivalQuarter: nil, earlyDepartureQuarter: nil
            )
        }
        game.attendance = attendance

        let newPlan = RotationSolver.solve(game: game, players: players)

        let newGoalieID = newPlan.slots[0].assignments.first { $0.position == .goalie }?.playerID
        #expect(newGoalieID != absentGoalieID)
    }
}
