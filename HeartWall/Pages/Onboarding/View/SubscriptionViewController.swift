//
//  SubscriptionViewController.swift
//  HeartWall
//

import UIKit

final class SubscriptionViewController: BaseViewController {

    // MARK: - Properties

    private let videoResource: OnboardingVideoResource

    // MARK: - UI

    private let backgroundVideoView = LoopingVideoView()
    private let dimOverlayView = UIView()
    private let auroraView = AuroraBackgroundView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let closeButton = UIButton(type: .system)
    private let restoreButton = UIButton(type: .system)
    private let heroPillView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
    private let heroPillLabel = UILabel()
    private let phoneContainerView = UIView()
    private let phoneBorderView = UIView()
    private let previewVideoView = LoopingVideoView()
    private let previewTimeLabel = UILabel()
    private let previewDateLabel = UILabel()
    private let previewBadgeLabel = UILabel()
    private let contentStackView = UIStackView()
    private let eyebrowLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let benefitStackView = UIStackView()
    private let trialButton = GradientCapsuleButton()
    private let noteLabel = UILabel()
    private let legalLabel = UILabel()

    // MARK: - Lifecycle

    init(videoResource: OnboardingVideoResource) {
        self.videoResource = videoResource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        auroraView.startAnimatingIfNeeded()
        startFloatingAnimationIfNeeded()
    }

    // MARK: - Setup

    override func setupUI() {
        view.backgroundColor = .black

        if let videoURL = videoResource.bundleURL() {
            backgroundVideoView.configure(url: videoURL, isMuted: true)
            previewVideoView.configure(url: videoURL, isMuted: true)
        }

        dimOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.26)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never

        configureTopButtons()
        configurePreviewCard()
        configureContent()

        [backgroundVideoView, dimOverlayView, auroraView, scrollView].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        [closeButton, restoreButton, heroPillView, phoneContainerView, contentStackView].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            backgroundVideoView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundVideoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundVideoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundVideoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            dimOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            dimOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            auroraView.topAnchor.constraint(equalTo: view.topAnchor),
            auroraView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            auroraView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            auroraView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor),

            closeButton.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 10),
            closeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),

            restoreButton.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            restoreButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            heroPillView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 24),
            heroPillView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            phoneContainerView.topAnchor.constraint(equalTo: heroPillView.bottomAnchor, constant: 16),
            phoneContainerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            phoneContainerView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.60),
            phoneContainerView.widthAnchor.constraint(lessThanOrEqualToConstant: 276),
            phoneContainerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 214),
            phoneContainerView.heightAnchor.constraint(equalTo: phoneContainerView.widthAnchor, multiplier: 1.94),

            contentStackView.topAnchor.constraint(equalTo: phoneContainerView.bottomAnchor, constant: 26),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 26),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -26),
            contentStackView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    private func configureTopButtons() {
        var closeConfiguration = UIButton.Configuration.plain()
        closeConfiguration.baseForegroundColor = UIColor.white.withAlphaComponent(0.88)
        closeConfiguration.contentInsets = .zero
        closeConfiguration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        closeButton.configuration = closeConfiguration
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        closeButton.layer.cornerRadius = 18
        closeButton.layer.cornerCurve = .continuous
        closeButton.layer.borderWidth = 1
        closeButton.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        closeButton.addTarget(self, action: #selector(handleEnterHome), for: .touchUpInside)

        var restoreConfiguration = UIButton.Configuration.plain()
        restoreConfiguration.title = "恢复购买"
        restoreConfiguration.baseForegroundColor = UIColor.white.withAlphaComponent(0.74)
        restoreConfiguration.contentInsets = .zero
        restoreButton.configuration = restoreConfiguration
        restoreButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        restoreButton.addTarget(self, action: #selector(handleRestore), for: .touchUpInside)
    }

    private func configurePreviewCard() {
        heroPillView.layer.cornerRadius = 17
        heroPillView.layer.cornerCurve = .continuous
        heroPillView.clipsToBounds = true
        heroPillView.layer.borderWidth = 1
        heroPillView.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor

        heroPillLabel.text = "精选导入片段"
        heroPillLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        heroPillLabel.textColor = UIColor.white.withAlphaComponent(0.90)
        heroPillView.contentView.addSubview(heroPillLabel)
        heroPillLabel.translatesAutoresizingMaskIntoConstraints = false

        phoneContainerView.layer.shadowColor = UIColor.black.cgColor
        phoneContainerView.layer.shadowOpacity = 0.28
        phoneContainerView.layer.shadowRadius = 34
        phoneContainerView.layer.shadowOffset = CGSize(width: 0, height: 22)

        phoneBorderView.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        phoneBorderView.layer.cornerRadius = 42
        phoneBorderView.layer.cornerCurve = .continuous
        phoneBorderView.layer.borderWidth = 4
        phoneBorderView.layer.borderColor = UIColor.white.withAlphaComponent(0.82).cgColor
        phoneBorderView.clipsToBounds = true

        let phoneGlassOverlay = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
        phoneGlassOverlay.alpha = 0.18

        previewTimeLabel.text = currentTimeText()
        previewTimeLabel.font = .systemFont(ofSize: 54, weight: .bold)
        previewTimeLabel.textColor = UIColor.white.withAlphaComponent(0.96)
        previewTimeLabel.textAlignment = .center

        previewDateLabel.text = currentDateText()
        previewDateLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        previewDateLabel.textColor = UIColor.white.withAlphaComponent(0.88)
        previewDateLabel.textAlignment = .center

        previewBadgeLabel.text = "本地珍藏"
        previewBadgeLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        previewBadgeLabel.textColor = UIColor.white.withAlphaComponent(0.92)
        previewBadgeLabel.backgroundColor = UIColor.black.withAlphaComponent(0.16)
        previewBadgeLabel.layer.cornerRadius = 12
        previewBadgeLabel.layer.cornerCurve = .continuous
        previewBadgeLabel.clipsToBounds = true
        previewBadgeLabel.textAlignment = .center

        [phoneBorderView].forEach(phoneContainerView.addSubview)
        [previewVideoView, phoneGlassOverlay, previewDateLabel, previewTimeLabel, previewBadgeLabel].forEach {
            phoneBorderView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        phoneBorderView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            heroPillLabel.topAnchor.constraint(equalTo: heroPillView.contentView.topAnchor, constant: 9),
            heroPillLabel.leadingAnchor.constraint(equalTo: heroPillView.contentView.leadingAnchor, constant: 16),
            heroPillLabel.trailingAnchor.constraint(equalTo: heroPillView.contentView.trailingAnchor, constant: -16),
            heroPillLabel.bottomAnchor.constraint(equalTo: heroPillView.contentView.bottomAnchor, constant: -9),

            phoneBorderView.topAnchor.constraint(equalTo: phoneContainerView.topAnchor),
            phoneBorderView.leadingAnchor.constraint(equalTo: phoneContainerView.leadingAnchor),
            phoneBorderView.trailingAnchor.constraint(equalTo: phoneContainerView.trailingAnchor),
            phoneBorderView.bottomAnchor.constraint(equalTo: phoneContainerView.bottomAnchor),

            previewVideoView.topAnchor.constraint(equalTo: phoneBorderView.topAnchor),
            previewVideoView.leadingAnchor.constraint(equalTo: phoneBorderView.leadingAnchor),
            previewVideoView.trailingAnchor.constraint(equalTo: phoneBorderView.trailingAnchor),
            previewVideoView.bottomAnchor.constraint(equalTo: phoneBorderView.bottomAnchor),

            phoneGlassOverlay.topAnchor.constraint(equalTo: phoneBorderView.topAnchor),
            phoneGlassOverlay.leadingAnchor.constraint(equalTo: phoneBorderView.leadingAnchor),
            phoneGlassOverlay.trailingAnchor.constraint(equalTo: phoneBorderView.trailingAnchor),
            phoneGlassOverlay.bottomAnchor.constraint(equalTo: phoneBorderView.bottomAnchor),

            previewDateLabel.topAnchor.constraint(equalTo: phoneBorderView.topAnchor, constant: 56),
            previewDateLabel.centerXAnchor.constraint(equalTo: phoneBorderView.centerXAnchor),

            previewTimeLabel.topAnchor.constraint(equalTo: previewDateLabel.bottomAnchor, constant: 6),
            previewTimeLabel.centerXAnchor.constraint(equalTo: phoneBorderView.centerXAnchor),

            previewBadgeLabel.topAnchor.constraint(equalTo: phoneBorderView.topAnchor, constant: 20),
            previewBadgeLabel.trailingAnchor.constraint(equalTo: phoneBorderView.trailingAnchor, constant: -18),
            previewBadgeLabel.widthAnchor.constraint(equalToConstant: 76),
            previewBadgeLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    private func configureContent() {
        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.spacing = 16

        eyebrowLabel.text = "沉浸式私密体验"
        eyebrowLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        eyebrowLabel.textColor = UIColor(red: 1, green: 0.88, blue: 0.68, alpha: 1)
        eyebrowLabel.textAlignment = .center

        titleLabel.text = "让私密视频\n拥有更安静的入口"
        titleLabel.font = serifFont(size: 36, weight: .bold)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.98)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center

        subtitleLabel.text = "本地优先、轻盈导入、细腻预览。\n先用视觉质感建立信任，再进入你的个人内容空间。"
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.72)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center

        benefitStackView.axis = .vertical
        benefitStackView.alignment = .fill
        benefitStackView.spacing = 10

        let benefits = [
            BenefitRowView(iconName: "lock.shield.fill", title: "本地优先管理私密视频，不默认依赖云端"),
            BenefitRowView(iconName: "square.and.arrow.down.on.square.fill", title: "支持从分享面板快速导入常用内容"),
            BenefitRowView(iconName: "play.square.stack.fill", title: "精选动效预览，让内容展示更有仪式感"),
            BenefitRowView(iconName: "eye.slash.fill", title: "弱打扰式订阅入口，浏览与离开都更克制")
        ]
        benefits.forEach(benefitStackView.addArrangedSubview)

        trialButton.setTitle("免费试用", for: .normal)
        trialButton.addTarget(self, action: #selector(handleEnterHome), for: .touchUpInside)

        noteLabel.text = "当前为预览版本，订阅购买能力暂未接入"
        noteLabel.font = .systemFont(ofSize: 13, weight: .medium)
        noteLabel.textColor = UIColor.white.withAlphaComponent(0.76)
        noteLabel.textAlignment = .center
        noteLabel.numberOfLines = 0

        legalLabel.text = "继续即表示你已阅读《会员协议》与《自动续费说明》。本轮仅实现页面与跳转，不触发真实扣费。"
        legalLabel.font = .systemFont(ofSize: 11, weight: .medium)
        legalLabel.textColor = UIColor.white.withAlphaComponent(0.48)
        legalLabel.textAlignment = .center
        legalLabel.numberOfLines = 0

        [eyebrowLabel, titleLabel, subtitleLabel, benefitStackView, trialButton, noteLabel, legalLabel].forEach {
            contentStackView.addArrangedSubview($0)
        }

        NSLayoutConstraint.activate([
            trialButton.heightAnchor.constraint(equalToConstant: 58)
        ])
    }

    // MARK: - Actions

    @objc
    private func handleEnterHome() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        backgroundVideoView.pause()
        previewVideoView.pause()

        guard let navigationController else { return }
        let libraryViewController = LibraryViewController()

        UIView.transition(
            with: navigationController.view,
            duration: UIAccessibility.isReduceMotionEnabled ? 0.15 : 0.40,
            options: [.transitionCrossDissolve, .allowAnimatedContent]
        ) {
            navigationController.setViewControllers([libraryViewController], animated: false)
        }
    }

    @objc
    private func handleRestore() {
        let alert = UIAlertController(title: "恢复购买", message: "当前版本仅完成订阅页预览，真实购买能力暂未接入。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "知道了", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Helpers

    private func currentDateText() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: Date())
    }

    private func currentTimeText() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }

    private func startFloatingAnimationIfNeeded() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }

        phoneContainerView.transform = .identity
        UIView.animate(
            withDuration: 3.8,
            delay: 0,
            options: [.allowUserInteraction, .autoreverse, .curveEaseInOut, .repeat]
        ) {
            self.phoneContainerView.transform = CGAffineTransform(translationX: 0, y: -10)
        }
    }

    private func serifFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        let descriptor = systemFont.fontDescriptor.withDesign(.serif) ?? systemFont.fontDescriptor
        return UIFont(descriptor: descriptor, size: size)
    }
}

private final class BenefitRowView: UIVisualEffectView {

    init(iconName: String, title: String) {
        super.init(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))

        layer.cornerRadius = 20
        layer.cornerCurve = .continuous
        clipsToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor

        let iconWrap = UIView()
        iconWrap.backgroundColor = UIColor(red: 1, green: 0.88, blue: 0.68, alpha: 0.14)
        iconWrap.layer.cornerRadius = 15
        iconWrap.layer.cornerCurve = .continuous

        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = UIColor(red: 1, green: 0.88, blue: 0.68, alpha: 1)
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.88)
        titleLabel.numberOfLines = 0

        contentView.addSubview(iconWrap)
        contentView.addSubview(titleLabel)
        iconWrap.addSubview(iconView)

        [iconWrap, iconView, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            iconWrap.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            iconWrap.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconWrap.widthAnchor.constraint(equalToConstant: 30),
            iconWrap.heightAnchor.constraint(equalToConstant: 30),

            iconView.centerXAnchor.constraint(equalTo: iconWrap.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconWrap.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: iconWrap.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class GradientCapsuleButton: UIButton {

    private let gradientLayer = CAGradientLayer()
    private let glowLayer = CALayer()

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
        gradientLayer.cornerRadius = bounds.height * 0.5
        glowLayer.frame = CGRect(x: bounds.width * 0.12, y: 8, width: bounds.width * 0.40, height: bounds.height * 0.28)
        glowLayer.cornerRadius = glowLayer.bounds.height * 0.5
    }

    private func configure() {
        clipsToBounds = false
        layer.cornerRadius = 29
        layer.cornerCurve = .continuous
        layer.insertSublayer(gradientLayer, at: 0)
        layer.insertSublayer(glowLayer, above: gradientLayer)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.18
        layer.shadowRadius = 20
        layer.shadowOffset = CGSize(width: 0, height: 10)

        gradientLayer.colors = [
            UIColor(red: 0.98, green: 0.88, blue: 0.72, alpha: 1).cgColor,
            UIColor(red: 0.95, green: 0.76, blue: 0.53, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)

        glowLayer.backgroundColor = UIColor.white.withAlphaComponent(0.20).cgColor
        glowLayer.opacity = 1

        setTitleColor(UIColor(red: 0.34, green: 0.23, blue: 0.10, alpha: 1), for: .normal)
        titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
    }
}
