import CRDesign
import CRModel
import SwiftUI

struct ViolationBannerView: View {
    let violation: Violation
    let players: [Player]
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.crDanger)
                .font(.subheadline)

            Text(bannerText)
                .font(.caption)
                .foregroundStyle(Color.crTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.crTextSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.crDanger.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.crDanger.opacity(0.3), lineWidth: 1)
        )
    }

    private var bannerText: String {
        switch violation.kind {
        case .minutesBelowMinimum:
            let name = players.first { $0.id == violation.playerID }?.name ?? "Player"
            let projected = violation.projectedMinutes ?? 0
            let minimum = violation.minimumMinutes ?? 0
            let below = minimum - projected
            return "\(name) gets \(projected)m — \(below)m below \(minimum)m minimum"
        case .noEligiblePlayer:
            let pos = violation.position?.rawValue ?? "Unknown"
            let q = violation.quarter ?? 0
            return "No eligible \(pos) for Q\(q)"
        }
    }
}
