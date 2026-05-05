import Foundation

public struct PlayerAttendance: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var isPresent: Bool
    public var lateArrivalQuarter: Int?
    public var earlyDepartureQuarter: Int?

    public init(id: UUID, isPresent: Bool, lateArrivalQuarter: Int?, earlyDepartureQuarter: Int?) {
        self.id = id
        self.isPresent = isPresent
        self.lateArrivalQuarter = lateArrivalQuarter
        self.earlyDepartureQuarter = earlyDepartureQuarter
    }
}
