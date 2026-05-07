import CRApp
import CRWorld
import SwiftUI

@main
struct CreaseApp: App {
    private let viewModel = AppRootViewModel(world: Current)
    @AppStorage("cr_color_scheme") private var colorSchemePreference = "system"

    var body: some Scene {
        WindowGroup {
            AppRootView(viewModel: viewModel)
                .preferredColorScheme(resolvedColorScheme)
        }
    }

    private var resolvedColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }
}
