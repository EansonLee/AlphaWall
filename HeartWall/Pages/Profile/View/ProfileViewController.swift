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

    private let backgroundImageView = UIImageView(image: UIImage(named: "MyPageBackground"))
    private let backgroundOverlayView = ProfileBackgroundOverlayView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let pageStackView = UIStackView()
    private let pageTitleLabel = UILabel()
    private let heroPanelView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
    private let heroContentStackView = UIStackView()
    private let avatarContainerView = UIView()
    private let avatarInitialLabel = UILabel()
    private let headerStackView = UIStackView()
    private let nicknameLabel = UILabel()
    private let statusLabel = UILabel()
    private let menuPanelView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
    private let menuStackView = UIStackView()
    private let versionLabel = UILabel()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1)
        configureBackground()
        configureHeader()
        configureContent()
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
        pageTitleLabel.text = "我的"
        pageTitleLabel.font = .systemFont(ofSize: 34, weight: .heavy)
        pageTitleLabel.textColor = UIColor.white.withAlphaComponent(0.96)
        pageTitleLabel.shadowColor = UIColor.black.withAlphaComponent(0.18)
        pageTitleLabel.shadowOffset = CGSize(width: 0, height: 2)

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

        avatarContainerView.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        avatarContainerView.layer.cornerRadius = 31
        avatarContainerView.layer.cornerCurve = .continuous
        avatarContainerView.layer.borderWidth = 1
        avatarContainerView.layer.borderColor = UIColor.white.withAlphaComponent(0.32).cgColor
        avatarContainerView.clipsToBounds = true

        avatarInitialLabel.text = "栖"
        avatarInitialLabel.font = .systemFont(ofSize: 28, weight: .semibold)
        avatarInitialLabel.textAlignment = .center
        avatarInitialLabel.textColor = UIColor.white.withAlphaComponent(0.96)

        avatarContainerView.addSubview(avatarInitialLabel)
        avatarInitialLabel.translatesAutoresizingMaskIntoConstraints = false

        headerStackView.axis = .vertical
        headerStackView.alignment = .leading
        headerStackView.spacing = 5
        headerStackView.isUserInteractionEnabled = false

        nicknameLabel.text = "栖幕用户"
        nicknameLabel.font = .systemFont(ofSize: 22, weight: .bold)
        nicknameLabel.textColor = UIColor.white.withAlphaComponent(0.96)
        nicknameLabel.adjustsFontSizeToFitWidth = true
        nicknameLabel.minimumScaleFactor = 0.86

        statusLabel.text = "收藏喜欢的壁纸，保留安静灵感"
        statusLabel.font = .systemFont(ofSize: 13, weight: .medium)
        statusLabel.textColor = UIColor.white.withAlphaComponent(0.66)
        statusLabel.adjustsFontSizeToFitWidth = true
        statusLabel.minimumScaleFactor = 0.82

        [nicknameLabel, statusLabel].forEach {
            headerStackView.addArrangedSubview($0)
        }

        heroContentStackView.addArrangedSubview(avatarContainerView)
        heroContentStackView.addArrangedSubview(headerStackView)

        NSLayoutConstraint.activate([
            heroContentStackView.topAnchor.constraint(equalTo: heroPanelView.contentView.topAnchor, constant: 20),
            heroContentStackView.leadingAnchor.constraint(equalTo: heroPanelView.contentView.leadingAnchor, constant: 20),
            heroContentStackView.trailingAnchor.constraint(equalTo: heroPanelView.contentView.trailingAnchor, constant: -20),
            heroContentStackView.bottomAnchor.constraint(equalTo: heroPanelView.contentView.bottomAnchor, constant: -20),

            avatarContainerView.widthAnchor.constraint(equalToConstant: 62),
            avatarContainerView.heightAnchor.constraint(equalToConstant: 62),

            avatarInitialLabel.topAnchor.constraint(equalTo: avatarContainerView.topAnchor),
            avatarInitialLabel.leadingAnchor.constraint(equalTo: avatarContainerView.leadingAnchor),
            avatarInitialLabel.trailingAnchor.constraint(equalTo: avatarContainerView.trailingAnchor),
            avatarInitialLabel.bottomAnchor.constraint(equalTo: avatarContainerView.bottomAnchor)
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
        pageStackView.addArrangedSubview(pageTitleLabel)
        pageStackView.addArrangedSubview(heroPanelView)
        pageStackView.addArrangedSubview(menuPanelView)
        pageStackView.addArrangedSubview(versionLabel)
        pageTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        heroPanelView.translatesAutoresizingMaskIntoConstraints = false
        menuPanelView.translatesAutoresizingMaskIntoConstraints = false
        menuStackView.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
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

            pageStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            pageStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            pageStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            pageStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),

            heroPanelView.heightAnchor.constraint(greaterThanOrEqualToConstant: 112),

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
                separator.backgroundColor = UIColor.white.withAlphaComponent(0.09)
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
