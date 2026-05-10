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
        format: GameFormatDefaults = GameFormatDefaults(quarters: 4, quarterLengthMinutes: 10, playersPerSide: 7),
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
            format: GameFormatDefaults(quarters: 4, quarterLengthMinutes: 10, playersPerSide: 7)
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
            format: GameFormatDefaults(quarters: 2, quarterLengthMinutes: 10, playersPerSide: 7),
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
            format: GameFormatDefaults(quarters: 1, quarterLengthMinutes: 9, playersPerSide: 7),
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
            format: GameFormatDefaults(quarters: 2, quarterLengthMinutes: 10, playersPerSide: 7),
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
            format: GameFormatDefaults(quarters: 4, quarterLengthMinutes: 10, playersPerSide: 7),
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
            format: GameFormatDefaults(quarters: 2, quarterLengthMinutes: 10, playersPerSide: 7),
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
            format: GameFormatDefaults(quarters: 1, quarterLengthMinutes: 10, playersPerSide: 7)
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
            format: GameFormatDefaults(quarters: 4, quarterLengthMinutes: 10, playersPerSide: 0)
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

    // MARK: - hasGoalie = false

    @Test func noGoalieFormatProducesNoGoalieAssignments() {
        let players = (0 ..< 6).map { i in makePlayer(number: i, positions: [.attack, .midfield, .defense]) }
        let game = makeGame(
            players: players,
            format: GameFormatDefaults(quarters: 4, quarterLengthMinutes: 10, playersPerSide: 6, hasGoalie: false)
        )
        let plan = RotationSolver.solve(game: game, players: players)

        for slot in plan.slots {
            #expect(slot.assignments.allSatisfy { $0.position != .goalie })
        }
        let goalieViolations = plan.violations.filter { $0.kind == .noEligiblePlayer && $0.position == .goalie }
        #expect(goalieViolations.isEmpty)
    }

    @Test func noGoalieFormatFillsAllFieldSlots() {
        // 6 players, 6v6 no-goalie → attack=2, midfield=2, defense=2; all 6 fill, bench empty
        let players = (0 ..< 6).map { i in makePlayer(number: i, positions: [.attack, .midfield, .defense]) }
        let game = makeGame(
            players: players,
            format: GameFormatDefaults(quarters: 4, quarterLengthMinutes: 10, playersPerSide: 6, hasGoalie: false)
        )
        let plan = RotationSolver.solve(game: game, players: players)

        for slot in plan.slots {
            #expect(slot.assignments.count == 6)
            #expect(slot.bench.isEmpty)
        }
        #expect(plan.violations.filter { $0.kind == .noEligiblePlayer }.isEmpty)
    }

    // MARK: - Edge cases

    @Test func playerWithNoAttendanceRecordIsNotAssigned() {
        let ghost = makePlayer(positions: [.attack, .midfield, .defense, .goalie])
        let others = allPositionPlayers(count: 7)
        let players = [ghost] + others
        let att = attendAll(others) // ghost has no attendance entry
        let game = makeGame(players: players, attendance: att)
        let plan = RotationSolver.solve(game: game, players: players)

        for slot in plan.slots {
            let allIDs = slot.assignments.map { $0.playerID } + slot.bench
            #expect(!allIDs.contains(ghost.id))
        }
    }

    @Test func singlePresentPlayerIsAssignedOncePerSlot() {
        let player = makePlayer(positions: [.attack, .midfield, .defense, .goalie])
        let game = makeGame(players: [player])
        let plan = RotationSolver.solve(game: game, players: [player])

        for slot in plan.slots {
            let assignedCount = slot.assignments.filter { $0.playerID == player.id }.count
            #expect(assignedCount == 1)
            #expect(!slot.bench.contains(player.id))
        }
    }

    @Test func lateArrivalPlayerFillsAllAvailableSlots() {
        // 8 players, 7v7, 4 quarters. Late player arrives Q3 (available for 2 of 4 slots).
        // Play ratio normalisation means they have priority in both Q3 and Q4.
        let latePlayer = makePlayer(positions: [.attack, .midfield, .defense, .goalie])
        let others = allPositionPlayers(count: 7)
        let players = [latePlayer] + others
        var att = attendAll(players)
        att[0] = PlayerAttendance(id: latePlayer.id, isPresent: true, lateArrivalQuarter: 3, earlyDepartureQuarter: nil)
        let game = makeGame(players: players, attendance: att)
        let plan = RotationSolver.solve(game: game, players: players)

        let latePlayed = plan.slots.filter { slot in
            slot.assignments.contains { $0.playerID == latePlayer.id }
        }.count
        #expect(latePlayed == 2)
    }

    @Test func byTimeIntervalNonDivisibleIntervalUsesFloorDivision() {
        // 10-minute quarter with 3-minute interval → floor(10/3) = 3 rotations
        let players = allPositionPlayers(count: 7)
        let game = makeGame(
            players: players,
            format: GameFormatDefaults(quarters: 1, quarterLengthMinutes: 10, playersPerSide: 7),
            rotationStyle: .byTimeInterval(intervalMinutes: 3)
        )
        let plan = RotationSolver.solve(game: game, players: players)
        #expect(plan.slots.count == 3)
    }

    @Test func allTiersMeetMinimumMinutesWithAdequateRoster() {
        // One player per tier, 5v5 no-goalie, 4 quarters × 10 min = 40 min each.
        // All minimums ≤ 40, so no minutesBelowMinimum violations.
        let tiers: [Tier] = [.elite, .strong, .developing, .learning, .beginner]
        let players = tiers.enumerated().map { i, tier in
            makePlayer(number: i, positions: [.attack, .midfield, .defense], tier: tier)
        }
        let game = makeGame(
            players: players,
            format: GameFormatDefaults(quarters: 4, quarterLengthMinutes: 10, playersPerSide: 5, hasGoalie: false)
        )
        let plan = RotationSolver.solve(game: game, players: players)
        #expect(plan.violations.filter { $0.kind == .minutesBelowMinimum }.isEmpty)
    }

    @Test func balancedModePrefersTierAsPlayRatioTiebreaker() throws {
        // 8 players (4 beginners first, 4 elites) for 7 slots over 4 quarters.
        // Balanced mode uses tier as a tiebreaker when play ratios are equal.
        // Elites should accumulate more plays (4 each) than beginners (3 each).
        let beginners = (0 ..< 4).map { i in makePlayer(number: i, positions: [.attack, .midfield, .defense, .goalie], tier: .beginner) }
        let elites = (4 ..< 8).map { i in makePlayer(number: i, positions: [.attack, .midfield, .defense, .goalie], tier: .elite) }
        let players = beginners + elites // beginners listed first to confirm tier beats input order
        let game = makeGame(players: players, mode: .balanced)
        let plan = RotationSolver.solve(game: game, players: players)

        var playCount: [UUID: Int] = [:]
        for slot in plan.slots {
            for assignment in slot.assignments {
                playCount[assignment.playerID, default: 0] += 1
            }
        }
        let elitePlays = elites.map { playCount[$0.id] ?? 0 }
        let beginnerPlays = beginners.map { playCount[$0.id] ?? 0 }
        #expect(try #require(elitePlays.min()) >= beginnerPlays.max()!)
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

    // MARK: - Guard conditions

    @Test func zeroQuarterLengthProducesEmptyPlan() {
        let players = allPositionPlayers(count: 7)
        let game = makeGame(
            players: players,
            format: GameFormatDefaults(quarters: 4, quarterLengthMinutes: 0, playersPerSide: 7)
        )
        let plan = RotationSolver.solve(game: game, players: players)
        #expect(plan.slots.isEmpty)
        #expect(plan.violations.isEmpty)
    }

    @Test func zeroIntervalProducesEmptyPlan() {
        let players = allPositionPlayers(count: 7)
        let game = makeGame(
            players: players,
            rotationStyle: .byTimeInterval(intervalMinutes: 0)
        )
        let plan = RotationSolver.solve(game: game, players: players)
        #expect(plan.slots.isEmpty)
        #expect(plan.violations.isEmpty)
    }

    @Test func negativeIntervalProducesEmptyPlan() {
        let players = allPositionPlayers(count: 7)
        let game = makeGame(
            players: players,
            rotationStyle: .byTimeInterval(intervalMinutes: -1)
        )
        let plan = RotationSolver.solve(game: game, players: players)
        #expect(plan.slots.isEmpty)
    }

    // MARK: - Locked cells (additional)

    @Test func lockedCellDroppedWhenPlayerNoLongerEligibleForPosition() {
        var players = allPositionPlayers(count: 7)
        var game = makeGame(players: players)
        var initialPlan = RotationSolver.solve(game: game, players: players)

        guard let goalieIndex = initialPlan.slots[0].assignments
            .firstIndex(where: { $0.position == .goalie }) else {
            Issue.record("No goalie assignment found")
            return
        }
        let lockedPlayerID = initialPlan.slots[0].assignments[goalieIndex].playerID
        initialPlan.slots[0].assignments[goalieIndex].isLocked = true
        game.rotationPlan = initialPlan

        // Remove goalie eligibility from the locked player
        if let idx = players.firstIndex(where: { $0.id == lockedPlayerID }) {
            players[idx] = makePlayer(id: lockedPlayerID, number: players[idx].jerseyNumber, positions: [.attack, .midfield, .defense])
        }

        let newPlan = RotationSolver.solve(game: game, players: players)

        // Locked player must not appear as goalie
        let newGoalieAssignment = newPlan.slots[0].assignments.first { $0.position == .goalie }
        #expect(newGoalieAssignment?.playerID != lockedPlayerID)
        // A different eligible player fills the goalie slot
        #expect(newGoalieAssignment != nil)
    }

    @Test func multipleLockedCellsInSameSlotAllPreserved() {
        let players = allPositionPlayers(count: 7)
        var game = makeGame(players: players)
        var plan = RotationSolver.solve(game: game, players: players)

        let locked1 = plan.slots[0].assignments[0]
        let locked2 = plan.slots[0].assignments[1]
        plan.slots[0].assignments[0].isLocked = true
        plan.slots[0].assignments[1].isLocked = true
        game.rotationPlan = plan

        let newPlan = RotationSolver.solve(game: game, players: players)
        let newQ1 = newPlan.slots[0].assignments

        #expect(newQ1.contains { $0.playerID == locked1.playerID && $0.position == locked1.position && $0.isLocked })
        #expect(newQ1.contains { $0.playerID == locked2.playerID && $0.position == locked2.position && $0.isLocked })
    }

    // MARK: - Attendance boundary cases

    @Test func lateArrivalOnFirstQuarterIsEffectivelyPresent() {
        // lateArrivalQuarter = 1 means available from Q1 onward — same as no constraint
        let lateQ1 = makePlayer(positions: [.attack, .midfield, .defense, .goalie])
        let fillers = allPositionPlayers(count: 6)
        let players = [lateQ1] + fillers
        var att = attendAll(players)
        att[0] = PlayerAttendance(id: lateQ1.id, isPresent: true, lateArrivalQuarter: 1, earlyDepartureQuarter: nil)
        let game = makeGame(players: players, attendance: att)
        let plan = RotationSolver.solve(game: game, players: players)

        let appearedIn = plan.slots.filter { slot in
            slot.assignments.contains { $0.playerID == lateQ1.id } || slot.bench.contains(lateQ1.id)
        }.count
        #expect(appearedIn == plan.slots.count)
    }

    @Test func earlyDepartureOnLastQuarterIsEffectivelyPresent() {
        // earlyDepartureQuarter = 4 in a 4-quarter game — available all game
        let earlyQ4 = makePlayer(positions: [.attack, .midfield, .defense, .goalie])
        let fillers = allPositionPlayers(count: 6)
        let players = [earlyQ4] + fillers
        var att = attendAll(players)
        att[0] = PlayerAttendance(id: earlyQ4.id, isPresent: true, lateArrivalQuarter: nil, earlyDepartureQuarter: 4)
        let game = makeGame(players: players, attendance: att, format: GameFormatDefaults(quarters: 4, quarterLengthMinutes: 10, playersPerSide: 7))
        let plan = RotationSolver.solve(game: game, players: players)

        let appearedIn = plan.slots.filter { slot in
            slot.assignments.contains { $0.playerID == earlyQ4.id } || slot.bench.contains(earlyQ4.id)
        }.count
        #expect(appearedIn == 4)
    }

    @Test func lateArrivalAndEarlyDepartureSameQuarterRestrictsToOneQuarter() {
        // Available only in Q2 (late Q2, early Q2)
        let restricted = makePlayer(positions: [.attack, .midfield, .defense, .goalie])
        let fillers = allPositionPlayers(count: 7)
        let players = [restricted] + fillers
        var att = attendAll(players)
        att[0] = PlayerAttendance(id: restricted.id, isPresent: true, lateArrivalQuarter: 2, earlyDepartureQuarter: 2)
        let game = makeGame(players: players, attendance: att)
        let plan = RotationSolver.solve(game: game, players: players)

        for slot in plan.slots where slot.quarter != 2 {
            let allIDs = Set(slot.assignments.map { $0.playerID } + slot.bench)
            #expect(!allIDs.contains(restricted.id))
        }
        let appearsInQ2 = plan.slots.filter { $0.quarter == 2 }.contains { slot in
            slot.assignments.contains { $0.playerID == restricted.id } || slot.bench.contains(restricted.id)
        }
        #expect(appearsInQ2)
    }

    // MARK: - Boosted players (additional)

    @Test func multipleBoostedPlayersAllGetPriority() {
        // 4 boosted + 10 unboosted, 7v7, 4 quarters — every boosted player plays at least as much as any unboosted
        let players = allPositionPlayers(count: 14)
        let boostedIDs = players.prefix(4).map { $0.id }
        let game = makeGame(players: players, mode: .fair, boostedPlayerIDs: Array(boostedIDs))
        let plan = RotationSolver.solve(game: game, players: players)

        var playCount: [UUID: Int] = [:]
        for slot in plan.slots {
            for assignment in slot.assignments {
                playCount[assignment.playerID, default: 0] += 1
            }
        }
        let boostedCounts = boostedIDs.map { playCount[$0] ?? 0 }
        let unboostedCounts = players.dropFirst(4).map { playCount[$0.id] ?? 0 }
        let minBoosted = boostedCounts.min() ?? 0
        let maxUnboosted = unboostedCounts.max() ?? 0
        #expect(minBoosted >= maxUnboosted)
    }

    @Test func absentBoostedPlayerIsNotAssigned() {
        let players = allPositionPlayers(count: 14)
        let absentBoosted = players[0]
        var att = attendAll(players)
        att[0] = PlayerAttendance(id: absentBoosted.id, isPresent: false, lateArrivalQuarter: nil, earlyDepartureQuarter: nil)
        let game = makeGame(players: players, attendance: att, mode: .fair, boostedPlayerIDs: [absentBoosted.id])
        let plan = RotationSolver.solve(game: game, players: players)

        for slot in plan.slots {
            let allIDs = slot.assignments.map { $0.playerID } + slot.bench
            #expect(!allIDs.contains(absentBoosted.id))
        }
    }

    // MARK: - Time interval edge cases

    @Test func intervalLargerThanQuarterLengthProducesOneSlotPerQuarter() {
        // 15-minute interval with a 10-minute quarter → floor(10/15) = 0, max(1, 0) = 1 slot per quarter
        let players = allPositionPlayers(count: 7)
        let game = makeGame(
            players: players,
            format: GameFormatDefaults(quarters: 4, quarterLengthMinutes: 10, playersPerSide: 7),
            rotationStyle: .byTimeInterval(intervalMinutes: 15)
        )
        let plan = RotationSolver.solve(game: game, players: players)
        #expect(plan.slots.count == 4)
        #expect(plan.slots.allSatisfy { $0.subIndex == 0 })
    }

    @Test func competitiveModeKeySlotWithTimeInterval() {
        // Competitive + byTimeInterval: sub-index 0 of each quarter is the key slot
        let elites = (0 ..< 4).map { i in makePlayer(number: i, positions: [.attack, .midfield, .defense, .goalie], tier: .elite) }
        let developing = (0 ..< 10).map { i in makePlayer(number: i + 10, positions: [.attack, .midfield, .defense, .goalie], tier: .developing) }
        let players = elites + developing
        let game = makeGame(
            players: players,
            format: GameFormatDefaults(quarters: 2, quarterLengthMinutes: 10, playersPerSide: 7),
            rotationStyle: .byTimeInterval(intervalMinutes: 5),
            mode: .competitive
        )
        let plan = RotationSolver.solve(game: game, players: players)

        let eliteIDs = Set(elites.map { $0.id })
        let keySlots = plan.slots.filter { $0.subIndex == 0 }
        for slot in keySlots {
            let assignedElites = slot.assignments.filter { eliteIDs.contains($0.playerID) }.count
            #expect(assignedElites == elites.count)
        }
    }

    // MARK: - Position count override

    @Test func explicitPositionCountOverrideIsRespected() {
        // 3 attack + 2 midfield + 2 defense + 1 goalie = 8 field slots
        let players = allPositionPlayers(count: 8)
        let counts = PositionCounts(attack: 3, midfield: 2, defense: 2)
        let game = makeGame(
            players: players,
            format: GameFormatDefaults(quarters: 2, quarterLengthMinutes: 10, playersPerSide: 8, positionCounts: counts)
        )
        let plan = RotationSolver.solve(game: game, players: players)

        for slot in plan.slots {
            #expect(slot.assignments.filter { $0.position == .attack }.count == 3)
            #expect(slot.assignments.filter { $0.position == .midfield }.count == 2)
            #expect(slot.assignments.filter { $0.position == .defense }.count == 2)
            #expect(slot.assignments.filter { $0.position == .goalie }.count == 1)
        }
    }

    // MARK: - Invariant checks

    @Test func noPlayerAssignedMoreThanOnceInSameSlot() {
        // Small roster (5) for a 7-slot game forces shortfalls but no duplicates
        let players = allPositionPlayers(count: 5)
        let game = makeGame(
            players: players,
            format: GameFormatDefaults(quarters: 4, quarterLengthMinutes: 10, playersPerSide: 7)
        )
        let plan = RotationSolver.solve(game: game, players: players)

        for slot in plan.slots {
            let assignedIDs = slot.assignments.map { $0.playerID }
            #expect(Set(assignedIDs).count == assignedIDs.count)
        }
    }

    @Test func benchAndAssignmentsAreAlwaysDisjoint() {
        let players = allPositionPlayers(count: 14)
        let game = makeGame(players: players)
        let plan = RotationSolver.solve(game: game, players: players)

        for slot in plan.slots {
            let assignedSet = Set(slot.assignments.map { $0.playerID })
            let benchSet = Set(slot.bench)
            #expect(assignedSet.isDisjoint(with: benchSet))
        }
    }

    @Test func playerWithNoPositionEligibilityLandsOnBench() {
        // A player with empty positions set is present but can never be assigned a position
        let noPos = makePlayer(positions: [])
        let fillers = allPositionPlayers(count: 7)
        let players = [noPos] + fillers
        let game = makeGame(players: players)
        let plan = RotationSolver.solve(game: game, players: players)

        for slot in plan.slots {
            #expect(!slot.assignments.contains { $0.playerID == noPos.id })
            #expect(slot.bench.contains(noPos.id))
        }
    }

    // MARK: - Integration

    @Test func fullGameMixedPositionRoster() throws {
        // 12 players: 1 goalie-only, 3 attack-only, 3 defense-only, 5 all-position
        let goalie = makePlayer(number: 0, positions: [.goalie])
        let attackOnly = (1 ... 3).map { i in makePlayer(number: i, positions: [.attack]) }
        let defenseOnly = (4 ... 6).map { i in makePlayer(number: i, positions: [.defense]) }
        let allPos = (7 ... 11).map { i in makePlayer(number: i, positions: [.attack, .midfield, .defense, .goalie]) }
        let players = [goalie] + attackOnly + defenseOnly + allPos
        let game = makeGame(
            players: players,
            format: GameFormatDefaults(quarters: 4, quarterLengthMinutes: 10, playersPerSide: 7)
        )
        let plan = RotationSolver.solve(game: game, players: players)

        for slot in plan.slots {
            // No duplicate player IDs in a single slot's assignments
            let assignedIDs = slot.assignments.map { $0.playerID }
            #expect(Set(assignedIDs).count == assignedIDs.count)
            // Every assigned player is eligible for their position
            for assignment in slot.assignments {
                let player = try #require(players.first { $0.id == assignment.playerID })
                #expect(player.positions.contains(assignment.position))
            }
            // Bench and assignments don't overlap
            #expect(Set(assignedIDs).isDisjoint(with: Set(slot.bench)))
        }
    }

    @Test func regenerationPreservesLockedCellsWhileRespectingNewAbsence() {
        // 8 players: lock goalie in Q1, then mark a different player absent and regenerate
        let players = allPositionPlayers(count: 8)
        var game = makeGame(players: players)
        var plan = RotationSolver.solve(game: game, players: players)

        guard let goalieIndex = plan.slots[0].assignments.firstIndex(where: { $0.position == .goalie }) else {
            Issue.record("No goalie found in initial plan")
            return
        }
        let lockedGoalieID = plan.slots[0].assignments[goalieIndex].playerID
        plan.slots[0].assignments[goalieIndex].isLocked = true
        game.rotationPlan = plan

        // Mark a different player absent
        guard let otherPlayer = players.first(where: { $0.id != lockedGoalieID }) else {
            Issue.record("No other player found")
            return
        }
        var att = game.attendance
        if let idx = att.firstIndex(where: { $0.id == otherPlayer.id }) {
            att[idx] = PlayerAttendance(id: otherPlayer.id, isPresent: false, lateArrivalQuarter: nil, earlyDepartureQuarter: nil)
        }
        game.attendance = att

        let newPlan = RotationSolver.solve(game: game, players: players)

        // Locked goalie still in Q1
        let newGoalie = newPlan.slots[0].assignments.first { $0.position == .goalie }
        #expect(newGoalie?.playerID == lockedGoalieID)
        #expect(newGoalie?.isLocked == true)
        // Absent player appears nowhere
        for slot in newPlan.slots {
            let allIDs = slot.assignments.map { $0.playerID } + slot.bench
            #expect(!allIDs.contains(otherPlayer.id))
        }
    }

    @Test func largeRosterFairModeProducesTightDistribution() {
        // 24 players, 12v12 no-goalie, 4 quarters — max - min play count must be ≤ 1
        let players = (0 ..< 24).map { i in makePlayer(number: i, positions: [.attack, .midfield, .defense]) }
        let game = makeGame(
            players: players,
            format: GameFormatDefaults(quarters: 4, quarterLengthMinutes: 10, playersPerSide: 12, hasGoalie: false),
            mode: .fair
        )
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

    @Test func mixedAttendanceAllConstraintsRespected() {
        // 12 players: 2 absent, 2 late Q3, 1 early Q2, 7 fully present; 7v7, 4 quarters
        let fullyPresent = (0 ..< 7).map { i in makePlayer(number: i, positions: [.attack, .midfield, .defense, .goalie]) }
        let absentPlayers = (7 ..< 9).map { i in makePlayer(number: i, positions: [.attack, .midfield, .defense, .goalie]) }
        let latePlayers = (9 ..< 11).map { i in makePlayer(number: i, positions: [.attack, .midfield, .defense, .goalie]) }
        let earlyPlayer = makePlayer(number: 11, positions: [.attack, .midfield, .defense, .goalie])
        let players = fullyPresent + absentPlayers + latePlayers + [earlyPlayer]

        var att: [PlayerAttendance] = []
        att += fullyPresent.map { PlayerAttendance(id: $0.id, isPresent: true, lateArrivalQuarter: nil, earlyDepartureQuarter: nil) }
        att += absentPlayers.map { PlayerAttendance(id: $0.id, isPresent: false, lateArrivalQuarter: nil, earlyDepartureQuarter: nil) }
        att += latePlayers.map { PlayerAttendance(id: $0.id, isPresent: true, lateArrivalQuarter: 3, earlyDepartureQuarter: nil) }
        att.append(PlayerAttendance(id: earlyPlayer.id, isPresent: true, lateArrivalQuarter: nil, earlyDepartureQuarter: 2))

        let game = makeGame(players: players, attendance: att, mode: .fair)
        let plan = RotationSolver.solve(game: game, players: players)

        for slot in plan.slots {
            let allIDs = Set(slot.assignments.map { $0.playerID } + slot.bench)
            // Absent players never appear
            for absent in absentPlayers {
                #expect(!allIDs.contains(absent.id))
            }
            // Late players only appear in Q3+
            if slot.quarter < 3 {
                for late in latePlayers {
                    #expect(!allIDs.contains(late.id))
                }
            }
            // Early player only in Q1 and Q2
            if slot.quarter > 2 {
                #expect(!allIDs.contains(earlyPlayer.id))
            }
        }

        // Late players appear in at least one slot from Q3 onward
        let lateSlotsIDs = plan.slots.filter { $0.quarter >= 3 }.flatMap {
            $0.assignments.map { $0.playerID } + $0.bench
        }
        for late in latePlayers {
            #expect(lateSlotsIDs.contains(late.id))
        }
    }
}
