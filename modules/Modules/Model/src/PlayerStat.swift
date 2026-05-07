import Foundation

public struct PlayerStat: Codable, Equatable, Identifiable, Sendable {
    public let playerID: UUID
    public var goals: Int
    public var groundBalls: Int

    public var id: UUID {
        playerID
    }

    public init(playerID: UUID, goals: Int, groundBalls: Int) {
        self.playerID = playerID
        self.goals = goals
        self.groundBalls = groundBalls
    }
}
