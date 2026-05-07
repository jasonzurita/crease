import CRModel
import Foundation
import Observation

@Observable
@MainActor
final class CompletionSheetViewModel {
    var usScore: Int = 0
    var themScore: Int = 0
    var opponentGroundBalls: Int = 0
    var playerStats: [PlayerStat]

    init(players: [Player]) {
        playerStats = players.map { PlayerStat(playerID: $0.id, goals: 0, groundBalls: 0) }
    }

    func makeStats() -> GameStats {
        GameStats(
            usScore: usScore,
            themScore: themScore,
            playerStats: playerStats,
            opponentGroundBalls: opponentGroundBalls
        )
    }
}
