import SharedUI
import SwiftUI
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo _: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let splitViewController = createSplitViewController()

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = splitViewController
        window?.makeKeyAndVisible()
    }

    private func createSplitViewController() -> UISplitViewController {
        let splitVC = UISplitViewController(style: .doubleColumn)
        splitVC.preferredDisplayMode = .oneBesideSecondary
        splitVC.preferredSplitBehavior = .tile

        let sidebarVC = SidebarViewController()
        let sidebarNav = UINavigationController(rootViewController: sidebarVC)

        let placeholderVC = createPlaceholderViewController()
        let detailNav = UINavigationController(rootViewController: placeholderVC)

        splitVC.setViewController(sidebarNav, for: .primary)
        splitVC.setViewController(detailNav, for: .secondary)

        // Connect sidebar selection to detail updates
        sidebarVC.onSectionSelected = { [weak splitVC] section in
            let contentView = DemoContentView(section: section)
            let hostingController = UIHostingController(rootView: contentView)
            hostingController.title = section.title

            let nav = UINavigationController(rootViewController: hostingController)
            splitVC?.setViewController(nav, for: .secondary)
            splitVC?.show(.secondary)
        }

        return splitVC
    }

    private func createPlaceholderViewController() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "Select a section"
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .body)
        label.translatesAutoresizingMaskIntoConstraints = false

        vc.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor),
        ])

        return vc
    }
}
