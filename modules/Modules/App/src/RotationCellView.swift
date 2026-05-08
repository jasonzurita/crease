import CRDesign
import SwiftUI

struct RotationCellView: View {
    let playerName: String?
    let jerseyNumber: Int?
    let isSelected: Bool
    let isLocked: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                cellBackground
                if let name = playerName {
                    VStack(spacing: 1) {
                        HStack(spacing: 3) {
                            Text(name)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(isSelected ? Color.crBackground : Color.crTextPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)
                            if isLocked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 7))
                                    .foregroundStyle(isSelected ? Color.crBackground.opacity(0.7) : Color.crAccent.opacity(0.7))
                            }
                        }
                        if let num = jerseyNumber {
                            Text("#\(num)")
                                .font(.system(size: 9).monospacedDigit())
                                .foregroundStyle(isSelected ? Color.crBackground.opacity(0.7) : Color.crTextSecondary)
                        }
                    }
                    .padding(.horizontal, 4)
                } else {
                    Text("—")
                        .font(.caption)
                        .foregroundStyle(Color.crDanger.opacity(0.6))
                }
            }
        }
        .buttonStyle(.plain)
        .onLongPressGesture {
            if playerName != nil { onLongPress() }
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.crTextSecondary.opacity(0.15))
                .frame(width: 1)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.crTextSecondary.opacity(0.15))
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private var cellBackground: some View {
        if isSelected {
            Color.crAccent
        } else if isLocked {
            Color.crAccent.opacity(0.1)
        } else {
            Color.clear
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        RotationCellView(
            playerName: "Alex Johnson",
            jerseyNumber: 12,
            isSelected: false,
            isLocked: false,
            onTap: {},
            onLongPress: {}
        )
        .frame(width: 96, height: 58)
        .background(Color.crSurface)

        RotationCellView(
            playerName: "Sam Lee",
            jerseyNumber: 1,
            isSelected: true,
            isLocked: false,
            onTap: {},
            onLongPress: {}
        )
        .frame(width: 96, height: 58)
        .background(Color.crSurface)

        RotationCellView(
            playerName: "Jordan",
            jerseyNumber: 7,
            isSelected: false,
            isLocked: true,
            onTap: {},
            onLongPress: {}
        )
        .frame(width: 96, height: 58)
        .background(Color.crSurface)

        RotationCellView(
            playerName: nil,
            jerseyNumber: nil,
            isSelected: false,
            isLocked: false,
            onTap: {},
            onLongPress: {}
        )
        .frame(width: 96, height: 58)
        .background(Color.crSurface)
    }
    .background(Color.crBackground)
}
