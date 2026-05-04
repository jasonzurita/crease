@testable import CRModel
import Foundation
import Testing

@Suite("Season")
struct SeasonTests {
    private let fixedID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

    @Test func codableRoundTrip() throws {
        let original = Season(
            id: fixedID,
            teamName: "Eagles",
            seasonName: "Spring 2025",
            gameFormatDefaults: .default,
            createdAt: fixedDate
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Season.self, from: data)
        #expect(decoded == original)
    }

    @Test func encodesExpectedKeys() throws {
        let season = Season(
            id: fixedID,
            teamName: "Eagles",
            seasonName: "Spring 2025",
            gameFormatDefaults: .default,
            createdAt: fixedDate
        )
        let data = try JSONEncoder().encode(season)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["id"] != nil)
        #expect(json?["teamName"] as? String == "Eagles")
        #expect(json?["seasonName"] as? String == "Spring 2025")
        #expect(json?["gameFormatDefaults"] != nil)
        #expect(json?["createdAt"] != nil)
    }
}

@Suite("GameFormatDefaults")
struct GameFormatDefaultsTests {
    @Test func defaultValues() {
        let defaults = GameFormatDefaults.default
        #expect(defaults.quarters == 4)
        #expect(defaults.quarterLengthMinutes == 10)
        #expect(defaults.playersPerSide == 7)
        #expect(defaults.midQuarterSubsEnabled == true)
    }

    @Test func codableRoundTrip() throws {
        let original = GameFormatDefaults.default
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(GameFormatDefaults.self, from: data)
        #expect(decoded == original)
    }
}
