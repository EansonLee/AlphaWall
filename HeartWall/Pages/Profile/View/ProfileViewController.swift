//
//  ProfileViewController.swift
//  HeartWall
//

import UIKit

final class ProfileViewController: BaseViewController {

    fileprivate enum ProfileItem: CaseIterable {
        case favoriteWallpapers
        case privacy
        case terms

        var title: String {
            switch self {
            case .favoriteWallpapers:
                return "喜欢的壁纸"
            case .privacy:
                return "隐私协议"
            case .terms:
                return "用户协议"
            }
        }

        var iconName: String {
            switch self {
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
            case .favoriteWallpapers:
                return UIColor(red: 1.00, green: 0.80, blue: 0.50, alpha: 1)
            case .privacy:
                return UIColor(red: 0.42, green: 0.82, blue: 0.76, alpha: 1)
            case .terms:
                return UIColor(red: 0.66, green: 0.78, blue: 0.98, alpha: 1)
            }
        }
    }

    private let backgroundView = AuroraBackgroundView()
    private let dimView = UIView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let pageStackView = UIStackView()
    private let heroPanelView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let heroContentStackView = UIStackView()
    private let launcherIconContainerView = UIView()
    private let launcherIconImageView = UIImageView(image: UIImage(named: "icon_launcher"))
    private let launcherIconGlowView = UIView()
    private let launcherIconHighlightView = UIView()
    private let headerStackView = UIStackView()
    private let eyebrowLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let menuPanelView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let menuStackView = UIStackView()
    private let versionLabel = UILabel()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        backgroundView.startAnimatingIfNeeded()
    }

    override func setupUI() {
        view.backgroundColor = UIColor(red: 0.06, green: 0.10, blue: 0.14, alpha: 1)
        configureBackground()
        configureContent()
        configureHeader()
        renderMenuItems()
    }

    private func configureBackground() {
        view.addSubview(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.22)
        view.addSubview(dimView)
        dimView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureHeader() {
        heroPanelView.layer.cornerRadius = 26
        heroPanelView.layer.cornerCurve = .continuous
        heroPanelView.clipsToBounds = true
        heroPanelView.layer.borderWidth = 1
        heroPanelView.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor

        heroContentStackView.axis = .horizontal
        heroContentStackView.alignment = .center
        heroContentStackView.spacing = 16
        heroPanelView.contentView.addSubview(heroContentStackView)
        heroContentStackView.translatesAutoresizingMaskIntoConstraints = false

        launcherIconGlowView.backgroundColor = UIColor(red: 1.00, green: 0.75, blue: 0.45, alpha: 0.24)
        launcherIconGlowView.layer.cornerRadius = 30
        launcherIconGlowView.layer.cornerCurve = .continuous
        launcherIconGlowView.isUserInteractionEnabled = false

        launcherIconContainerView.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        launcherIconContainerView.layer.cornerRadius = 20
        launcherIconContainerView.layer.cornerCurve = .continuous
        launcherIconContainerView.layer.borderWidth = 1
        launcherIconContainerView.layer.borderColor = UIColor.white.withAlphaComponent(0.26).cgColor
        launcherIconContainerView.layer.shadowColor = UIColor.black.cgColor
        launcherIconContainerView.layer.shadowOpacity = 0.24
        launcherIconContainerView.layer.shadowRadius = 18
        launcherIconContainerView.layer.shadowOffset = CGSize(width: 0, height: 10)
        launcherIconContainerView.clipsToBounds = false

        launcherIconImageView.contentMode = .scaleAspectFill
        launcherIconImageView.clipsToBounds = true
        launcherIconImageView.layer.cornerRadius = 18
        launcherIconImageView.layer.cornerCurve = .continuous

        launcherIconHighlightView.backgroundColor = UIColor.white.withAlphaComponent(0.22)
        launcherIconHighlightView.layer.cornerRadius = 9
        launcherIconHighlightView.layer.cornerCurve = .continuous
        launcherIconHighlightView.isUserInteractionEnabled = false

        launcherIconContainerView.addSubview(launcherIconGlowView)
        launcherIconContainerView.addSubview(launcherIconImageView)
        launcherIconContainerView.addSubview(launcherIconHighlightView)
        launcherIconGlowView.translatesAutoresizingMaskIntoConstraints = false
        launcherIconImageView.translatesAutoresizingMaskIntoConstraints = false
        launcherIconHighlightView.translatesAutoresizingMaskIntoConstraints = false

        headerStackView.axis = .vertical
        headerStackView.alignment = .leading
        headerStackView.spacing = 4
        headerStackView.isUserInteractionEnabled = false

        eyebrowLabel.text = "栖幕壁纸"
        eyebrowLabel.font = .monospacedSystemFont(ofSize: 11, weight: .semibold)
        eyebrowLabel.textColor = UIColor(red: 1.00, green: 0.86, blue: 0.62, alpha: 0.86)

        titleLabel.text = "我的"
        titleLabel.font = .systemFont(ofSize: 30, weight: .heavy)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.96)

        subtitleLabel.text = "收藏、协议与应用信息"
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.60)
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.minimumScaleFactor = 0.82

        [eyebrowLabel, titleLabel, subtitleLabel].forEach {
            headerStackView.addArrangedSubview($0)
        }

        heroContentStackView.addArrangedSubview(launcherIconContainerView)
        heroContentStackView.addArrangedSubview(headerStackView)

        NSLayoutConstraint.activate([
            heroContentStackView.topAnchor.constraint(equalTo: heroPanelView.contentView.topAnchor, constant: 18),
            heroContentStackView.leadingAnchor.constraint(equalTo: heroPanelView.contentView.leadingAnchor, constant: 18),
            heroContentStackView.trailingAnchor.constraint(equalTo: heroPanelView.contentView.trailingAnchor, constant: -18),
            heroContentStackView.bottomAnchor.constraint(equalTo: heroPanelView.contentView.bottomAnchor, constant: -18),

            launcherIconContainerView.widthAnchor.constraint(equalToConstant: 68),
            launcherIconContainerView.heightAnchor.constraint(equalToConstant: 68),

            launcherIconGlowView.centerXAnchor.constraint(equalTo: launcherIconContainerView.centerXAnchor),
            launcherIconGlowView.centerYAnchor.constraint(equalTo: launcherIconContainerView.centerYAnchor),
            launcherIconGlowView.widthAnchor.constraint(equalToConstant: 84),
            launcherIconGlowView.heightAnchor.constraint(equalToConstant: 84),

            launcherIconImageView.topAnchor.constraint(equalTo: launcherIconContainerView.topAnchor, constant: 4),
            launcherIconImageView.leadingAnchor.constraint(equalTo: launcherIconContainerView.leadingAnchor, constant: 4),
            launcherIconImageView.trailingAnchor.constraint(equalTo: launcherIconContainerView.trailingAnchor, constant: -4),
            launcherIconImageView.bottomAnchor.constraint(equalTo: launcherIconContainerView.bottomAnchor, constant: -4),

            launcherIconHighlightView.topAnchor.constraint(equalTo: launcherIconContainerView.topAnchor, constant: 10),
            launcherIconHighlightView.leadingAnchor.constraint(equalTo: launcherIconContainerView.leadingAnchor, constant: 13),
            launcherIconHighlightView.widthAnchor.constraint(equalToConstant: 28),
            launcherIconHighlightView.heightAnchor.constraint(equalToConstant: 12)
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
        pageStackView.spacing = 28
        contentView.addSubview(pageStackView)
        pageStackView.translatesAutoresizingMaskIntoConstraints = false

        menuPanelView.layer.cornerRadius = 22
        menuPanelView.layer.cornerCurve = .continuous
        menuPanelView.clipsToBounds = true
        menuPanelView.layer.borderWidth = 1
        menuPanelView.layer.borderColor = UIColor.white.withAlphaComponent(0.16).cgColor
        menuPanelView.layer.shadowColor = UIColor.black.cgColor
        menuPanelView.layer.shadowOpacity = 0.12
        menuPanelView.layer.shadowRadius = 20
        menuPanelView.layer.shadowOffset = CGSize(width: 0, height: 12)

        menuStackView.axis = .vertical
        menuStackView.spacing = 0

        versionLabel.text = appVersionText()
        versionLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        versionLabel.textColor = UIColor.white.withAlphaComponent(0.44)
        versionLabel.textAlignment = .center

        menuPanelView.contentView.addSubview(menuStackView)
        pageStackView.addArrangedSubview(heroPanelView)
        pageStackView.addArrangedSubview(menuPanelView)
        pageStackView.addArrangedSubview(versionLabel)
        heroPanelView.translatesAutoresizingMaskIntoConstraints = false
        menuPanelView.translatesAutoresizingMaskIntoConstraints = false
        menuStackView.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        pageStackView.setCustomSpacing(18, after: heroPanelView)
        pageStackView.setCustomSpacing(22, after: menuPanelView)

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

            pageStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 28),
            pageStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 22),
            pageStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -22),
            pageStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),

            heroPanelView.heightAnchor.constraint(greaterThanOrEqualToConstant: 104),

            menuStackView.topAnchor.constraint(equalTo: menuPanelView.contentView.topAnchor, constant: 8),
            menuStackView.leadingAnchor.constraint(equalTo: menuPanelView.contentView.leadingAnchor),
            menuStackView.trailingAnchor.constraint(equalTo: menuPanelView.contentView.trailingAnchor),
            menuStackView.bottomAnchor.constraint(equalTo: menuPanelView.contentView.bottomAnchor, constant: -8)
        ])
    }

    private func renderMenuItems() {
        ProfileItem.allCases.enumerated().forEach { index, item in
            let rowView = ProfileMenuRowView(item: item)
            rowView.addTarget(self, action: #selector(handleMenuTap(_:)), for: .touchUpInside)
            rowView.tag = index
            menuStackView.addArrangedSubview(rowView)

            if index < ProfileItem.allCases.count - 1 {
                let separator = UIView()
                separator.backgroundColor = UIColor.white.withAlphaComponent(0.08)
                menuStackView.addArrangedSubview(separator)
                separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
            }
        }
    }

    @objc
    private func handleMenuTap(_ sender: UIControl) {
        guard let item = ProfileItem.allCases[safe: sender.tag] else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        switch item {
        case .favoriteWallpapers:
            let viewController = FavoriteWallpapersViewController()
            viewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(viewController, animated: true)
        case .privacy, .terms:
            break
        }
    }

    private func appVersionText() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        guard let version, !version.isEmpty else {
            return "版本"
        }

        return "版本 v\(version)"
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

        iconContainerView.layer.cornerRadius = 12
        iconContainerView.layer.cornerCurve = .continuous

        iconImageView.tintColor = UIColor.black.withAlphaComponent(0.72)
        iconImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)

        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.92)

        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = UIColor.white.withAlphaComponent(0.28)
        chevronImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)

        addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(chevronImageView)

        iconContainerView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 58),

            iconContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconContainerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconContainerView.widthAnchor.constraint(equalToConstant: 34),
            iconContainerView.heightAnchor.constraint(equalToConstant: 34),

            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: iconContainerView.trailingAnchor, constant: 13),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronImageView.leadingAnchor, constant: -12),

            chevronImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            chevronImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private func apply(item: ProfileViewController.ProfileItem) {
        iconImageView.image = UIImage(systemName: item.iconName)
        titleLabel.text = item.title
        iconContainerView.backgroundColor = item.accentColor
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
