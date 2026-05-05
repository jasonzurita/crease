import CRModel
import Foundation

@Observable
@MainActor
final class GameSetupViewModel {
    enum Step: Int, CaseIterable {
        case details = 1
        case attendance = 2
        case options = 3
    }

    var currentStep: Step = .details

    // Step 1 — Details
    var opponent: String = ""
    var date: Date
    var isHome: Bool = true

    // Step 2 — Attendance
    var attendance: [PlayerAttendance]

    // Step 3 — Options
    var format: GameFormatDefaults
    var rotationStyle: RotationStyle = .byQuarter
    var fairnessTargets: FairnessTargets = .default
    var competitivenessMode: CompetitivenessMode = .balanced
    var boostedPlayerIDs: [UUID] = []

    var isCurrentStepValid: Bool {
        switch currentStep {
        case .details:
            return !opponent.trimmingCharacters(in: .whitespaces).isEmpty
        case .attendance, .options:
            return true
        }
    }

    init(formatDefaults: GameFormatDefaults, players: [Player]) {
        self.format = formatDefaults
        self.date = Self.nextSunday()
        self.attendance = players.map {
            PlayerAttendance(id: $0.id, isPresent: true, lateArrivalQuarter: nil, earlyDepartureQuarter: nil)
        }
    }

    func goNext() {
        switch currentStep {
        case .details: currentStep = .attendance
        case .attendance: currentStep = .options
        case .options: break
        }
    }

    func goBack() {
        switch currentStep {
        case .details: break
        case .attendance: currentStep = .details
        case .options: currentStep = .attendance
        }
    }

    func createGame(in store: SeasonStore) throws {
        let game = Game(
            id: UUID(),
            opponent: opponent.trimmingCharacters(in: .whitespaces),
            date: date,
            isHome: isHome,
            status: .planned,
            attendance: attendance,
            format: format,
            rotationStyle: rotationStyle,
            fairnessTargets: fairnessTargets,
            competitivenessMode: competitivenessMode,
            boostedPlayerIDs: boostedPlayerIDs,
            createdAt: Date()
        )
        try store.createGame(game)
    }

    private static func nextSunday() -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysUntilSunday = weekday == 1 ? 7 : 8 - weekday
        return calendar.date(byAdding: .day, value: daysUntilSunday, to: today) ?? today
    }
}
