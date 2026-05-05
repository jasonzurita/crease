import Combine
import UIKit

public extension ApplicationClient {
    static func live() -> ApplicationClient {
        .init(
            applicationState: { UIApplication.shared.applicationState },
            appVersion: { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "" },
            appBuildVersion: { Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "" },
            beginBackgroundTask: { handler in UIApplication.shared.beginBackgroundTask(expirationHandler: handler)
            },
            endBackgroundTask: { identifier in
                UIApplication.shared.endBackgroundTask(identifier)
            },
            isIdleTimerDisabled: { isDisabled in
                UIApplication.shared.isIdleTimerDisabled = isDisabled
            },
            interfaceOrientation: {
                (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.effectiveGeometry.interfaceOrientation
            },
            applicationStatePublisher: {
                Publishers.MergeMany([
                    NotificationCenter
                        .default
                        .publisher(for: UIApplication.willResignActiveNotification)
                        .map { _ in UIApplication.State.inactive },
                    NotificationCenter
                        .default
                        .publisher(for: UIApplication.didBecomeActiveNotification)
                        .map { _ in UIApplication.State.active },
                    NotificationCenter
                        .default
                        .publisher(for: UIApplication.didEnterBackgroundNotification)
                        .map { _ in UIApplication.State.background },
                ])
                .share()
                .prepend(UIApplication.shared.applicationState)
                .eraseToAnyPublisher()
            },
            didBecomeActivePublisher: {
                NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
                    .map { _ in () }
                    .eraseToAnyPublisher()
            },
            visibleViewController: {
                UIApplication.shared.visibleViewController()
            },
            currentWindowScene: {
                UIApplication.shared
                    .connectedScenes
                    .first as? UIWindowScene
            },
            registerForRemoteNotifications: { UIApplication.shared.registerForRemoteNotifications()
            }
        )
    }
}
