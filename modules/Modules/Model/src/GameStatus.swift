public enum GameStatus: String, Codable, Equatable, CaseIterable, Sendable {
    case planned = "Planned"
    case ready = "Ready"
    case complete = "Complete"
}
