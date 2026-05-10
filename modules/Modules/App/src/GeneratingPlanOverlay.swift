import CRDesign
import SwiftUI

struct GeneratingPlanOverlay: View {
    @State private var isSpinning = false
    @State private var tipIndex: Int = .random(in: 0 ..< CoachingTips.all.count)
    @State private var tipOpacity: Double = 1

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
                VStack(spacing: 6) {
                    Text("Coaching Tip")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.crAccent)
                        .textCase(.uppercase)
                        .tracking(1)
                    Text(CoachingTips.all[tipIndex])
                        .font(.subheadline)
                        .foregroundStyle(Color.crTextSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(tipOpacity)
                }
                .padding(.horizontal, 8)
            }
            .padding(32)
        }
        .onAppear { isSpinning = true }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.5))
                guard !Task.isCancelled else { break }
                withAnimation(.easeInOut(duration: 0.3)) { tipOpacity = 0 }
                try? await Task.sleep(for: .seconds(0.35))
                guard !Task.isCancelled else { break }
                tipIndex = (tipIndex + 1) % CoachingTips.all.count
                withAnimation(.easeInOut(duration: 0.3)) { tipOpacity = 1 }
            }
        }
    }
}

#Preview {
    GeneratingPlanOverlay()
}
