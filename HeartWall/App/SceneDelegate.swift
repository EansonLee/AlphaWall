//
//  SceneDelegate.swift
//  HeartWall
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var startupTask: Task<Void, Never>?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)
        let navigationController = UINavigationController(rootViewController: StartupGateViewController())
        navigationController.setNavigationBarHidden(true, animated: false)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        startupTask = Task {
            await PremiumAccessStore.shared.refreshPurchasedProducts()
            guard !Task.isCancelled else { return }

            let rootViewController = PremiumAccessStore.shared.isPremium
                ? LaunchViewController()
                : SubscriptionRoute.makeSubscriptionViewController(source: .appLaunch)

            navigationController.setViewControllers([rootViewController], animated: false)
        }
    }
}

private final class StartupGateViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.03, green: 0.03, blue: 0.05, alpha: 1)
    }
}
