public enum Position: String, Codable, CaseIterable, Hashable, Sendable {
    case attack = "Attack"
    case midfield = "Midfield"
    case defense = "Defense"
    case goalie = "Goalie"
}
