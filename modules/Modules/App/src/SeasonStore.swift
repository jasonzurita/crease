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
    public private(set) var players: [Player] = []

    private let persistenceClient: CodablePersistenceClient<Season>
    private let fileManagerClient: FileManagerClient
    private let userDefaultsClient: UserDefaultsClient
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var seasonsURL: URL?

    private static let activeSeasonKey = "cr_active_season_id"

    public init(fileManagerClient: FileManagerClient, userDefaultsClient: UserDefaultsClient) {
        self.fileManagerClient = fileManagerClient
        self.userDefaultsClient = userDefaultsClient

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.encoder = encoder
        self.decoder = decoder

        let client: CodablePersistenceClient<Season>
        var resolvedSeasonsURL: URL?
        do {
            let documentsURL = try fileManagerClient.url(.documentDirectory, .userDomainMask, nil, false)
            let seasonsURL = documentsURL.appending(component: "Seasons")
            try fileManagerClient.createDirectory(seasonsURL, true)
            resolvedSeasonsURL = seasonsURL
            client = CodablePersistenceClient<Season>(
                save: { season, id in
                    let seasonDir = seasonsURL.appending(component: id)
                    try fileManagerClient.createDirectory(seasonDir, true)
                    let data = try encoder.encode(season)
                    try fileManagerClient.writeData(data, seasonDir.appending(component: "season.json"))
                },
                getAll: {
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
        seasonsURL = resolvedSeasonsURL

        do {
            seasons = try persistenceClient.getAll()
        } catch {
            logger.error("Failed to load seasons: \(error)")
        }

        let activeID = userDefaultsClient.stringForKey(Self.activeSeasonKey)
        activeSeason = seasons.first { $0.id.uuidString == activeID } ?? seasons.first

        loadRoster()
    }

    public func create(_ season: Season) throws {
        try persistenceClient.save(season, season.id.uuidString)
        seasons.append(season)
        setActive(season)
    }

    public func setActive(_ season: Season) {
        activeSeason = season
        userDefaultsClient.storeString(season.id.uuidString, Self.activeSeasonKey)
        loadRoster()
    }

    // MARK: - Roster

    public func createPlayer(_ player: Player) throws {
        players.append(player)
        try saveRoster()
    }

    public func updatePlayer(_ player: Player) throws {
        guard let index = players.firstIndex(where: { $0.id == player.id }) else { return }
        players[index] = player
        try saveRoster()
    }

    public func deletePlayer(_ player: Player) throws {
        players.removeAll { $0.id == player.id }
        try saveRoster()
    }

    // MARK: - Private

    private func rosterURL(for season: Season) -> URL? {
        seasonsURL?.appending(component: season.id.uuidString).appending(component: "roster.json")
    }

    private func loadRoster() {
        guard let season = activeSeason, let url = rosterURL(for: season) else {
            players = []
            return
        }
        guard let data = fileManagerClient.contents(url.path) else {
            players = []
            return
        }
        do {
            players = try decoder.decode([Player].self, from: data)
        } catch {
            logger.error("Failed to load roster: \(error)")
            players = []
        }
    }

    private func saveRoster() throws {
        guard let season = activeSeason, let url = rosterURL(for: season) else { return }
        let data = try encoder.encode(players)
        try fileManagerClient.writeData(data, url)
    }
}
