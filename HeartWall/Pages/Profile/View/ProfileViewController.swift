//
//  ProfileViewController.swift
//  HeartWall
//

import UIKit

final class ProfileViewController: BaseViewController {

    fileprivate enum ProfileItem: CaseIterable, Equatable {
        case membership
        case restorePurchases
        case favoriteWallpapers
        case privacy
        case terms

        var title: String {
            switch self {
            case .membership:
                return L10n.text("profile.menu.membership")
            case .restorePurchases:
                return L10n.text("profile.menu.restore_purchases")
            case .favoriteWallpapers:
                return L10n.text("profile.menu.favorite_wallpapers")
            case .privacy:
                return L10n.text("profile.menu.privacy")
            case .terms:
                return L10n.text("profile.menu.terms")
            }
        }

        var iconName: String {
            switch self {
            case .membership:
                return "crown.fill"
            case .restorePurchases:
                return "arrow.clockwise.circle.fill"
            case .favoriteWallpapers:
                return "heart.fill"
            case .privacy:
                return "lock.doc.fill"
            case .terms:
                return "doc.text.fill"
            }
        }

        var accentColor: UIColor {
            switch self {
            case .membership:
                return UIColor(red: 1.00, green: 0.82, blue: 0.55, alpha: 1)
            case .restorePurchases:
                return UIColor(red: 0.52, green: 0.78, blue: 1.00, alpha: 1)
            case .favoriteWallpapers:
                return UIColor(red: 1.00, green: 0.80, blue: 0.50, alpha: 1)
            case .privacy:
                return UIColor(red: 0.42, green: 0.82, blue: 0.76, alpha: 1)
            case .terms:
                return UIColor(red: 0.66, green: 0.78, blue: 0.98, alpha: 1)
            }
        }

        var agreementURL: URL? {
            switch self {
            case .membership, .restorePurchases, .favoriteWallpapers:
                return nil
            case .privacy:
                return URL(string: "https://docs.google.com/document/d/1n2nVh6Esl44qqnzkzcKzVcyx4290vUxlfHRON--3GpQ/edit?tab=t.0")
            case .terms:
                return URL(string: "https://docs.google.com/document/d/1xgrVsqWmuMHLHbtH7dr15_dqKjy8nfQ4xKl6Qho0hdA/edit?tab=t.0")
            }
        }

        var agreementTitle: String {
            switch self {
            case .membership, .restorePurchases, .favoriteWallpapers:
                return title
            case .privacy:
                return L10n.text("agreement.privacy.title")
            case .terms:
                return L10n.text("agreement.terms.title")
            }
        }

        static func visibleItems(isPremium: Bool) -> [ProfileItem] {
            allCases.filter { item in
                !(isPremium && item == .membership)
            }
        }
    }

    private let backgroundImageView = UIImageView(image: UIImage(named: "MyPageBackground"))
    private let backgroundOverlayView = ProfileBackgroundOverlayView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let pageStackView = UIStackView()
    private let coverStackView = UIStackView()
    private let coverTagLabel = UILabel()
    private let coverTitleLabel = UILabel()
    private let coverSubtitleLabel = UILabel()
    private let heroPanelView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
    private let heroContentStackView = UIStackView()
    private let appIconContainerView = UIView()
    private let appIconImageView = UIImageView(image: UIImage(named: "icon_launcher"))
    private let heroTextStackView = UIStackView()
    private let heroTitleLabel = UILabel()
    private let heroSubtitleLabel = UILabel()
    private let menuPanelView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
    private let menuStackView = UIStackView()
    private let versionLabel = UILabel()
    private var visibleMenuItems: [ProfileItem] = []

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        renderMenuItems()
    }

    override func setupUI() {
        view.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1)
        configureBackground()
        configureHeader()
        configureContent()
        configureObservers()
        renderMenuItems()
    }

    private func configureBackground() {
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.isUserInteractionEnabled = false
        view.addSubview(backgroundImageView)
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false

        backgroundOverlayView.isUserInteractionEnabled = false
        view.addSubview(backgroundOverlayView)
        backgroundOverlayView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            backgroundOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureHeader() {
        coverStackView.axis = .vertical
        coverStackView.alignment = .leading
        coverStackView.spacing = 10

        coverTagLabel.text = L10n.text("profile.cover.tag")
        coverTagLabel.font = .monospacedSystemFont(ofSize: 11, weight: .semibold)
        coverTagLabel.textColor = UIColor.white.withAlphaComponent(0.66)

        coverTitleLabel.text = L10n.text("profile.cover.title")
        coverTitleLabel.font = .systemFont(ofSize: 38, weight: .heavy)
        coverTitleLabel.textColor = UIColor.white.withAlphaComponent(0.97)
        coverTitleLabel.shadowColor = UIColor.black.withAlphaComponent(0.22)
        coverTitleLabel.shadowOffset = CGSize(width: 0, height: 2)
        coverTitleLabel.adjustsFontSizeToFitWidth = true
        coverTitleLabel.minimumScaleFactor = 0.82

        coverSubtitleLabel.text = L10n.text("profile.cover.subtitle")
        coverSubtitleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        coverSubtitleLabel.textColor = UIColor.white.withAlphaComponent(0.72)
        coverSubtitleLabel.numberOfLines = 2
        coverSubtitleLabel.adjustsFontSizeToFitWidth = true
        coverSubtitleLabel.minimumScaleFactor = 0.86

        [coverTagLabel, coverTitleLabel, coverSubtitleLabel].forEach {
            coverStackView.addArrangedSubview($0)
        }

        heroPanelView.layer.cornerRadius = 28
        heroPanelView.layer.cornerCurve = .continuous
        heroPanelView.clipsToBounds = true
        heroPanelView.layer.borderWidth = 0.8
        heroPanelView.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor
        heroPanelView.contentView.backgroundColor = UIColor.black.withAlphaComponent(0.16)

        heroContentStackView.axis = .horizontal
        heroContentStackView.alignment = .center
        heroContentStackView.spacing = 15
        heroPanelView.contentView.addSubview(heroContentStackView)
        heroContentStackView.translatesAutoresizingMaskIntoConstraints = false

        appIconContainerView.backgroundColor = UIColor.white.withAlphaComponent(0.14)
        appIconContainerView.layer.cornerRadius = 19
        appIconContainerView.layer.cornerCurve = .continuous
        appIconContainerView.layer.borderWidth = 0.8
        appIconContainerView.layer.borderColor = UIColor.white.withAlphaComponent(0.28).cgColor
        appIconContainerView.clipsToBounds = true

        appIconImageView.contentMode = .scaleAspectFill
        appIconImageView.clipsToBounds = true
        appIconImageView.layer.cornerRadius = 15
        appIconImageView.layer.cornerCurve = .continuous

        appIconContainerView.addSubview(appIconImageView)
        appIconImageView.translatesAutoresizingMaskIntoConstraints = false

        heroTextStackView.axis = .vertical
        heroTextStackView.alignment = .leading
        heroTextStackView.spacing = 4
        heroTextStackView.isUserInteractionEnabled = false

        heroTitleLabel.text = "栖幕壁纸"
        heroTitleLabel.font = .systemFont(ofSize: 19, weight: .semibold)
        heroTitleLabel.textColor = UIColor.white.withAlphaComponent(0.94)
        heroTitleLabel.adjustsFontSizeToFitWidth = true
        heroTitleLabel.minimumScaleFactor = 0.86

        heroSubtitleLabel.text = L10n.text("profile.hero.subtitle")
        heroSubtitleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        heroSubtitleLabel.textColor = UIColor.white.withAlphaComponent(0.62)
        heroSubtitleLabel.adjustsFontSizeToFitWidth = true
        heroSubtitleLabel.minimumScaleFactor = 0.82

        [heroTitleLabel, heroSubtitleLabel].forEach {
            heroTextStackView.addArrangedSubview($0)
        }

        heroContentStackView.addArrangedSubview(appIconContainerView)
        heroContentStackView.addArrangedSubview(heroTextStackView)

        NSLayoutConstraint.activate([
            heroContentStackView.topAnchor.constraint(equalTo: heroPanelView.contentView.topAnchor, constant: 16),
            heroContentStackView.leadingAnchor.constraint(equalTo: heroPanelView.contentView.leadingAnchor, constant: 16),
            heroContentStackView.trailingAnchor.constraint(equalTo: heroPanelView.contentView.trailingAnchor, constant: -16),
            heroContentStackView.bottomAnchor.constraint(equalTo: heroPanelView.contentView.bottomAnchor, constant: -16),

            appIconContainerView.widthAnchor.constraint(equalToConstant: 56),
            appIconContainerView.heightAnchor.constraint(equalToConstant: 56),

            appIconImageView.topAnchor.constraint(equalTo: appIconContainerView.topAnchor, constant: 4),
            appIconImageView.leadingAnchor.constraint(equalTo: appIconContainerView.leadingAnchor, constant: 4),
            appIconImageView.trailingAnchor.constraint(equalTo: appIconContainerView.trailingAnchor, constant: -4),
            appIconImageView.bottomAnchor.constraint(equalTo: appIconContainerView.bottomAnchor, constant: -4)
        ])
    }

    private func configureContent() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        pageStackView.axis = .vertical
        pageStackView.alignment = .fill
        pageStackView.spacing = 18
        contentView.addSubview(pageStackView)
        pageStackView.translatesAutoresizingMaskIntoConstraints = false

        menuPanelView.layer.cornerRadius = 24
        menuPanelView.layer.cornerCurve = .continuous
        menuPanelView.clipsToBounds = true
        menuPanelView.layer.borderWidth = 0.8
        menuPanelView.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
        menuPanelView.contentView.backgroundColor = UIColor.black.withAlphaComponent(0.14)

        menuStackView.axis = .vertical
        menuStackView.spacing = 0

        versionLabel.text = appVersionText()
        versionLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        versionLabel.textColor = UIColor.white.withAlphaComponent(0.52)
        versionLabel.textAlignment = .center

        menuPanelView.contentView.addSubview(menuStackView)
        pageStackView.addArrangedSubview(coverStackView)
        pageStackView.addArrangedSubview(heroPanelView)
        pageStackView.addArrangedSubview(menuPanelView)
        pageStackView.addArrangedSubview(versionLabel)
        coverStackView.translatesAutoresizingMaskIntoConstraints = false
        heroPanelView.translatesAutoresizingMaskIntoConstraints = false
        menuPanelView.translatesAutoresizingMaskIntoConstraints = false
        menuStackView.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        pageStackView.setCustomSpacing(24, after: coverStackView)
        pageStackView.setCustomSpacing(22, after: heroPanelView)
        pageStackView.setCustomSpacing(24, after: menuPanelView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -116),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor),

            pageStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),
            pageStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            pageStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            pageStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),

            heroPanelView.heightAnchor.constraint(greaterThanOrEqualToConstant: 88),

            menuStackView.topAnchor.constraint(equalTo: menuPanelView.contentView.topAnchor, constant: 8),
            menuStackView.leadingAnchor.constraint(equalTo: menuPanelView.contentView.leadingAnchor),
            menuStackView.trailingAnchor.constraint(equalTo: menuPanelView.contentView.trailingAnchor),
            menuStackView.bottomAnchor.constraint(equalTo: menuPanelView.contentView.bottomAnchor, constant: -8)
        ])
    }

    private func renderMenuItems() {
        let nextMenuItems = ProfileItem.visibleItems(isPremium: PremiumAccessStore.shared.isPremium)
        guard nextMenuItems != visibleMenuItems else { return }
        visibleMenuItems = nextMenuItems

        menuStackView.arrangedSubviews.forEach { subview in
            menuStackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }

        visibleMenuItems.enumerated().forEach { index, item in
            let rowView = ProfileMenuRowView(item: item)
            rowView.addTarget(self, action: #selector(handleMenuTap(_:)), for: .touchUpInside)
            rowView.tag = index
            menuStackView.addArrangedSubview(rowView)

            if index < visibleMenuItems.count - 1 {
                let separator = UIView()
                separator.backgroundColor = UIColor.white.withAlphaComponent(0.09)
                menuStackView.addArrangedSubview(separator)
                separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
            }
        }
    }

    @objc
    private func handleMenuTap(_ sender: UIControl) {
        guard let item = visibleMenuItems[safe: sender.tag] else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        switch item {
        case .membership:
            SubscriptionRoute.presentSubscription(from: self, source: .modal)
        case .restorePurchases:
            restorePurchases()
        case .favoriteWallpapers:
            let viewController = FavoriteWallpapersViewController()
            viewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(viewController, animated: true)
        case .privacy, .terms:
            guard let url = item.agreementURL else { return }
            let viewController = AgreementWebViewController(title: item.agreementTitle, url: url)
            viewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(viewController, animated: true)
        }
    }

    private func appVersionText() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        guard let version, !version.isEmpty else {
            return L10n.text("profile.version.empty")
        }

        return L10n.text("profile.version.value", version)
    }

    private func configureObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePremiumAccessDidChange),
            name: .premiumAccessDidChange,
            object: PremiumAccessStore.shared
        )
    }

    @objc
    private func handlePremiumAccessDidChange() {
        renderMenuItems()
    }

    private func restorePurchases() {
        Task { [weak self] in
            do {
                let restored = try await PremiumAccessStore.shared.restorePurchases()
                let message = restored
                    ? L10n.text("subscription.restore.success")
                    : L10n.text("subscription.restore.empty")
                self?.showProfileMessage(title: L10n.text("subscription.restore"), message: message)
            } catch {
                self?.showProfileMessage(title: L10n.text("subscription.error.title"), message: error.localizedDescription)
            }
        }
    }

    private func showProfileMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.text("common.ok"), style: .default))
        present(alert, animated: true)
    }
}

private final class ProfileMenuRowView: UIControl {

    private let iconContainerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let chevronImageView = UIImageView()

    init(item: ProfileViewController.ProfileItem) {
        super.init(frame: .zero)
        configure()
        apply(item: item)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.16, delay: 0, options: [.beginFromCurrentState, .curveEaseOut]) {
                self.alpha = self.isHighlighted ? 0.72 : 1
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.992, y: 0.992) : .identity
            }
        }
    }

    private func configure() {
        backgroundColor = .clear
        isExclusiveTouch = true

        iconContainerView.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        iconContainerView.layer.cornerRadius = 13
        iconContainerView.layer.cornerCurve = .continuous
        iconContainerView.layer.borderWidth = 0.8
        iconContainerView.layer.borderColor = UIColor.white.withAlphaComponent(0.14).cgColor

        iconImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.90)

        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = UIColor.white.withAlphaComponent(0.30)
        chevronImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)

        addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(chevronImageView)

        iconContainerView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 60),

            iconContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            iconContainerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconContainerView.widthAnchor.constraint(equalToConstant: 36),
            iconContainerView.heightAnchor.constraint(equalToConstant: 36),

            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: iconContainerView.trailingAnchor, constant: 14),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronImageView.leadingAnchor, constant: -12),

            chevronImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            chevronImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private func apply(item: ProfileViewController.ProfileItem) {
        iconImageView.image = UIImage(systemName: item.iconName)
        iconImageView.tintColor = item.accentColor
        titleLabel.text = item.title
    }
}

private final class ProfileBackgroundOverlayView: UIView {

    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    private func configure() {
        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0.18).cgColor,
            UIColor.black.withAlphaComponent(0.03).cgColor,
            UIColor.black.withAlphaComponent(0.30).cgColor,
            UIColor.black.withAlphaComponent(0.56).cgColor
        ]
        gradientLayer.locations = [0, 0.34, 0.72, 1]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(gradientLayer)

        backgroundColor = UIColor(red: 0.03, green: 0.03, blue: 0.05, alpha: 0.10)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
