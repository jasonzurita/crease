import Combine
import UIKit

public extension ApplicationClient {
    static func appForegrounded() -> ApplicationClient {
        .init(
            applicationState: { .active },
            appVersion: { "" },
            appBuildVersion: { "" },
            beginBackgroundTask: { _ in UIBackgroundTaskIdentifier(rawValue: 0) },
            endBackgroundTask: { _ in },
            isIdleTimerDisabled: { _ in },
            interfaceOrientation: { nil },
            applicationStatePublisher: { PassthroughSubject<UIApplication.State, Never>()
                .eraseToAnyPublisher()
            },
            didBecomeActivePublisher: { PassthroughSubject<Void, Never>()
                .eraseToAnyPublisher()
            },
            visibleViewController: { nil },
            currentWindowScene: { nil },
            registerForRemoteNotifications: {}
        )
    }

    static func appBackgrounded() -> ApplicationClient {
        .init(
            applicationState: { .background },
            appVersion: { "" },
            appBuildVersion: { "" },
            beginBackgroundTask: { _ in UIBackgroundTaskIdentifier(rawValue: 0) },
            endBackgroundTask: { _ in },
            isIdleTimerDisabled: { _ in },
            interfaceOrientation: { nil },
            applicationStatePublisher: { PassthroughSubject<UIApplication.State, Never>()
                .eraseToAnyPublisher()
            },
            didBecomeActivePublisher: { PassthroughSubject<Void, Never>()
                .eraseToAnyPublisher()
            },
            visibleViewController: { nil },
            currentWindowScene: { nil },
            registerForRemoteNotifications: {}
        )
    }

    /// Flip the application state from active to background and vice-versa
    /// - Parameters:
    ///   - every: how many seconds should pass between each update
    ///   - for: how many times it should update
    static func flipApplicationState(
        every interval: TimeInterval,
        for maxAmount: Int
    ) -> Self {
        var state: UIApplication.State = .active

        return .init(
            // FIXME: active below is hard coded because Swift 6 doesn't like it
            applicationState: { .active },
            appVersion: { "" },
            appBuildVersion: { "" },
            beginBackgroundTask: { _ in UIBackgroundTaskIdentifier(rawValue: 0) },
            endBackgroundTask: { _ in },
            isIdleTimerDisabled: { _ in },
            interfaceOrientation: { nil },
            applicationStatePublisher: {
                Timer
                    .publish(every: interval, on: .main, in: .common)
                    .autoconnect()
                    .prefix(maxAmount)
                    .map { _ -> UIApplication.State in
                        if state == .active {
                            state = .background
                        } else {
                            state = .active
                        }
                        return state
                    }
                    .prepend(state)
                    .eraseToAnyPublisher()
            },
            didBecomeActivePublisher: { PassthroughSubject<Void, Never>()
                .eraseToAnyPublisher()
            },
            visibleViewController: { nil },
            currentWindowScene: { nil },
            registerForRemoteNotifications: {}
        )
    }
}
