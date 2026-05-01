//
//  SubscriptionRoute.swift
//  HeartWall
//

import UIKit

enum SubscriptionRoute {

    static func makeSubscriptionViewController(
        source: SubscriptionViewController.Source,
        videoResource: OnboardingVideoResource = .appGuide2
    ) -> SubscriptionViewController {
        SubscriptionViewController(videoResource: videoResource, source: source)
    }

    static func presentSubscription(
        from presenter: UIViewController,
        source: SubscriptionViewController.Source = .modal,
        videoResource: OnboardingVideoResource = .appGuide2
    ) {
        let viewController = makeSubscriptionViewController(source: source, videoResource: videoResource)
        viewController.modalPresentationStyle = .fullScreen
        presenter.present(viewController, animated: true)
    }

    static func replaceRootWithLaunch(from navigationController: UINavigationController) {
        transition(on: navigationController, to: LaunchViewController())
    }

    static func replaceRootWithHome(from navigationController: UINavigationController) {
        transition(on: navigationController, to: HomeRootViewController())
    }

    private static func transition(on navigationController: UINavigationController, to viewController: UIViewController) {
        UIView.transition(
            with: navigationController.view,
            duration: UIAccessibility.isReduceMotionEnabled ? 0.15 : 0.40,
            options: [.transitionCrossDissolve, .allowAnimatedContent]
        ) {
            navigationController.setViewControllers([viewController], animated: false)
        }
    }
}
