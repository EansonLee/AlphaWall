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
                return "音疗"
            case .quote:
                return "心语"
            case .profile:
                return "我的"
            }
        }

        var iconName: String {
            switch self {
            case .audio:
                return "waveform.circle"
            case .quote:
                return "book.closed"
            case .profile:
                return "person.crop.circle"
            }
        }
    }

    // MARK: - Properties

    private let contentContainerView = UIView()
    private let tabBarView = FloatingHomeTabBar()
    private var currentTab: Tab = .quote
    private lazy var viewControllers: [Tab: UIViewController] = [
        .audio: PlaceholderSectionViewController(titleText: "音疗", subtitleText: "一级页占位，后续接入真实音疗内容。"),
        .quote: LibraryViewController(),
        .profile: PlaceholderSectionViewController(titleText: "我的", subtitleText: "一级页占位，后续接入会员、收藏与设置。")
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

            tabBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tabBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tabBarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -6),
            tabBarView.heightAnchor.constraint(equalToConstant: 72)
        ])

        tabBarView.configure(items: Tab.allCases.map { .init(title: $0.title, iconName: $0.iconName) }, selectedIndex: 1)
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

private final class PlaceholderSectionViewController: BaseViewController {

    private let titleText: String
    private let subtitleText: String

    init(titleText: String, subtitleText: String) {
        self.titleText = titleText
        self.subtitleText = subtitleText
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupUI() {
        view.backgroundColor = UIColor(red: 0.10, green: 0.11, blue: 0.15, alpha: 1)

        let titleLabel = UILabel()
        titleLabel.text = titleText
        titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = .white

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitleText
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.68)
        subtitleLabel.numberOfLines = 0

        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 10

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
