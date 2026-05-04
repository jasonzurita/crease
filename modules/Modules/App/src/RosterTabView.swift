import CRDesign
import SwiftUI

public struct RosterTabView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.crBackground.ignoresSafeArea()
                Text("Roster coming in Phase 2")
                    .foregroundStyle(Color.crTextSecondary)
            }
            .navigationTitle("Roster")
            .toolbarBackground(Color.crSurface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    RosterTabView()
}
