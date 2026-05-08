import Foundation

public struct GameFormatDefaults: Codable, Equatable, Sendable {
    public var quarters: Int
    public var quarterLengthMinutes: Int
    public var playersPerSide: Int
    public var positionCounts: PositionCounts?

    public init(
        quarters: Int,
        quarterLengthMinutes: Int,
        playersPerSide: Int,
        positionCounts: PositionCounts? = nil
    ) {
        self.quarters = quarters
        self.quarterLengthMinutes = quarterLengthMinutes
        self.playersPerSide = playersPerSide
        self.positionCounts = positionCounts
    }

    public static let `default` = GameFormatDefaults(
        quarters: 4,
        quarterLengthMinutes: 10,
        playersPerSide: 7
    )

    /// Effective counts to use for rotation generation — uses explicit override when set,
    /// otherwise distributes field players evenly across attack/midfield/defense.
    public var effectivePositionCounts: PositionCounts {
        if let counts = positionCounts { return counts }
        let fieldPlayers = max(0, playersPerSide - 1)
        let base = fieldPlayers / 3
        let remainder = fieldPlayers % 3
        return PositionCounts(
            attack: base + (remainder > 0 ? 1 : 0),
            midfield: base + (remainder > 1 ? 1 : 0),
            defense: base
        )
    }
}
