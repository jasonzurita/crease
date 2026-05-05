import CRDesign
import SwiftUI

struct SummaryStripView: View {
    let viewModel: RotationOutputViewModel

    var body: some View {
        let minMax = viewModel.summaryMinMax

        HStack(spacing: 0) {
            statCell(label: "Players", value: "\(viewModel.summaryPlayerCount)")
            stripDivider
            statCell(
                label: "Min · Max",
                value: "\(minMax.min)m · \(minMax.max)m"
            )
            stripDivider
            statCell(
                label: "Violations",
                value: "\(viewModel.summaryViolationCount)",
                valueColor: viewModel.summaryViolationCount > 0 ? .crDanger : .crSuccess
            )
            stripDivider
            statCell(label: "Locked", value: "\(viewModel.summaryLockedCount)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.crSurface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.crTextSecondary.opacity(0.2))
                .frame(height: 1)
        }
    }

    private func statCell(
        label: String,
        value: String,
        valueColor: Color = Color.crTextPrimary
    ) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.crTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var stripDivider: some View {
        Rectangle()
            .fill(Color.crTextSecondary.opacity(0.3))
            .frame(width: 1, height: 24)
    }
}
