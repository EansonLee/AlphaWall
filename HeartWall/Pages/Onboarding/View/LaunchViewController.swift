//
//  LaunchViewController.swift
//  HeartWall
//

import UIKit
import AVFoundation

final class LaunchViewController: BaseViewController {

    // MARK: - Properties

    private let videoResource = OnboardingVideoProvider.shared.selectedResource
    private var hasTransitioned = false
    private var transitionWorkItem: DispatchWorkItem?

    // MARK: - UI

    private let backgroundVideoView = LoopingVideoView()
    private let dimOverlayView = UIView()
    private let auroraView = AuroraBackgroundView()
    private let iconView = PremiumAppIconView(sideLength: 90)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let metricsStackView = UIStackView()
    private let taglineLabel = UILabel()
    private let centerStackView = UIStackView()

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        auroraView.startAnimatingIfNeeded()
        backgroundVideoView.play()
        scheduleTransitionIfNeeded()
        animateEntranceIfNeeded()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        transitionWorkItem?.cancel()
    }

    // MARK: - Setup

    override func setupUI() {
        view.backgroundColor = .black

        if let videoURL = videoResource.bundleURL() {
            backgroundVideoView.configure(url: videoURL, isMuted: false)
        }

        dimOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.18)

        titleLabel.text = "HeartWall"
        titleLabel.font = serifFont(size: 34, weight: .bold)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.98)
        titleLabel.textAlignment = .center

        subtitleLabel.text = "本地优先的私密视频空间"
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.78)
        subtitleLabel.textAlignment = .center

        metricsStackView.axis = .horizontal
        metricsStackView.alignment = .fill
        metricsStackView.distribution = .fillEqually
        metricsStackView.spacing = 10

        let metricViews = [
            makeMetricView(symbol: "sparkles", title: "动态质感", subtitle: "沉浸氛围"),
            makeMetricView(symbol: "lock.shield.fill", title: "本地优先", subtitle: "私密安心"),
            makeMetricView(symbol: "star.fill", title: "4.9", subtitle: "设计体验")
        ]
        metricViews.forEach(metricsStackView.addArrangedSubview)

        centerStackView.axis = .vertical
        centerStackView.alignment = .center
        centerStackView.spacing = 18
        centerStackView.addArrangedSubview(iconView)
        centerStackView.addArrangedSubview(titleLabel)
        centerStackView.addArrangedSubview(subtitleLabel)
        centerStackView.addArrangedSubview(metricsStackView)

        taglineLabel.text = "让每一段珍藏，都有更好的出场方式"
        taglineLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        taglineLabel.textColor = UIColor.white.withAlphaComponent(0.84)
        taglineLabel.textAlignment = .center
        taglineLabel.numberOfLines = 0

        [backgroundVideoView, dimOverlayView, auroraView, centerStackView, taglineLabel].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSkip))
        view.addGestureRecognizer(tapGesture)

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

            centerStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            centerStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            centerStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -72),

            metricsStackView.widthAnchor.constraint(equalTo: centerStackView.widthAnchor),
            metricsStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 72),

            taglineLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            taglineLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            taglineLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -42)
        ])
    }

    // MARK: - Actions

    @objc
    private func handleSkip() {
        showSubscription()
    }

    private func scheduleTransitionIfNeeded() {
        guard transitionWorkItem == nil else { return }

        let workItem = DispatchWorkItem { [weak self] in
            self?.showSubscription()
        }
        transitionWorkItem = workItem

        DispatchQueue.main.asyncAfter(deadline: .now() + transitionDelay, execute: workItem)
    }

    private var transitionDelay: TimeInterval {
        guard let url = videoResource.bundleURL() else { return 2.6 }
        let duration = CMTimeGetSeconds(AVURLAsset(url: url).duration)
        guard duration.isFinite, duration > 0 else { return 2.6 }
        return min(max(duration, 2.4), 3.8)
    }

    private func showSubscription() {
        guard !hasTransitioned, let navigationController else { return }
        hasTransitioned = true
        transitionWorkItem?.cancel()

        let subscriptionViewController = SubscriptionViewController(videoResource: videoResource)

        UIView.transition(
            with: navigationController.view,
            duration: UIAccessibility.isReduceMotionEnabled ? 0.15 : 0.45,
            options: [.transitionCrossDissolve, .allowAnimatedContent]
        ) {
            navigationController.setViewControllers([subscriptionViewController], animated: false)
        }
    }

    private func animateEntranceIfNeeded() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }

        centerStackView.alpha = 0
        centerStackView.transform = CGAffineTransform(translationX: 0, y: 18).scaledBy(x: 0.98, y: 0.98)
        taglineLabel.alpha = 0
        taglineLabel.transform = CGAffineTransform(translationX: 0, y: 14)

        UIView.animate(withDuration: 0.8, delay: 0.08, options: [.curveEaseOut]) {
            self.centerStackView.alpha = 1
            self.centerStackView.transform = .identity
        }

        UIView.animate(withDuration: 0.8, delay: 0.24, options: [.curveEaseOut]) {
            self.taglineLabel.alpha = 1
            self.taglineLabel.transform = .identity
        }
    }

    // MARK: - Helpers

    private func makeMetricView(symbol: String, title: String, subtitle: String) -> UIView {
        let container = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        container.layer.cornerRadius = 20
        container.layer.cornerCurve = .continuous
        container.clipsToBounds = true
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor

        let iconView = UIImageView(image: UIImage(systemName: symbol))
        iconView.tintColor = UIColor(red: 1, green: 0.87, blue: 0.63, alpha: 1)
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)

        let titleView = UILabel()
        titleView.text = title
        titleView.font = .systemFont(ofSize: 13, weight: .semibold)
        titleView.textColor = UIColor.white.withAlphaComponent(0.96)
        titleView.textAlignment = .center

        let subtitleView = UILabel()
        subtitleView.text = subtitle
        subtitleView.font = .systemFont(ofSize: 11, weight: .medium)
        subtitleView.textColor = UIColor.white.withAlphaComponent(0.64)
        subtitleView.textAlignment = .center

        let stackView = UIStackView(arrangedSubviews: [iconView, titleView, subtitleView])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 6

        container.contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: container.contentView.topAnchor, constant: 14),
            stackView.leadingAnchor.constraint(equalTo: container.contentView.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: container.contentView.trailingAnchor, constant: -10),
            stackView.bottomAnchor.constraint(equalTo: container.contentView.bottomAnchor, constant: -14)
        ])

        return container
    }

    private func serifFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        let descriptor = systemFont.fontDescriptor.withDesign(.serif) ?? systemFont.fontDescriptor
        return UIFont(descriptor: descriptor, size: size)
    }
}
