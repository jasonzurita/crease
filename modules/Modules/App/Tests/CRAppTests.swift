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
