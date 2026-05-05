import CRDesign
import CRModel
import SwiftUI

struct AttendancePlayerCard: View {
    private let player: Player
    private let attendance: PlayerAttendance
    private let quarters: Int
    private let onTogglePresent: () -> Void
    private let onUpdate: (PlayerAttendance) -> Void
    @State private var showingSheet = false

    init(
        player: Player,
        attendance: PlayerAttendance,
        quarters: Int,
        onTogglePresent: @escaping () -> Void,
        onUpdate: @escaping (PlayerAttendance) -> Void
    ) {
        self.player = player
        self.attendance = attendance
        self.quarters = quarters
        self.onTogglePresent = onTogglePresent
        self.onUpdate = onUpdate
    }

    var body: some View {
        HStack(spacing: 0) {
            Button {
                onTogglePresent()
            } label: {
                Image(systemName: attendance.isPresent ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(attendance.isPresent ? Color.crAccent : Color.crTextSecondary)
                    .frame(width: 44)
                    .frame(maxHeight: .infinity)
            }

            Button {
                showingSheet = true
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("#\(player.jerseyNumber)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Color.crTextSecondary)
                    Text(player.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(attendance.isPresent ? Color.crTextPrimary : Color.crTextSecondary)
                        .lineLimit(1)
                    if let q = attendance.lateArrivalQuarter {
                        Text("Late Q\(q)+")
                            .font(.caption2)
                            .foregroundStyle(Color.crWarning)
                    }
                    if let q = attendance.earlyDepartureQuarter {
                        Text("Leaves Q\(q)")
                            .font(.caption2)
                            .foregroundStyle(Color.crWarning)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 10)
                .padding(.trailing, 8)
            }
        }
        .background(Color.crSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .opacity(attendance.isPresent ? 1.0 : 0.6)
        .sheet(isPresented: $showingSheet) {
            PlayerAttendanceSheet(
                attendance: attendance,
                quarters: quarters,
                playerName: player.name,
                onUpdate: onUpdate
            )
        }
    }
}
