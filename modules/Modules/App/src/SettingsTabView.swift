import CRDesign
import SwiftUI

public struct SettingsTabView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.crBackground.ignoresSafeArea()
                Text("Settings coming in Phase 9")
                    .foregroundStyle(Color.crTextSecondary)
            }
            .navigationTitle("Settings")
            .toolbarBackground(Color.crSurface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    SettingsTabView()
}
