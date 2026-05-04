import ApplicationClient
import FileManagerClient
import Foundation
import UserDefaultsClient

public let Current: World = .live()

public struct World: Sendable {
    public var currentDate: @Sendable () -> Date
    public var applicationClient: ApplicationClient
    public var fileManagerClient: FileManagerClient
    public var userDefaultsClient: UserDefaultsClient

    public init(
        currentDate: @escaping @Sendable () -> Date,
        applicationClient: ApplicationClient,
        fileManagerClient: FileManagerClient,
        userDefaultsClient: UserDefaultsClient
    ) {
        self.currentDate = currentDate
        self.applicationClient = applicationClient
        self.fileManagerClient = fileManagerClient
        self.userDefaultsClient = userDefaultsClient
    }
}

extension World {
    static func live() -> World {
        .init(
            currentDate: Date.init,
            applicationClient: .live(),
            fileManagerClient: .live(),
            userDefaultsClient: .live
        )
    }
}
