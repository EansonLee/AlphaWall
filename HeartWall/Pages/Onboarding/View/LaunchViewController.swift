//
//  LaunchViewController.swift
//  HeartWall
//

import UIKit

final class LaunchViewController: BaseViewController {

    // MARK: - Properties

    private var hasTransitioned = false
    private var transitionWorkItem: DispatchWorkItem?
    private var didAnimateEntrance = false

    // MARK: - UI

    private let backgroundImageView = UIImageView()
    private let topScrimView = GradientView()
    private let bottomScrimView = GradientView()
    private let brandStackView = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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

        backgroundImageView.image = UIImage(named: "LaunchBackground")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true

        topScrimView.configure(colors: [
            UIColor.black.withAlphaComponent(0.50),
            UIColor.black.withAlphaComponent(0.18),
            UIColor.black.withAlphaComponent(0.00)
        ])

        bottomScrimView.configure(colors: [
            UIColor.black.withAlphaComponent(0.00),
            UIColor.black.withAlphaComponent(0.22),
            UIColor.black.withAlphaComponent(0.64)
        ])

        titleLabel.text = "栖幕壁纸"
        titleLabel.font = .systemFont(ofSize: 38, weight: .semibold)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.98)
        titleLabel.textAlignment = .left
        titleLabel.adjustsFontForContentSizeCategory = true

        subtitleLabel.text = "把珍藏留在此刻"
        subtitleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.76)
        subtitleLabel.textAlignment = .left
        subtitleLabel.numberOfLines = 0
        subtitleLabel.adjustsFontForContentSizeCategory = true

        brandStackView.axis = .vertical
        brandStackView.alignment = .leading
        brandStackView.spacing = 8
        brandStackView.alpha = 0
        brandStackView.addArrangedSubview(titleLabel)
        brandStackView.addArrangedSubview(subtitleLabel)

        [backgroundImageView, topScrimView, bottomScrimView, brandStackView].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSkip))
        view.addGestureRecognizer(tapGesture)

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            topScrimView.topAnchor.constraint(equalTo: view.topAnchor),
            topScrimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topScrimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topScrimView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.42),

            bottomScrimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomScrimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomScrimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomScrimView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.44),

            brandStackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            brandStackView.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor),
            brandStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -46)
        ])
    }

    // MARK: - Actions

    @objc
    private func handleSkip() {
        showHome()
    }

    private func scheduleTransitionIfNeeded() {
        guard transitionWorkItem == nil else { return }

        let workItem = DispatchWorkItem { [weak self] in
            self?.showHome()
        }
        transitionWorkItem = workItem

        DispatchQueue.main.asyncAfter(deadline: .now() + transitionDelay, execute: workItem)
    }

    private var transitionDelay: TimeInterval {
        2.8
    }

    private func showHome() {
        guard !hasTransitioned, let navigationController else { return }
        hasTransitioned = true
        transitionWorkItem?.cancel()

        let homeRootViewController = HomeRootViewController()

        UIView.transition(
            with: navigationController.view,
            duration: UIAccessibility.isReduceMotionEnabled ? 0.15 : 0.45,
            options: [.transitionCrossDissolve, .allowAnimatedContent]
        ) {
            navigationController.setViewControllers([homeRootViewController], animated: false)
        }
    }

    private func animateEntranceIfNeeded() {
        guard !didAnimateEntrance else { return }
        didAnimateEntrance = true

        guard !UIAccessibility.isReduceMotionEnabled else {
            brandStackView.alpha = 1
            return
        }

        backgroundImageView.transform = CGAffineTransform(scaleX: 1.025, y: 1.025)
        brandStackView.transform = CGAffineTransform(translationX: 0, y: 16)

        UIView.animate(withDuration: 1.2, delay: 0, options: [.curveEaseOut]) {
            self.backgroundImageView.transform = .identity
        }

        UIView.animate(withDuration: 0.85, delay: 0.18, options: [.curveEaseOut]) {
            self.brandStackView.alpha = 1
            self.brandStackView.transform = .identity
        }
    }

    // MARK: - Helpers

    private final class GradientView: UIView {
        override class var layerClass: AnyClass {
            CAGradientLayer.self
        }

        func configure(colors: [UIColor]) {
            guard let gradientLayer = layer as? CAGradientLayer else { return }
            gradientLayer.colors = colors.map(\.cgColor)
            gradientLayer.locations = [0, 0.58, 1]
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        }
    }
}
