public struct RotationPlan: Codable, Equatable, Sendable {
    public var slots: [RotationSlot]
    public var violations: [Violation]

    public init(slots: [RotationSlot], violations: [Violation]) {
        self.slots = slots
        self.violations = violations
    }
}
