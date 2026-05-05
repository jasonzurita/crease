import Foundation

public struct PositionAssignment: Codable, Equatable, Sendable {
    public let position: Position
    public let playerID: UUID

    public init(position: Position, playerID: UUID) {
        self.position = position
        self.playerID = playerID
    }
}
