//
//  HomeRootViewController.swift
//  HeartWall
//

import UIKit

final class HomeRootViewController: BaseViewController {

    private enum Tab: CaseIterable {
        case audio
        case quote
        case profile

        var title: String {
            switch self {
            case .audio:
                return L10n.text("tab.audio")
            case .quote:
                return L10n.text("tab.quote")
            case .profile:
                return L10n.text("tab.profile")
            }
        }

        var iconName: String {
            switch self {
            case .audio:
                return "waveform"
            case .quote:
                return "rectangle.on.rectangle"
            case .profile:
                return "person"
            }
        }

        var selectedIconName: String {
            switch self {
            case .audio:
                return "waveform"
            case .quote:
                return "rectangle.on.rectangle.fill"
            case .profile:
                return "person.fill"
            }
        }
    }

    // MARK: - Properties

    private let contentContainerView = UIView()
    private let tabBarView = FloatingHomeTabBar()
    private var currentTab: Tab = .quote
    private lazy var viewControllers: [Tab: UIViewController] = [
        .audio: AudioTherapyViewController(),
        .quote: LibraryViewController(),
        .profile: ProfileViewController()
    ]
    private weak var currentViewController: UIViewController?

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Setup

    override func setupUI() {
        view.backgroundColor = .black

        view.addSubview(contentContainerView)
        view.addSubview(tabBarView)
        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        tabBarView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            contentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            tabBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tabBarView.heightAnchor.constraint(equalToConstant: 74)
        ])

        tabBarView.configure(
            items: Tab.allCases.map {
                .init(title: $0.title, iconName: $0.iconName, selectedIconName: $0.selectedIconName)
            },
            selectedIndex: 1
        )
        tabBarView.onSelectionChanged = { [weak self] index in
            guard let self, let tab = Tab.allCases[safe: index] else { return }
            self.selectTab(tab)
        }

        selectTab(.quote)
    }

    private func selectTab(_ tab: Tab) {
        guard currentTab != tab || currentViewController == nil else { return }
        let nextViewController = viewControllers[tab] ?? UIViewController()

        currentViewController?.willMove(toParent: nil)
        currentViewController?.view.removeFromSuperview()
        currentViewController?.removeFromParent()

        addChild(nextViewController)
        contentContainerView.addSubview(nextViewController.view)
        nextViewController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            nextViewController.view.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            nextViewController.view.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            nextViewController.view.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            nextViewController.view.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor)
        ])

        nextViewController.didMove(toParent: self)
        currentViewController = nextViewController
        currentTab = tab

        if let selectedIndex = Tab.allCases.firstIndex(of: tab) {
            tabBarView.updateSelection(index: selectedIndex)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
