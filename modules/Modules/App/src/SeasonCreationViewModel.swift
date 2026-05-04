import CRModel
import Foundation
import Observation

@Observable
@MainActor
public final class SeasonCreationViewModel {
    public var teamName: String = ""
    public var seasonName: String = ""
    public var gameFormatDefaults: GameFormatDefaults = .default

    public var isValid: Bool {
        !trimmedTeamName.isEmpty && !trimmedSeasonName.isEmpty
    }

    public init() {}

    public func create(in store: SeasonStore) throws {
        let season = Season(
            id: UUID(),
            teamName: trimmedTeamName,
            seasonName: trimmedSeasonName,
            gameFormatDefaults: gameFormatDefaults,
            createdAt: Date()
        )
        try store.create(season)
    }

    private var trimmedTeamName: String {
        teamName.trimmingCharacters(in: .whitespaces)
    }

    private var trimmedSeasonName: String {
        seasonName.trimmingCharacters(in: .whitespaces)
    }
}
