import Foundation

public struct GameFormatDefaults: Codable, Equatable, Sendable {
    public var quarters: Int
    public var quarterLengthMinutes: Int
    public var playersPerSide: Int

    public init(
        quarters: Int,
        quarterLengthMinutes: Int,
        playersPerSide: Int
    ) {
        self.quarters = quarters
        self.quarterLengthMinutes = quarterLengthMinutes
        self.playersPerSide = playersPerSide
    }

    public static let `default` = GameFormatDefaults(
        quarters: 4,
        quarterLengthMinutes: 10,
        playersPerSide: 7
    )
}
