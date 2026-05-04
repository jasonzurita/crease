import CodablePersistenceClient
import CRModel
import FileManagerClient
import Foundation
import UserDefaultsClient

@Observable
@MainActor
public final class SeasonStore {
    public private(set) var seasons: [Season] = []
    public private(set) var activeSeason: Season?

    private let persistenceClient: CodablePersistenceClient<Season>
    private let userDefaultsClient: UserDefaultsClient

    public init(fileManagerClient: FileManagerClient, userDefaultsClient: UserDefaultsClient) {
        self.userDefaultsClient = userDefaultsClient

        let client: CodablePersistenceClient<Season>
        do {
            let documentsURL = try fileManagerClient.url(.documentDirectory, .userDomainMask, nil, false)
            let seasonsURL = documentsURL.appending(component: "Seasons")
            if !fileManagerClient.fileExistsAtPath(seasonsURL.path) {
                try fileManagerClient.createDirectory(seasonsURL, true)
            }
            client = CodablePersistenceClient<Season>(
                save: { season, id in
                    let seasonDir = seasonsURL.appending(component: id)
                    if !fileManagerClient.fileExistsAtPath(seasonDir.path) {
                        try fileManagerClient.createDirectory(seasonDir, true)
                    }
                    let encoder = JSONEncoder()
                    encoder.dateEncodingStrategy = .iso8601
                    encoder.outputFormatting = .prettyPrinted
                    let data = try encoder.encode(season)
                    try fileManagerClient.writeData(data, seasonDir.appending(component: "season.json"))
                },
                getAll: {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let subdirs = try fileManagerClient.contentsOfDirectoryUrls(
                        seasonsURL, nil, [.skipsHiddenFiles]
                    )
                    return try subdirs.compactMap { dir in
                        guard let data = fileManagerClient.contents(
                            dir.appending(component: "season.json").path
                        ) else { return nil }
                        return try decoder.decode(Season.self, from: data)
                    }
                },
                delete: { id in
                    try fileManagerClient.removeItem(seasonsURL.appending(component: id))
                }
            )
        } catch {
            logger.error("Seasons directory setup failed: \(error)")
            client = .mock()
        }

        persistenceClient = client

        do {
            seasons = try persistenceClient.getAll()
        } catch {
            logger.error("Failed to load seasons: \(error)")
        }

        let activeID = userDefaultsClient.stringForKey("cr_active_season_id")
        activeSeason = seasons.first { $0.id.uuidString == activeID } ?? seasons.first
    }

    public func create(_ season: Season) throws {
        try persistenceClient.save(season, season.id.uuidString)
        seasons.append(season)
        setActive(season)
    }

    public func setActive(_ season: Season) {
        activeSeason = season
        userDefaultsClient.storeString(season.id.uuidString, "cr_active_season_id")
    }
}
