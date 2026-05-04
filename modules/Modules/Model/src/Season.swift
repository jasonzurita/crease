import Foundation

public struct Season: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var teamName: String
    public var seasonName: String
    public var gameFormatDefaults: GameFormatDefaults
    public let createdAt: Date

    public init(
        id: UUID,
        teamName: String,
        seasonName: String,
        gameFormatDefaults: GameFormatDefaults,
        createdAt: Date
    ) {
        self.id = id
        self.teamName = teamName
        self.seasonName = seasonName
        self.gameFormatDefaults = gameFormatDefaults
        self.createdAt = createdAt
    }
}
