public struct FairnessTargets: Codable, Equatable, Sendable {
    public var eliteMinutes: Int
    public var strongMinutes: Int
    public var developingMinutes: Int
    public var learningMinutes: Int
    public var beginnerMinutes: Int
    public var goalieTimeCountsAsFieldTime: Bool

    public init(
        eliteMinutes: Int,
        strongMinutes: Int,
        developingMinutes: Int,
        learningMinutes: Int,
        beginnerMinutes: Int,
        goalieTimeCountsAsFieldTime: Bool
    ) {
        self.eliteMinutes = eliteMinutes
        self.strongMinutes = strongMinutes
        self.developingMinutes = developingMinutes
        self.learningMinutes = learningMinutes
        self.beginnerMinutes = beginnerMinutes
        self.goalieTimeCountsAsFieldTime = goalieTimeCountsAsFieldTime
    }

    public static let `default` = FairnessTargets(
        eliteMinutes: 20,
        strongMinutes: 18,
        developingMinutes: 15,
        learningMinutes: 12,
        beginnerMinutes: 10,
        goalieTimeCountsAsFieldTime: true
    )

    public func minutes(for tier: Tier) -> Int {
        switch tier {
        case .elite: eliteMinutes
        case .strong: strongMinutes
        case .developing: developingMinutes
        case .learning: learningMinutes
        case .beginner: beginnerMinutes
        }
    }

    public mutating func setMinutes(_ minutes: Int, for tier: Tier) {
        switch tier {
        case .elite: eliteMinutes = minutes
        case .strong: strongMinutes = minutes
        case .developing: developingMinutes = minutes
        case .learning: learningMinutes = minutes
        case .beginner: beginnerMinutes = minutes
        }
    }
}
