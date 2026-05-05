public enum RotationStyle: Equatable, Sendable {
    case byQuarter
    case byTimeInterval(intervalMinutes: Int)
}

extension RotationStyle: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case intervalMinutes
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "byQuarter":
            self = .byQuarter
        case "byTimeInterval":
            let minutes = try container.decode(Int.self, forKey: .intervalMinutes)
            self = .byTimeInterval(intervalMinutes: minutes)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown rotation style: \(type)"
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .byQuarter:
            try container.encode("byQuarter", forKey: .type)
        case .byTimeInterval(let minutes):
            try container.encode("byTimeInterval", forKey: .type)
            try container.encode(minutes, forKey: .intervalMinutes)
        }
    }
}
