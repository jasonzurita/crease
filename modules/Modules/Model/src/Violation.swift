import Foundation

public struct Violation: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Equatable, Sendable {
        case minutesBelowMinimum
        case noEligiblePlayer
    }

    public let kind: Kind
    public let playerID: UUID?
    public let projectedMinutes: Int?
    public let minimumMinutes: Int?
    public let position: Position?
    public let quarter: Int?
    public let subIndex: Int?
    public var isDismissed: Bool

    private init(
        kind: Kind,
        playerID: UUID?,
        projectedMinutes: Int?,
        minimumMinutes: Int?,
        position: Position?,
        quarter: Int?,
        subIndex: Int?,
        isDismissed: Bool
    ) {
        self.kind = kind
        self.playerID = playerID
        self.projectedMinutes = projectedMinutes
        self.minimumMinutes = minimumMinutes
        self.position = position
        self.quarter = quarter
        self.subIndex = subIndex
        self.isDismissed = isDismissed
    }

    public static func minutesBelowMinimum(
        playerID: UUID,
        projectedMinutes: Int,
        minimumMinutes: Int
    ) -> Violation {
        Violation(
            kind: .minutesBelowMinimum,
            playerID: playerID,
            projectedMinutes: projectedMinutes,
            minimumMinutes: minimumMinutes,
            position: nil,
            quarter: nil,
            subIndex: nil,
            isDismissed: false
        )
    }

    public static func noEligiblePlayer(position: Position, quarter: Int, subIndex: Int) -> Violation {
        Violation(
            kind: .noEligiblePlayer,
            playerID: nil,
            projectedMinutes: nil,
            minimumMinutes: nil,
            position: position,
            quarter: quarter,
            subIndex: subIndex,
            isDismissed: false
        )
    }
}
