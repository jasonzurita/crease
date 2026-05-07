import Foundation

public struct GameStats: Codable, Equatable, Sendable {
    public var usScore: Int
    public var themScore: Int
    public var playerStats: [PlayerStat]
    public var opponentGroundBalls: Int

    public init(usScore: Int, themScore: Int, playerStats: [PlayerStat], opponentGroundBalls: Int) {
        self.usScore = usScore
        self.themScore = themScore
        self.playerStats = playerStats
        self.opponentGroundBalls = opponentGroundBalls
    }
}
