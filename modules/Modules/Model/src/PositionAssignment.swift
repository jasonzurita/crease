import Foundation

public struct PositionAssignment: Codable, Equatable, Sendable {
    public let position: Position
    public let playerID: UUID
    public var isLocked: Bool

    public init(position: Position, playerID: UUID, isLocked: Bool) {
        self.position = position
        self.playerID = playerID
        self.isLocked = isLocked
    }

    private enum CodingKeys: String, CodingKey {
        case position, playerID, isLocked
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        position = try container.decode(Position.self, forKey: .position)
        playerID = try container.decode(UUID.self, forKey: .playerID)
        isLocked = try container.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(position, forKey: .position)
        try container.encode(playerID, forKey: .playerID)
        try container.encode(isLocked, forKey: .isLocked)
    }
}
