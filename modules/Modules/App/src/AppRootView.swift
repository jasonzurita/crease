import CRDesign
import SwiftUI

public struct AppRootView: View {
    private var viewModel: AppRootViewModel

    public init(viewModel: AppRootViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Text("Crease")
    }
}

#Preview {
    AppRootView(viewModel: AppRootViewModel())
}
