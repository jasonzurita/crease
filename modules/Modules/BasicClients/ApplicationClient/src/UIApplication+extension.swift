import UIKit

/// Additional context/discussion: https://stackoverflow.com/questions/22882078/how-to-get-visible-viewcontroller-from-app-delegate-when-using-storyboard
extension UIApplication {
    func visibleViewController() -> UIViewController? {
        guard let rootViewController = UIApplication
            .shared
            .connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .last?.rootViewController
        else { return nil }
        return getVisibleViewController(rootViewController)
    }

    private func getVisibleViewController(_ rootViewController: UIViewController) -> UIViewController? {
        if let presentedViewController = rootViewController.presentedViewController {
            return getVisibleViewController(presentedViewController)
        }

        if let navigationController = rootViewController as? UINavigationController {
            return navigationController.visibleViewController
        }

        if let tabBarController = rootViewController as? UITabBarController {
            return tabBarController.selectedViewController
        }

        return rootViewController
    }
}
