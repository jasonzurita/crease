import CRWorld
import Foundation
import Observation

@Observable
@MainActor
public final class AppRootViewModel {
    public enum Route {
        case seasonCreation
        case mainApp
    }

    public var route: Route
    public let store: SeasonStore

    public init(world: World) {
        let store = SeasonStore(
            fileManagerClient: world.fileManagerClient,
            userDefaultsClient: world.userDefaultsClient
        )
        self.store = store
        route = store.seasons.isEmpty ? .seasonCreation : .mainApp
    }
}
