import CRDesign
import CRWorld
import SwiftUI

public struct AppRootView: View {
    var viewModel: AppRootViewModel

    public init(viewModel: AppRootViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            switch viewModel.route {
            case .seasonCreation:
                SeasonCreationView(store: viewModel.store) {
                    viewModel.route = .mainApp
                }
            case .mainApp:
                MainTabView(store: viewModel.store)
            }
        }
        .onChange(of: viewModel.store.activeSeason == nil) { _, isNil in
            if isNil { viewModel.route = .seasonCreation }
        }
    }
}

#Preview {
    AppRootView(viewModel: AppRootViewModel(world: Current))
}
