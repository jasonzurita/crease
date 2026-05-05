import CRDesign
import CRModel
import SwiftUI

public struct PlayerRowView: View {
    private let player: Player

    public init(player: Player) {
        self.player = player
    }

    public var body: some View {
        HStack(spacing: 12) {
            Text("#\(player.jerseyNumber)")
                .font(.body.monospacedDigit())
                .foregroundStyle(Color.crTextSecondary)
                .frame(minWidth: 36, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(player.name)
                        .foregroundStyle(Color.crTextPrimary)
                    if player.positions.contains(.goalie) {
                        Text("G")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.crBackground)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.crWarning)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                Text(positionSummary)
                    .font(.caption)
                    .foregroundStyle(Color.crTextSecondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var positionSummary: String {
        Position.allCases
            .filter { player.positions.contains($0) }
            .map(\.rawValue)
            .joined(separator: ", ")
    }
}

#Preview {
    ZStack {
        Color.crBackground.ignoresSafeArea()
        VStack(spacing: 0) {
            PlayerRowView(player: Player(
                id: UUID(),
                name: "Alex Johnson",
                jerseyNumber: 12,
                positions: [.midfield, .attack],
                tier: .strong
            ))
            PlayerRowView(player: Player(
                id: UUID(),
                name: "Sam Lee",
                jerseyNumber: 1,
                positions: [.goalie, .defense],
                tier: .elite
            ))
        }
        .padding()
    }
}
