@testable import CRApp
import CRModel
import FileManagerClient
import Foundation
import Testing
import UserDefaultsClient

@Suite("SeasonStore")
@MainActor
struct SeasonStoreTests {
    private let fixedID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeStore(
        fileManagerClient: FileManagerClient = .mock(),
        userDefaultsClient: UserDefaultsClient = .noop
    ) -> SeasonStore {
        SeasonStore(
            fileManagerClient: fileManagerClient,
            userDefaultsClient: userDefaultsClient
        )
    }

    private func encodedSeason(_ season: Season) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(season)
    }

    @Test func startsEmptyWhenNoSeasonsOnDisk() {
        let store = makeStore(
            fileManagerClient: .mock(
                contentsOfDirectoryUrls: { _, _, _ in [] }
            )
        )
        #expect(store.seasons.isEmpty)
        #expect(store.activeSeason == nil)
    }

    @Test func createSeasonAddsToList() throws {
        let store = makeStore()
        let season = Season(
            id: fixedID,
            teamName: "Eagles",
            seasonName: "Spring 2025",
            gameFormatDefaults: .default,
            createdAt: fixedDate
        )
        try store.create(season)
        #expect(store.seasons.count == 1)
        #expect(store.seasons.first?.id == fixedID)
    }

    @Test func createSeasonSetsActiveSeasonAndPersistsID() throws {
        let userDefaults = UserDefaultsClient.memoryStorage
        let store = makeStore(userDefaultsClient: userDefaults)
        let season = Season(
            id: fixedID,
            teamName: "Eagles",
            seasonName: "Spring 2025",
            gameFormatDefaults: .default,
            createdAt: fixedDate
        )
        try store.create(season)
        #expect(store.activeSeason?.id == fixedID)
        #expect(userDefaults.stringForKey("cr_active_season_id") == fixedID.uuidString)
    }

    @Test func loadsExistingSeasonFromDisk() throws {
        let season = Season(
            id: fixedID,
            teamName: "Eagles",
            seasonName: "Spring 2025",
            gameFormatDefaults: .default,
            createdAt: fixedDate
        )
        let data = try encodedSeason(season)
        let seasonDir = URL(fileURLWithPath: "/fake/Seasons/\(fixedID.uuidString)")
        let store = makeStore(
            fileManagerClient: .mock(
                contentsOfDirectoryUrls: { _, _, _ in [seasonDir] },
                contents: { path in path.hasSuffix("season.json") ? data : nil }
            )
        )
        #expect(store.seasons.count == 1)
        #expect(store.seasons.first?.teamName == "Eagles")
    }

    @Test func restoresActiveSeasonFromUserDefaults() throws {
        let season = Season(
            id: fixedID,
            teamName: "Eagles",
            seasonName: "Spring 2025",
            gameFormatDefaults: .default,
            createdAt: fixedDate
        )
        let data = try encodedSeason(season)
        let seasonDir = URL(fileURLWithPath: "/fake/Seasons/\(fixedID.uuidString)")
        let userDefaults = UserDefaultsClient.memoryStorage
        userDefaults.storeString(fixedID.uuidString, "cr_active_season_id")
        let store = makeStore(
            fileManagerClient: .mock(
                contentsOfDirectoryUrls: { _, _, _ in [seasonDir] },
                contents: { path in path.hasSuffix("season.json") ? data : nil }
            ),
            userDefaultsClient: userDefaults
        )
        #expect(store.activeSeason?.id == fixedID)
    }

    @Test func setActiveUpdatesActiveSeasonAndUserDefaults() throws {
        let season = Season(
            id: fixedID,
            teamName: "Eagles",
            seasonName: "Spring 2025",
            gameFormatDefaults: .default,
            createdAt: fixedDate
        )
        let userDefaults = UserDefaultsClient.memoryStorage
        let store = makeStore(userDefaultsClient: userDefaults)
        try store.create(season)

        let secondID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
        let second = Season(
            id: secondID,
            teamName: "Hawks",
            seasonName: "Fall 2025",
            gameFormatDefaults: .default,
            createdAt: fixedDate
        )
        try store.create(second)
        store.setActive(season)

        #expect(store.activeSeason?.id == fixedID)
        #expect(userDefaults.stringForKey("cr_active_season_id") == fixedID.uuidString)
    }
}

@Suite("SeasonStore — Roster")
@MainActor
struct SeasonStoreRosterTests {
    private let fixedSeasonID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func storeWithActiveSeason() throws -> SeasonStore {
        let store = SeasonStore(fileManagerClient: .mock(), userDefaultsClient: .noop)
        let season = Season(
            id: fixedSeasonID,
            teamName: "Eagles",
            seasonName: "Spring 2025",
            gameFormatDefaults: .default,
            createdAt: fixedDate
        )
        try store.create(season)
        return store
    }

    private func makePlayer(id: UUID = UUID(), name: String = "Alex", number: Int = 10) -> Player {
        Player(
            id: id,
            name: name,
            jerseyNumber: number,
            positions: [.midfield],
            tier: .developing
        )
    }

    @Test func startsWithEmptyRosterWhenNoActiveSeason() {
        let store = SeasonStore(fileManagerClient: .mock(), userDefaultsClient: .noop)
        #expect(store.players.isEmpty)
    }

    @Test func createPlayerAddsToList() throws {
        let store = try storeWithActiveSeason()
        let player = makePlayer()
        try store.createPlayer(player)
        #expect(store.players.count == 1)
        #expect(store.players.first?.id == player.id)
    }

    @Test func updatePlayerModifiesInPlace() throws {
        let store = try storeWithActiveSeason()
        let playerID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
        let original = makePlayer(id: playerID, name: "Alex", number: 10)
        try store.createPlayer(original)

        let updated = Player(
            id: playerID,
            name: "Alexander",
            jerseyNumber: 99,
            positions: [.attack, .midfield],
            tier: .strong
        )
        try store.updatePlayer(updated)

        #expect(store.players.count == 1)
        #expect(store.players.first?.name == "Alexander")
        #expect(store.players.first?.jerseyNumber == 99)
        #expect(store.players.first?.tier == .strong)
    }

    @Test func deletePlayerRemovesFromList() throws {
        let store = try storeWithActiveSeason()
        let player = makePlayer()
        try store.createPlayer(player)
        try store.deletePlayer(player)
        #expect(store.players.isEmpty)
    }

    @Test func deleteUnknownPlayerIsNoOp() throws {
        let store = try storeWithActiveSeason()
        let known = try makePlayer(id: #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002")), name: "Alex")
        try store.createPlayer(known)
        let unknown = try makePlayer(id: #require(UUID(uuidString: "00000000-0000-0000-0000-000000000003")), name: "Unknown")
        try store.deletePlayer(unknown)
        #expect(store.players.count == 1)
    }

    @Test func loadsRosterFromDiskOnInit() throws {
        let playerID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
        let player = Player(
            id: playerID,
            name: "Sam Lee",
            jerseyNumber: 1,
            positions: [.goalie],
            tier: .elite
        )
        let rosterData = try JSONEncoder().encode([player])

        let seasonEncoder = JSONEncoder()
        seasonEncoder.dateEncodingStrategy = .iso8601
        let season = Season(
            id: fixedSeasonID,
            teamName: "Eagles",
            seasonName: "Spring 2025",
            gameFormatDefaults: .default,
            createdAt: fixedDate
        )
        let seasonData = try seasonEncoder.encode(season)

        let seasonDir = URL(fileURLWithPath: "/fake/Seasons/\(fixedSeasonID.uuidString)")
        let store = SeasonStore(
            fileManagerClient: .mock(
                contentsOfDirectoryUrls: { _, _, _ in [seasonDir] },
                contents: { path in
                    if path.hasSuffix("season.json") { return seasonData }
                    if path.hasSuffix("roster.json") { return rosterData }
                    return nil
                }
            ),
            userDefaultsClient: .memoryStorage
        )

        #expect(store.players.count == 1)
        #expect(store.players.first?.name == "Sam Lee")
        #expect(store.players.first?.positions == [.goalie])
    }

    @Test func rosterClearsWhenSwitchingToSeasonWithNoRoster() throws {
        let store = try storeWithActiveSeason()
        let player = makePlayer()
        try store.createPlayer(player)
        #expect(store.players.count == 1)

        let secondSeasonID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000009"))
        let secondSeason = Season(
            id: secondSeasonID,
            teamName: "Hawks",
            seasonName: "Fall 2025",
            gameFormatDefaults: .default,
            createdAt: fixedDate
        )
        try store.create(secondSeason)
        #expect(store.players.isEmpty)
    }
}

@Suite("SeasonStore — Games")
@MainActor
struct SeasonStoreGameTests {
    private let fixedSeasonID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let fixedGameID = UUID(uuidString: "00000000-0000-0000-0000-000000000010")!
    private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func storeWithActiveSeason() throws -> SeasonStore {
        let store = SeasonStore(fileManagerClient: .mock(), userDefaultsClient: .noop)
        let season = Season(
            id: fixedSeasonID,
            teamName: "Eagles",
            seasonName: "Spring 2025",
            gameFormatDefaults: .default,
            createdAt: fixedDate
        )
        try store.create(season)
        return store
    }

    private func makeGame(id: UUID? = nil) -> Game {
        Game(
            id: id ?? UUID(),
            opponent: "Hawks",
            date: fixedDate,
            isHome: true,
            status: .planned,
            attendance: [],
            format: .default,
            rotationStyle: .byQuarter,
            fairnessTargets: .default,
            competitivenessMode: .balanced,
            boostedPlayerIDs: [],
            createdAt: fixedDate
        )
    }

    @Test func startsWithEmptyGamesWhenNoActiveSeason() {
        let store = SeasonStore(fileManagerClient: .mock(), userDefaultsClient: .noop)
        #expect(store.games.isEmpty)
    }

    @Test func createGameAddsToList() throws {
        let store = try storeWithActiveSeason()
        let game = makeGame(id: fixedGameID)
        try store.createGame(game)
        #expect(store.games.count == 1)
        #expect(store.games.first?.id == fixedGameID)
    }

    @Test func deleteGameRemovesFromList() throws {
        let store = try storeWithActiveSeason()
        let game = makeGame(id: fixedGameID)
        try store.createGame(game)
        try store.deleteGame(game)
        #expect(store.games.isEmpty)
    }

    @Test func updateGameModifiesInPlace() throws {
        let store = try storeWithActiveSeason()
        let original = makeGame(id: fixedGameID)
        try store.createGame(original)

        var updated = original
        updated.opponent = "Lions"
        updated.isHome = false
        try store.updateGame(updated)

        #expect(store.games.count == 1)
        #expect(store.games.first?.opponent == "Lions")
        #expect(store.games.first?.isHome == false)
    }

    @Test func loadsGamesFromDiskOnInit() throws {
        let game = makeGame(id: fixedGameID)
        let gameEncoder = JSONEncoder()
        gameEncoder.dateEncodingStrategy = .iso8601
        let gameData = try gameEncoder.encode(game)

        let seasonEncoder = JSONEncoder()
        seasonEncoder.dateEncodingStrategy = .iso8601
        let season = Season(
            id: fixedSeasonID,
            teamName: "Eagles",
            seasonName: "Spring 2025",
            gameFormatDefaults: .default,
            createdAt: fixedDate
        )
        let seasonData = try seasonEncoder.encode(season)

        let seasonDir = URL(fileURLWithPath: "/fake/Seasons/\(fixedSeasonID.uuidString)")
        let gamesDir = URL(fileURLWithPath: "/fake/Games")
        let gameFileURL = gamesDir.appending(component: "game_\(fixedGameID.uuidString).json")

        let store = SeasonStore(
            fileManagerClient: .mock(
                contentsOfDirectoryUrls: { url, _, _ in
                    if url.path.hasSuffix("Seasons") { return [seasonDir] }
                    if url.path.hasSuffix("Games") { return [gameFileURL] }
                    return []
                },
                contents: { path in
                    if path.hasSuffix("season.json") { return seasonData }
                    if path.hasSuffix("game_\(fixedGameID.uuidString).json") { return gameData }
                    return nil
                }
            ),
            userDefaultsClient: .memoryStorage
        )

        #expect(store.games.count == 1)
        #expect(store.games.first?.opponent == "Hawks")
    }

    @Test func gamesClearWhenSwitchingSeasons() throws {
        let store = try storeWithActiveSeason()
        let game = makeGame(id: fixedGameID)
        try store.createGame(game)
        #expect(store.games.count == 1)

        let secondSeasonID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000009"))
        let secondSeason = Season(
            id: secondSeasonID,
            teamName: "Hawks",
            seasonName: "Fall 2025",
            gameFormatDefaults: .default,
            createdAt: fixedDate
        )
        try store.create(secondSeason)
        #expect(store.games.isEmpty)
    }
}

// MARK: - RotationOutputViewModel Tests

@Suite("RotationOutputViewModel")
@MainActor
struct RotationOutputViewModelTests {
    private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
    private let seasonID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let gameID = UUID(uuidString: "00000000-0000-0000-0000-000000000010")!

    private func makeStore() throws -> SeasonStore {
        let store = SeasonStore(fileManagerClient: .mock(), userDefaultsClient: .noop)
        let season = Season(
            id: seasonID,
            teamName: "Eagles",
            seasonName: "Spring 2025",
            gameFormatDefaults: .default,
            createdAt: fixedDate
        )
        try store.create(season)
        return store
    }

    private func makePlayers() -> [Player] {
        (0 ..< 6).map { i in
            Player(
                id: UUID(),
                name: "Player \(i)",
                jerseyNumber: i,
                positions: [.attack, .midfield, .defense, .goalie],
                tier: .developing
            )
        }
    }

    private func makePlan(players: [Player]) -> RotationPlan {
        RotationPlan(
            slots: [
                RotationSlot(
                    quarter: 1,
                    subIndex: 0,
                    assignments: [
                        PositionAssignment(position: .goalie, playerID: players[0].id, isLocked: false),
                        PositionAssignment(position: .attack, playerID: players[1].id, isLocked: false),
                        PositionAssignment(position: .midfield, playerID: players[2].id, isLocked: false),
                        PositionAssignment(position: .defense, playerID: players[3].id, isLocked: false),
                    ],
                    bench: [players[4].id, players[5].id]
                ),
            ],
            violations: []
        )
    }

    private func makeGame(players: [Player], plan: RotationPlan) -> Game {
        Game(
            id: gameID,
            opponent: "Hawks",
            date: fixedDate,
            isHome: true,
            status: .ready,
            attendance: players.map {
                PlayerAttendance(id: $0.id, isPresent: true, lateArrivalQuarter: nil, earlyDepartureQuarter: nil)
            },
            format: GameFormatDefaults(
                quarters: 1,
                quarterLengthMinutes: 10,
                playersPerSide: 5
            ),
            rotationStyle: .byQuarter,
            fairnessTargets: FairnessTargets(
                eliteMinutes: 10,
                strongMinutes: 8,
                developingMinutes: 6,
                learningMinutes: 4,
                beginnerMinutes: 2,
                goalieTimeCountsAsFieldTime: true
            ),
            competitivenessMode: .fair,
            boostedPlayerIDs: [],
            rotationPlan: plan,
            createdAt: fixedDate
        )
    }

    private func makeVM(
        store: SeasonStore,
        game: Game,
        players: [Player]
    ) throws -> RotationOutputViewModel {
        try store.createGame(game)
        return RotationOutputViewModel(game: game, players: players, store: store)
    }

    // MARK: - Playing time

    @Test func projectedMinutesCountsAssignedSlots() throws {
        let store = try makeStore()
        let players = makePlayers()
        let plan = makePlan(players: players)
        let game = makeGame(players: players, plan: plan)
        let vm = try makeVM(store: store, game: game, players: players)

        // Player 0 is in goalie slot (counts because goalieTimeCountsAsFieldTime = true)
        #expect(vm.projectedMinutes(for: players[0].id) == 10)
        // Player 1 is in attack slot
        #expect(vm.projectedMinutes(for: players[1].id) == 10)
        // Player 4 is on bench
        #expect(vm.projectedMinutes(for: players[4].id) == 0)
    }

    @Test func projectedMinutesExcludesGoalieWhenToggleOff() throws {
        let store = try makeStore()
        let players = makePlayers()
        let plan = makePlan(players: players)
        var game = makeGame(players: players, plan: plan)
        game.fairnessTargets.goalieTimeCountsAsFieldTime = false
        let vm = try makeVM(store: store, game: game, players: players)

        // Player 0 is goalie-only; with toggle off, their time = 0
        #expect(vm.projectedMinutes(for: players[0].id) == 0)
        // Field player still counts
        #expect(vm.projectedMinutes(for: players[1].id) == 10)
    }

    @Test func minutesStatusMetWhenAtOrAboveMinimum() throws {
        let store = try makeStore()
        let players = makePlayers()
        let plan = makePlan(players: players)
        let game = makeGame(players: players, plan: plan)
        let vm = try makeVM(store: store, game: game, players: players)

        // Developing minimum = 6 min, player gets 10 min → .met
        #expect(vm.minutesStatus(for: players[1].id) == .met)
    }

    @Test func minutesStatusViolationWhenBelowMinimum() throws {
        let store = try makeStore()
        let players = makePlayers()
        let plan = makePlan(players: players)
        let game = makeGame(players: players, plan: plan)
        let vm = try makeVM(store: store, game: game, players: players)

        // Player 4 is benched (0 min), developing minimum = 6 → .violation
        #expect(vm.minutesStatus(for: players[4].id) == .violation)
    }

    // MARK: - Tap-to-swap

    @Test func tapCellShowsActionMenu() throws {
        let store = try makeStore()
        let players = makePlayers()
        let plan = makePlan(players: players)
        let game = makeGame(players: players, plan: plan)
        let vm = try makeVM(store: store, game: game, players: players)

        vm.tapCell(slotIndex: 0, position: .goalie, playerID: players[0].id)
        #expect(vm.cellActionMenuTarget == RotationOutputViewModel.CellID(slotIndex: 0, position: .goalie))
        #expect(vm.swapSourceCell == nil)
    }

    @Test func initiateSwapModeEntersSwapState() throws {
        let store = try makeStore()
        let players = makePlayers()
        let plan = makePlan(players: players)
        let game = makeGame(players: players, plan: plan)
        let vm = try makeVM(store: store, game: game, players: players)

        vm.tapCell(slotIndex: 0, position: .goalie, playerID: players[0].id)
        vm.initiateSwapMode()
        #expect(vm.swapSourceCell == RotationOutputViewModel.CellID(slotIndex: 0, position: .goalie))
        #expect(vm.cellActionMenuTarget == nil)
    }

    @Test func cancelSwapClearsSwapSource() throws {
        let store = try makeStore()
        let players = makePlayers()
        let plan = makePlan(players: players)
        let game = makeGame(players: players, plan: plan)
        let vm = try makeVM(store: store, game: game, players: players)

        vm.tapCell(slotIndex: 0, position: .goalie, playerID: players[0].id)
        vm.initiateSwapMode()
        vm.cancelSwap()
        #expect(vm.swapSourceCell == nil)
    }

    @Test func tapTwoDifferentCellsSwapsPlayers() throws {
        let store = try makeStore()
        let players = makePlayers()
        let plan = makePlan(players: players)
        let game = makeGame(players: players, plan: plan)
        let vm = try makeVM(store: store, game: game, players: players)

        let goalieID = players[0].id
        let attackID = players[1].id

        vm.tapCell(slotIndex: 0, position: .goalie, playerID: players[0].id)
        vm.initiateSwapMode()
        vm.tapCell(slotIndex: 0, position: .attack, playerID: players[1].id)

        let newGoalieID = vm.plan?.slots[0].assignments.first { $0.position == .goalie }?.playerID
        let newAttackID = vm.plan?.slots[0].assignments.first { $0.position == .attack }?.playerID

        #expect(newGoalieID == attackID)
        #expect(newAttackID == goalieID)
        #expect(vm.swapSourceCell == nil)
    }

    @Test func swapSetsCanUndo() throws {
        let store = try makeStore()
        let players = makePlayers()
        let plan = makePlan(players: players)
        let game = makeGame(players: players, plan: plan)
        let vm = try makeVM(store: store, game: game, players: players)

        vm.tapCell(slotIndex: 0, position: .goalie, playerID: players[0].id)
        vm.initiateSwapMode()
        vm.tapCell(slotIndex: 0, position: .attack, playerID: players[1].id)

        #expect(vm.canUndo == true)
        #expect(vm.hasManualChanges == true)
    }

    @Test func undoRestoresPreviousPlan() throws {
        let store = try makeStore()
        let players = makePlayers()
        let plan = makePlan(players: players)
        let game = makeGame(players: players, plan: plan)
        let vm = try makeVM(store: store, game: game, players: players)

        let originalGoalieID = players[0].id

        vm.tapCell(slotIndex: 0, position: .goalie, playerID: players[0].id)
        vm.initiateSwapMode()
        vm.tapCell(slotIndex: 0, position: .attack, playerID: players[1].id)
        vm.undo()

        let restoredGoalieID = vm.plan?.slots[0].assignments.first { $0.position == .goalie }?.playerID
        #expect(restoredGoalieID == originalGoalieID)
        #expect(vm.canUndo == false)
    }

    // MARK: - Bench swap

    @Test func benchSwapMovesPlayerFromBenchToField() throws {
        let store = try makeStore()
        let players = makePlayers()
        let plan = makePlan(players: players)
        let game = makeGame(players: players, plan: plan)
        let vm = try makeVM(store: store, game: game, players: players)

        let benchPlayerID = players[4].id
        let displacedID = players[1].id // currently in attack

        vm.initiateBenchSwap(slotIndex: 0, position: .attack)
        #expect(vm.showBenchSwapSheet == true)

        vm.confirmBenchSwap(benchPlayerID: benchPlayerID)

        let newAttackID = vm.plan?.slots[0].assignments.first { $0.position == .attack }?.playerID
        let bench = vm.plan?.slots[0].bench ?? []

        #expect(newAttackID == benchPlayerID)
        #expect(bench.contains(displacedID))
        #expect(!bench.contains(benchPlayerID))
        #expect(vm.showBenchSwapSheet == false)
    }

    // MARK: - Cell locking

    @Test func toggleLockLocksCell() throws {
        let store = try makeStore()
        let players = makePlayers()
        let plan = makePlan(players: players)
        let game = makeGame(players: players, plan: plan)
        let vm = try makeVM(store: store, game: game, players: players)

        let cell = RotationOutputViewModel.CellID(slotIndex: 0, position: .goalie)
        vm.toggleLock(cell: cell)

        #expect(vm.isCellLocked(cell) == true)
        #expect(vm.summaryLockedCount == 1)
    }

    @Test func toggleLockUnlocksLockedCell() throws {
        let store = try makeStore()
        let players = makePlayers()
        var plan = makePlan(players: players)
        plan.slots[0].assignments[0].isLocked = true
        let game = makeGame(players: players, plan: plan)
        let vm = try makeVM(store: store, game: game, players: players)

        let cell = RotationOutputViewModel.CellID(slotIndex: 0, position: .goalie)
        #expect(vm.isCellLocked(cell) == true)
        vm.toggleLock(cell: cell)
        #expect(vm.isCellLocked(cell) == false)
    }

    // MARK: - Remove player

    @Test func removePlayerMovesThemToBench() throws {
        let store = try makeStore()
        let players = makePlayers()
        let plan = makePlan(players: players)
        let game = makeGame(players: players, plan: plan)
        let vm = try makeVM(store: store, game: game, players: players)

        let removedID = players[1].id // attack
        let cell = RotationOutputViewModel.CellID(slotIndex: 0, position: .attack)
        vm.removePlayer(at: cell)

        let assignments = vm.plan?.slots[0].assignments ?? []
        let bench = vm.plan?.slots[0].bench ?? []

        #expect(!assignments.contains { $0.position == .attack })
        #expect(bench.contains(removedID))
        #expect(vm.canUndo == true)
    }

    // MARK: - Violations

    @Test func dismissViolationMarksDismissed() throws {
        let store = try makeStore()
        let players = makePlayers()
        var plan = makePlan(players: players)
        plan.violations = [Violation.noEligiblePlayer(position: .midfield, quarter: 1, subIndex: 0)]
        let game = makeGame(players: players, plan: plan)
        let vm = try makeVM(store: store, game: game, players: players)

        #expect(vm.activeViolations.count == 1)
        vm.dismissViolation(at: 0)
        #expect(vm.activeViolations.isEmpty)
    }

    // MARK: - Undo clears hasManualChanges

    @Test func undoResetsHasManualChanges() throws {
        let store = try makeStore()
        let players = makePlayers()
        let plan = makePlan(players: players)
        let game = makeGame(players: players, plan: plan)
        let vm = try makeVM(store: store, game: game, players: players)

        vm.tapCell(slotIndex: 0, position: .goalie, playerID: players[0].id)
        vm.initiateSwapMode()
        vm.tapCell(slotIndex: 0, position: .attack, playerID: players[1].id)
        #expect(vm.hasManualChanges == true)
        #expect(vm.canUndo == true)

        vm.undo()
        #expect(vm.hasManualChanges == false)
        #expect(vm.canUndo == false)
    }

    // MARK: - Fairness targets update violations

    @Test func saveFairnessTargetsClearsStaleMinutesViolations() throws {
        let store = try makeStore()
        let players = makePlayers()
        var plan = makePlan(players: players)
        // Player 4 is benched — inject a minutesBelowMinimum violation for them
        plan.violations = [Violation.minutesBelowMinimum(playerID: players[4].id, projectedMinutes: 0, minimumMinutes: 6)]
        let game = makeGame(players: players, plan: plan)
        let vm = try makeVM(store: store, game: game, players: players)

        #expect(vm.activeViolations.count == 1)

        // Lower the minimum to 0 so benched player is no longer in violation
        vm.openFairnessEditor()
        vm.editedFairnessTargets = FairnessTargets(
            eliteMinutes: 0,
            strongMinutes: 0,
            developingMinutes: 0,
            learningMinutes: 0,
            beginnerMinutes: 0,
            goalieTimeCountsAsFieldTime: true
        )
        vm.saveFairnessTargets()

        #expect(vm.activeViolations.isEmpty)
    }

    @Test func saveFairnessTargetsAddsNewMinutesViolationsWhenTargetsRise() throws {
        let store = try makeStore()
        let players = makePlayers()
        let plan = makePlan(players: players) // no violations
        let game = makeGame(players: players, plan: plan)
        let vm = try makeVM(store: store, game: game, players: players)

        #expect(vm.activeViolations.isEmpty)

        // Raise minimum so that every player needs more than 10 min → benched players violate
        vm.openFairnessEditor()
        vm.editedFairnessTargets = FairnessTargets(
            eliteMinutes: 99,
            strongMinutes: 99,
            developingMinutes: 99,
            learningMinutes: 99,
            beginnerMinutes: 99,
            goalieTimeCountsAsFieldTime: true
        )
        vm.saveFairnessTargets()

        // All 6 players need 99 min but only get at most 10 → all should violate
        #expect(vm.activeViolations.filter { $0.kind == .minutesBelowMinimum }.count == 6)
    }
}
