//
//  SceneDelegate.swift
//  HeartWall
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)
        let rootViewController = PremiumAccessStore.shared.isPremium
            ? LaunchViewController()
            : SubscriptionRoute.makeSubscriptionViewController(source: .appLaunch)
        let navigationController = UINavigationController(rootViewController: rootViewController)
        navigationController.setNavigationBarHidden(true, animated: false)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        Task {
            await PremiumAccessStore.shared.refreshPurchasedProducts()
        }
    }
}
