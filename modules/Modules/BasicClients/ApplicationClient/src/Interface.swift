import Combine
import UIKit

public struct ApplicationClient: Sendable {
    public var applicationState: @MainActor () -> UIApplication.State
    public var appVersion: @Sendable () -> String
    public var appBuildVersion: @Sendable () -> String
    public var beginBackgroundTask: @MainActor (_ expirationHandler: (@Sendable () -> Void)?) -> UIBackgroundTaskIdentifier
    public var endBackgroundTask: @MainActor (UIBackgroundTaskIdentifier) -> Void
    public var isIdleTimerDisabled: @MainActor (Bool) -> Void
    public var interfaceOrientation: @MainActor () -> UIInterfaceOrientation?
    /// Publish the current `UIApplication.State` value and future changes.
    public var applicationStatePublisher: @MainActor () -> AnyPublisher<UIApplication.State, Never>
    public var didBecomeActivePublisher: @Sendable () -> AnyPublisher<Void, Never>
    public var visibleViewController: @MainActor () -> UIViewController?
    public var currentWindowScene: @MainActor () -> UIWindowScene?

    /// Registers to receive remote notifications through Apple Push Notification service.
    public var registerForRemoteNotifications: @MainActor () -> Void

    public init(
        applicationState: @escaping @MainActor () -> UIApplication.State,
        appVersion: @escaping @Sendable () -> String,
        appBuildVersion: @escaping @Sendable () -> String,
        beginBackgroundTask: @escaping @MainActor (_ expirationHandler: (@Sendable () -> Void)?) -> UIBackgroundTaskIdentifier,
        endBackgroundTask: @escaping @MainActor (UIBackgroundTaskIdentifier) -> Void,
        isIdleTimerDisabled: @escaping @MainActor (Bool) -> Void,
        interfaceOrientation: @escaping @MainActor () -> UIInterfaceOrientation?,
        applicationStatePublisher: @escaping @MainActor () -> AnyPublisher<UIApplication.State, Never>,
        didBecomeActivePublisher: @escaping @Sendable () -> AnyPublisher<Void, Never>,
        visibleViewController: @escaping @MainActor () -> UIViewController?,
        currentWindowScene: @escaping @MainActor () -> UIWindowScene?,
        registerForRemoteNotifications: @escaping @MainActor () -> Void
    ) {
        self.applicationState = applicationState
        self.appVersion = appVersion
        self.appBuildVersion = appBuildVersion
        self.beginBackgroundTask = beginBackgroundTask
        self.endBackgroundTask = endBackgroundTask
        self.isIdleTimerDisabled = isIdleTimerDisabled
        self.interfaceOrientation = interfaceOrientation
        self.applicationStatePublisher = applicationStatePublisher
        self.didBecomeActivePublisher = didBecomeActivePublisher
        self.visibleViewController = visibleViewController
        self.currentWindowScene = currentWindowScene
        self.registerForRemoteNotifications = registerForRemoteNotifications
    }
}
