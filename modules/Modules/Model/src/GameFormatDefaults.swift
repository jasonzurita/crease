import Foundation

public struct GameFormatDefaults: Codable, Equatable, Sendable {
    public var quarters: Int
    public var quarterLengthMinutes: Int
    public var playersPerSide: Int
    public var midQuarterSubsEnabled: Bool

    public init(
        quarters: Int,
        quarterLengthMinutes: Int,
        playersPerSide: Int,
        midQuarterSubsEnabled: Bool
    ) {
        self.quarters = quarters
        self.quarterLengthMinutes = quarterLengthMinutes
        self.playersPerSide = playersPerSide
        self.midQuarterSubsEnabled = midQuarterSubsEnabled
    }

    public static let `default` = GameFormatDefaults(
        quarters: 4,
        quarterLengthMinutes: 10,
        playersPerSide: 7,
        midQuarterSubsEnabled: true
    )
}
