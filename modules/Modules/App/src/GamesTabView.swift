import CRDesign
import SwiftUI

public struct GamesTabView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.crBackground.ignoresSafeArea()
                Text("Games coming in Phase 3")
                    .foregroundStyle(Color.crTextSecondary)
            }
            .navigationTitle("Games")
            .toolbarBackground(Color.crSurface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    GamesTabView()
}
