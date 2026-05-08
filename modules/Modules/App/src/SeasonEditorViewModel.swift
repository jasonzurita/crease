import CRModel
import Foundation
import Observation

@Observable
@MainActor
final class SeasonEditorViewModel {
    var teamName: String
    var seasonName: String
    var gameFormatDefaults: GameFormatDefaults

    private let season: Season

    init(season: Season) {
        self.season = season
        teamName = season.teamName
        seasonName = season.seasonName
        gameFormatDefaults = season.gameFormatDefaults
    }

    var isValid: Bool {
        !teamName.trimmingCharacters(in: .whitespaces).isEmpty &&
            !seasonName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func save(in store: SeasonStore) throws {
        var updated = season
        updated.teamName = teamName.trimmingCharacters(in: .whitespaces)
        updated.seasonName = seasonName.trimmingCharacters(in: .whitespaces)
        var defaults = gameFormatDefaults
        defaults.playersPerSide = gameFormatDefaults.derivedPlayersPerSide
        updated.gameFormatDefaults = defaults
        try store.updateSeason(updated)
    }
}
