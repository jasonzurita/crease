import CRModel
import SwiftUI
import UIKit

struct PlayerAvatarView: View {
    let player: Player
    let size: CGFloat

    var body: some View {
        Group {
            if let data = player.avatarImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(avatarColor)
            Text(player.initials.isEmpty ? "#\(player.jerseyNumber)" : player.initials)
                .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
        }
    }

    private var avatarColor: Color {
        let colors: [Color] = [
            .blue, .indigo, .purple, .pink, .orange, .green, .teal, .cyan,
        ]
        let index = abs(player.name.hashValue) % colors.count
        return colors[index].opacity(0.85)
    }
}

#Preview {
    HStack(spacing: 16) {
        PlayerAvatarView(
            player: Player(id: UUID(), name: "Alex Johnson", jerseyNumber: 12, positions: [.midfield], tier: .strong),
            size: 44
        )
        PlayerAvatarView(
            player: Player(id: UUID(), name: "Sam", jerseyNumber: 1, positions: [.goalie], tier: .elite),
            size: 44
        )
        PlayerAvatarView(
            player: Player(id: UUID(), name: "Jordan Lee", jerseyNumber: 7, positions: [.defense], tier: .developing),
            size: 32
        )
    }
    .padding()
    .background(Color.black)
}
