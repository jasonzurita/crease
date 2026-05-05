import Foundation

public struct Game: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var opponent: String
    public var date: Date
    public var isHome: Bool
    public var status: GameStatus
    public var attendance: [PlayerAttendance]
    public var format: GameFormatDefaults
    public var rotationStyle: RotationStyle
    public var fairnessTargets: FairnessTargets
    public var competitivenessMode: CompetitivenessMode
    public var boostedPlayerIDs: [UUID]
    public let createdAt: Date

    public init(
        id: UUID,
        opponent: String,
        date: Date,
        isHome: Bool,
        status: GameStatus,
        attendance: [PlayerAttendance],
        format: GameFormatDefaults,
        rotationStyle: RotationStyle,
        fairnessTargets: FairnessTargets,
        competitivenessMode: CompetitivenessMode,
        boostedPlayerIDs: [UUID],
        createdAt: Date
    ) {
        self.id = id
        self.opponent = opponent
        self.date = date
        self.isHome = isHome
        self.status = status
        self.attendance = attendance
        self.format = format
        self.rotationStyle = rotationStyle
        self.fairnessTargets = fairnessTargets
        self.competitivenessMode = competitivenessMode
        self.boostedPlayerIDs = boostedPlayerIDs
        self.createdAt = createdAt
    }
}
