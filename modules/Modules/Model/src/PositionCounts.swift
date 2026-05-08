import Foundation

public struct PositionCounts: Codable, Equatable, Sendable {
    public var attack: Int
    public var midfield: Int
    public var defense: Int

    public var fieldTotal: Int {
        attack + midfield + defense
    }

    public init(attack: Int, midfield: Int, defense: Int) {
        self.attack = attack
        self.midfield = midfield
        self.defense = defense
    }
}
