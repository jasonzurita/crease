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
        !teamName.trimmingCharacters(in: .whitespaces).isEmpty
            && !seasonName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    public init() {}

    public func create(in store: SeasonStore) throws {
        let season = Season(
            id: UUID(),
            teamName: teamName.trimmingCharacters(in: .whitespaces),
            seasonName: seasonName.trimmingCharacters(in: .whitespaces),
            gameFormatDefaults: gameFormatDefaults,
            createdAt: Date()
        )
        try store.create(season)
    }
}
