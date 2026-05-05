import Foundation

public struct Game: Codable, Equatable, Hashable, Identifiable, Sendable {
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
    public var rotationPlan: RotationPlan?
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
        rotationPlan: RotationPlan? = nil,
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
        self.rotationPlan = rotationPlan
        self.createdAt = createdAt
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
