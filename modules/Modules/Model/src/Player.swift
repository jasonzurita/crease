import Foundation

public struct Player: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var jerseyNumber: Int
    public var positions: Set<Position>
    public var tier: Tier
    public var avatarImageData: Data?

    public init(
        id: UUID,
        name: String,
        jerseyNumber: Int,
        positions: Set<Position>,
        tier: Tier,
        avatarImageData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.jerseyNumber = jerseyNumber
        self.positions = positions
        self.tier = tier
        self.avatarImageData = avatarImageData
    }

    public var initials: String {
        let words = name.split(separator: " ").map(String.init)
        let first = words.first?.first.map(String.init) ?? ""
        let last = words.dropFirst().last?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }
}
