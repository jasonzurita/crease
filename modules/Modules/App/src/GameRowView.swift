import CRDesign
import CRModel
import SwiftUI

struct GameRowView: View {
    private let game: Game

    init(game: Game) {
        self.game = game
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(monthAbbrev)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.crAccent)
                Text(dayNumber)
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color.crTextPrimary)
            }
            .frame(width: 40)

            Rectangle()
                .fill(Color.crTextSecondary.opacity(0.3))
                .frame(width: 1, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text("vs. \(game.opponent)")
                    .font(.headline)
                    .foregroundStyle(Color.crTextPrimary)
                HStack(spacing: 8) {
                    Text(game.isHome ? "Home" : "Away")
                        .font(.caption)
                        .foregroundStyle(Color.crTextSecondary)
                    statusBadge
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var monthAbbrev: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: game.date)
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: game.date)
    }

    private var statusBadge: some View {
        Text(game.status.rawValue)
            .font(.caption.weight(.semibold))
            .foregroundStyle(statusColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var statusColor: Color {
        switch game.status {
        case .planned: Color.crTextSecondary
        case .ready: Color.crAccent
        case .complete: Color.crSuccess
        }
    }
}

#Preview {
    ZStack {
        Color.crBackground.ignoresSafeArea()
        GameRowView(game: Game(
            id: UUID(),
            opponent: "Hawks",
            date: Date(),
            isHome: true,
            status: .planned,
            attendance: [],
            format: .default,
            rotationStyle: .byQuarter,
            fairnessTargets: .default,
            competitivenessMode: .balanced,
            boostedPlayerIDs: [],
            createdAt: Date()
        ))
        .padding()
    }
}
