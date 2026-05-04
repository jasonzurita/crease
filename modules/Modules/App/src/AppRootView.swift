import CRDesign
import CRWorld
import SwiftUI

public struct AppRootView: View {
    var viewModel: AppRootViewModel

    public init(viewModel: AppRootViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        switch viewModel.route {
        case .seasonCreation:
            SeasonCreationView(store: viewModel.store) {
                viewModel.route = .mainApp
            }
        case .mainApp:
            MainTabView(store: viewModel.store)
        }
    }
}

#Preview {
    AppRootView(viewModel: AppRootViewModel(world: Current))
}
