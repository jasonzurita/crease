import Foundation

public struct Player: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var jerseyNumber: Int
    public var positions: Set<Position>
    public var tier: Tier

    public init(
        id: UUID,
        name: String,
        jerseyNumber: Int,
        positions: Set<Position>,
        tier: Tier
    ) {
        self.id = id
        self.name = name
        self.jerseyNumber = jerseyNumber
        self.positions = positions
        self.tier = tier
    }
}
