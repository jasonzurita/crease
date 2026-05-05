import CodablePersistenceClient
import CRModel
import FileManagerClient
import Foundation
import RotationSolver
import UserDefaultsClient

@Observable
@MainActor
public final class SeasonStore {
    public private(set) var seasons: [Season] = []
    public private(set) var activeSeason: Season?
    public private(set) var players: [Player] = []
    public private(set) var games: [Game] = []

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
        loadGames()
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
        loadGames()
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

    // MARK: - Games

    public func createGame(_ game: Game) throws {
        games.append(game)
        games.sort { $0.date > $1.date }
        try saveGame(game)
    }

    public func updateGame(_ game: Game) throws {
        guard let index = games.firstIndex(where: { $0.id == game.id }) else { return }
        games[index] = game
        try saveGame(game)
    }

    public func deleteGame(_ game: Game) throws {
        games.removeAll { $0.id == game.id }
        guard let season = activeSeason, let url = gameURL(for: season, game: game) else { return }
        try fileManagerClient.removeItem(url)
    }

    public func generatePlan(for game: Game) throws {
        var updated = game
        updated.rotationPlan = RotationSolver.solve(game: game, players: players)
        updated.status = .ready
        try updateGame(updated)
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

    private func gamesDirectoryURL(for season: Season) -> URL? {
        seasonsURL?
            .appending(component: season.id.uuidString)
            .appending(component: "Games")
    }

    private func gameURL(for season: Season, game: Game) -> URL? {
        gamesDirectoryURL(for: season)?
            .appending(component: "game_\(game.id.uuidString).json")
    }

    private func loadGames() {
        guard let season = activeSeason,
              let gamesDir = gamesDirectoryURL(for: season) else {
            games = []
            return
        }
        do {
            try fileManagerClient.createDirectory(gamesDir, true)
            let files = try fileManagerClient.contentsOfDirectoryUrls(gamesDir, nil, [.skipsHiddenFiles])
            games = try files.compactMap { url in
                guard let data = fileManagerClient.contents(url.path) else { return nil }
                return try decoder.decode(Game.self, from: data)
            }
            games.sort { $0.date > $1.date }
        } catch {
            logger.error("Failed to load games: \(error)")
            games = []
        }
    }

    private func saveGame(_ game: Game) throws {
        guard let season = activeSeason,
              let gamesDir = gamesDirectoryURL(for: season),
              let url = gameURL(for: season, game: game) else { return }
        try fileManagerClient.createDirectory(gamesDir, true)
        let data = try encoder.encode(game)
        try fileManagerClient.writeData(data, url)
    }
}
