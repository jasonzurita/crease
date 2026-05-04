import CRDesign
import SwiftUI

public struct MainTabView: View {
    private let store: SeasonStore

    public init(store: SeasonStore) {
        self.store = store
    }

    public var body: some View {
        TabView {
            Tab("Roster", systemImage: "person.2") {
                RosterTabView()
            }
            Tab("Games", systemImage: "calendar") {
                GamesTabView()
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsTabView()
            }
        }
        .tint(Color.crAccent)
    }
}

#Preview {
    MainTabView(
        store: SeasonStore(fileManagerClient: .mock(), userDefaultsClient: .noop)
    )
}
