import Foundation

public struct PlayerStat: Codable, Equatable, Identifiable, Sendable {
    public let playerID: UUID
    public var goals: Int
    public var groundBalls: Int
    public var playingTimeSeconds: Int

    public var id: UUID {
        playerID
    }

    public init(playerID: UUID, goals: Int, groundBalls: Int, playingTimeSeconds: Int) {
        self.playerID = playerID
        self.goals = goals
        self.groundBalls = groundBalls
        self.playingTimeSeconds = playingTimeSeconds
    }

    private enum CodingKeys: String, CodingKey {
        case playerID, goals, groundBalls, playingTimeSeconds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playerID = try container.decode(UUID.self, forKey: .playerID)
        goals = try container.decode(Int.self, forKey: .goals)
        groundBalls = try container.decode(Int.self, forKey: .groundBalls)
        playingTimeSeconds = try container.decodeIfPresent(Int.self, forKey: .playingTimeSeconds) ?? 0
    }
}
