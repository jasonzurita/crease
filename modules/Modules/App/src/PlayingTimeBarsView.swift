import CRDesign
import CRModel
import SwiftUI

struct PlayingTimeBarsView: View {
    let viewModel: RotationOutputViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Playing Time")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.crTextSecondary)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            VStack(spacing: 6) {
                ForEach(viewModel.presentPlayers, id: \.id) { player in
                    playerBar(for: player)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(Color.crSurface)
    }

    private func playerBar(for player: Player) -> some View {
        let projected = viewModel.projectedMinutes(for: player.id)
        let minimum = viewModel.minimumMinutes(for: player.id)
        let fraction = viewModel.minutesFraction(for: player.id)
        let status = viewModel.minutesStatus(for: player.id)
        let totalSlots = viewModel.plan?.slots.count ?? 1
        let totalMinutes = totalSlots * viewModel.slotDurationMinutes

        return HStack(spacing: 10) {
            Text(player.name)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.crTextPrimary)
                .frame(width: 100, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.crTextSecondary.opacity(0.15))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor(for: status))
                        .frame(width: max(0, geo.size.width * fraction))

                    if minimum > 0 && totalMinutes > 0 {
                        let minFraction = min(1.0, Double(minimum) / Double(totalMinutes))
                        Rectangle()
                            .fill(Color.crTextPrimary.opacity(0.4))
                            .frame(width: 1.5)
                            .offset(x: geo.size.width * minFraction - 0.75)
                    }
                }
            }
            .frame(height: 14)

            Text("\(projected)m")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(barColor(for: status))
                .frame(width: 32, alignment: .trailing)
        }
    }

    private func barColor(for status: RotationOutputViewModel.MinutesStatus) -> Color {
        switch status {
        case .met: Color.crSuccess
        case .near: Color.crWarning
        case .violation: Color.crDanger
        }
    }
}
