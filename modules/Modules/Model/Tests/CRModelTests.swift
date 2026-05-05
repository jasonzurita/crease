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

@Suite("Player")
struct PlayerTests {
    private let fixedID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    @Test func codableRoundTrip() throws {
        let original = Player(
            id: fixedID,
            name: "Alex Johnson",
            jerseyNumber: 12,
            positions: [.midfield, .attack],
            tier: .strong
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Player.self, from: data)
        #expect(decoded == original)
    }

    @Test func encodesExpectedKeys() throws {
        let player = Player(
            id: fixedID,
            name: "Alex Johnson",
            jerseyNumber: 12,
            positions: [.midfield],
            tier: .elite
        )
        let data = try JSONEncoder().encode(player)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["id"] != nil)
        #expect(json?["name"] as? String == "Alex Johnson")
        #expect(json?["jerseyNumber"] as? Int == 12)
        #expect(json?["positions"] != nil)
        #expect(json?["tier"] as? String == "Elite")
    }

    @Test func goalieWithFieldPositions() throws {
        let player = Player(
            id: fixedID,
            name: "Sam Lee",
            jerseyNumber: 1,
            positions: [.goalie, .defense],
            tier: .developing
        )
        let data = try JSONEncoder().encode(player)
        let decoded = try JSONDecoder().decode(Player.self, from: data)
        #expect(decoded.positions.contains(.goalie))
        #expect(decoded.positions.contains(.defense))
        #expect(decoded.positions.count == 2)
    }
}

@Suite("Tier")
struct TierTests {
    @Test func allCasesOrdered() {
        let cases = Tier.allCases
        #expect(cases[0] == .elite)
        #expect(cases[1] == .strong)
        #expect(cases[2] == .developing)
        #expect(cases[3] == .learning)
        #expect(cases[4] == .beginner)
    }

    @Test func codableRoundTrip() throws {
        for tier in Tier.allCases {
            let data = try JSONEncoder().encode(tier)
            let decoded = try JSONDecoder().decode(Tier.self, from: data)
            #expect(decoded == tier)
        }
    }
}

@Suite("Position")
struct PositionTests {
    @Test func codableRoundTrip() throws {
        for position in Position.allCases {
            let data = try JSONEncoder().encode(position)
            let decoded = try JSONDecoder().decode(Position.self, from: data)
            #expect(decoded == position)
        }
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

@Suite("Game")
struct GameTests {
    private let fixedID = UUID(uuidString: "00000000-0000-0000-0000-000000000010")!
    private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeGame(rotationStyle: RotationStyle = .byQuarter) -> Game {
        Game(
            id: fixedID,
            opponent: "Hawks",
            date: fixedDate,
            isHome: true,
            status: .planned,
            attendance: [],
            format: .default,
            rotationStyle: rotationStyle,
            fairnessTargets: .default,
            competitivenessMode: .balanced,
            boostedPlayerIDs: [],
            createdAt: fixedDate
        )
    }

    @Test func codableRoundTrip() throws {
        let original = makeGame()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Game.self, from: data)
        #expect(decoded == original)
    }

    @Test func byTimeIntervalStyleRoundTrip() throws {
        let original = makeGame(rotationStyle: .byTimeInterval(intervalMinutes: 8))
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Game.self, from: data)
        #expect(decoded.rotationStyle == .byTimeInterval(intervalMinutes: 8))
    }

    @Test func attendancePreservedRoundTrip() throws {
        let playerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        var game = makeGame()
        game.attendance = [PlayerAttendance(id: playerID, isPresent: true, lateArrivalQuarter: 2, earlyDepartureQuarter: nil)]
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try encoder.encode(game)
        let decoded = try decoder.decode(Game.self, from: data)
        #expect(decoded.attendance.count == 1)
        #expect(decoded.attendance.first?.lateArrivalQuarter == 2)
    }
}

@Suite("RotationStyle")
struct RotationStyleTests {
    @Test func byQuarterRoundTrip() throws {
        let style = RotationStyle.byQuarter
        let data = try JSONEncoder().encode(style)
        let decoded = try JSONDecoder().decode(RotationStyle.self, from: data)
        #expect(decoded == .byQuarter)
    }

    @Test func byTimeIntervalRoundTrip() throws {
        let style = RotationStyle.byTimeInterval(intervalMinutes: 8)
        let data = try JSONEncoder().encode(style)
        let decoded = try JSONDecoder().decode(RotationStyle.self, from: data)
        #expect(decoded == .byTimeInterval(intervalMinutes: 8))
    }
}

@Suite("FairnessTargets")
struct FairnessTargetsTests {
    @Test func defaultValues() {
        let targets = FairnessTargets.default
        #expect(targets.eliteMinutes == 20)
        #expect(targets.strongMinutes == 18)
        #expect(targets.developingMinutes == 15)
        #expect(targets.learningMinutes == 12)
        #expect(targets.beginnerMinutes == 10)
        #expect(targets.goalieTimeCountsAsFieldTime == true)
    }

    @Test func minutesForTier() {
        let targets = FairnessTargets.default
        #expect(targets.minutes(for: .elite) == 20)
        #expect(targets.minutes(for: .strong) == 18)
        #expect(targets.minutes(for: .developing) == 15)
        #expect(targets.minutes(for: .learning) == 12)
        #expect(targets.minutes(for: .beginner) == 10)
    }

    @Test func codableRoundTrip() throws {
        let original = FairnessTargets.default
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FairnessTargets.self, from: data)
        #expect(decoded == original)
    }
}

@Suite("PlayerAttendance")
struct PlayerAttendanceTests {
    private let fixedID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    @Test func codableRoundTrip() throws {
        let attendance = PlayerAttendance(
            id: fixedID,
            isPresent: true,
            lateArrivalQuarter: 2,
            earlyDepartureQuarter: 4
        )
        let data = try JSONEncoder().encode(attendance)
        let decoded = try JSONDecoder().decode(PlayerAttendance.self, from: data)
        #expect(decoded == attendance)
    }

    @Test func absentWithNoConflicts() throws {
        let attendance = PlayerAttendance(
            id: fixedID,
            isPresent: false,
            lateArrivalQuarter: nil,
            earlyDepartureQuarter: nil
        )
        let data = try JSONEncoder().encode(attendance)
        let decoded = try JSONDecoder().decode(PlayerAttendance.self, from: data)
        #expect(decoded.isPresent == false)
        #expect(decoded.lateArrivalQuarter == nil)
        #expect(decoded.earlyDepartureQuarter == nil)
    }
}

@Suite("GameStatus")
struct GameStatusTests {
    @Test func codableRoundTrip() throws {
        for status in GameStatus.allCases {
            let data = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(GameStatus.self, from: data)
            #expect(decoded == status)
        }
    }
}

@Suite("CompetitivenessMode")
struct CompetitivenessModeTests {
    @Test func allCasesOrdered() {
        let cases = CompetitivenessMode.allCases
        #expect(cases[0] == .fair)
        #expect(cases[1] == .balanced)
        #expect(cases[2] == .competitive)
    }

    @Test func codableRoundTrip() throws {
        for mode in CompetitivenessMode.allCases {
            let data = try JSONEncoder().encode(mode)
            let decoded = try JSONDecoder().decode(CompetitivenessMode.self, from: data)
            #expect(decoded == mode)
        }
    }
}
