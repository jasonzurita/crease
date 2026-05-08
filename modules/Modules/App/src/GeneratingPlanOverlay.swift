import CRDesign
import SwiftUI

struct GeneratingPlanOverlay: View {
    @State private var isSpinning = false

    var body: some View {
        ZStack {
            Color.crBackground.opacity(0.95).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.crAccent)
                    .rotationEffect(.degrees(isSpinning ? 360 : 0))
                    .animation(
                        .linear(duration: 1.0).repeatForever(autoreverses: false),
                        value: isSpinning
                    )
                Text("Calculating rotation...")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.crTextPrimary)
                Text("Building the optimal plan for your roster")
                    .font(.subheadline)
                    .foregroundStyle(Color.crTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
        }
        .onAppear { isSpinning = true }
    }
}

#Preview {
    GeneratingPlanOverlay()
}
