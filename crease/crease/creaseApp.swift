import CRApp
import CRWorld
import SwiftUI

@main
struct CreaseApp: App {
    private let viewModel = AppRootViewModel(world: Current)

    var body: some Scene {
        WindowGroup {
            AppRootView(viewModel: viewModel)
        }
    }
}
