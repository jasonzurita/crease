import Foundation

public struct RotationSlot: Codable, Equatable, Sendable {
    public let quarter: Int
    public let subIndex: Int
    public var assignments: [PositionAssignment]
    public var bench: [UUID]

    public init(quarter: Int, subIndex: Int, assignments: [PositionAssignment], bench: [UUID]) {
        self.quarter = quarter
        self.subIndex = subIndex
        self.assignments = assignments
        self.bench = bench
    }
}
