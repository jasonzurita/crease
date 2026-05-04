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
