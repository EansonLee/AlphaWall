//
//  AuroraBackgroundView.swift
//  HeartWall
//

import UIKit

final class AuroraBackgroundView: UIView {

    // MARK: - UI

    private let frostView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let vignetteView = UIView()
    private let orbViews: [UIView] = [UIView(), UIView(), UIView()]
    private let vignetteLayer = CAGradientLayer()

    private var isAnimating = false

    // MARK: - Lifecycle

    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    private var gradientLayer: CAGradientLayer {
        layer as! CAGradientLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        vignetteLayer.frame = vignetteView.bounds
        layoutOrbs()
    }

    // MARK: - Setup

    private func configure() {
        isUserInteractionEnabled = false

        gradientLayer.colors = [
            UIColor(red: 0.03, green: 0.08, blue: 0.15, alpha: 1).cgColor,
            UIColor(red: 0.06, green: 0.26, blue: 0.34, alpha: 1).cgColor,
            UIColor(red: 0.30, green: 0.38, blue: 0.27, alpha: 1).cgColor,
            UIColor(red: 0.08, green: 0.12, blue: 0.17, alpha: 1).cgColor
        ]
        gradientLayer.locations = [0, 0.34, 0.72, 1]
        gradientLayer.startPoint = CGPoint(x: 0.15, y: 0.05)
        gradientLayer.endPoint = CGPoint(x: 0.88, y: 0.94)

        let orbColors: [UIColor] = [
            UIColor(red: 0.27, green: 0.87, blue: 0.80, alpha: 0.34),
            UIColor(red: 0.55, green: 0.74, blue: 0.99, alpha: 0.24),
            UIColor(red: 0.98, green: 0.84, blue: 0.62, alpha: 0.20)
        ]

        orbViews.enumerated().forEach { index, orbView in
            orbView.backgroundColor = orbColors[index]
            orbView.alpha = 1
            orbView.layer.cornerCurve = .continuous
            orbView.layer.masksToBounds = true
            addSubview(orbView)
        }

        frostView.alpha = 0.56
        addSubview(frostView)
        frostView.translatesAutoresizingMaskIntoConstraints = false

        vignetteLayer.colors = [
            UIColor(white: 0, alpha: 0.42).cgColor,
            UIColor(white: 0, alpha: 0.08).cgColor,
            UIColor(white: 0, alpha: 0.48).cgColor
        ]
        vignetteLayer.locations = [0, 0.48, 1]
        vignetteLayer.startPoint = CGPoint(x: 0.5, y: 0)
        vignetteLayer.endPoint = CGPoint(x: 0.5, y: 1)
        vignetteView.layer.addSublayer(vignetteLayer)
        addSubview(vignetteView)
        vignetteView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            frostView.topAnchor.constraint(equalTo: topAnchor),
            frostView.leadingAnchor.constraint(equalTo: leadingAnchor),
            frostView.trailingAnchor.constraint(equalTo: trailingAnchor),
            frostView.bottomAnchor.constraint(equalTo: bottomAnchor),

            vignetteView.topAnchor.constraint(equalTo: topAnchor),
            vignetteView.leadingAnchor.constraint(equalTo: leadingAnchor),
            vignetteView.trailingAnchor.constraint(equalTo: trailingAnchor),
            vignetteView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func layoutOrbs() {
        let configurations: [(CGSize, CGPoint)] = [
            (CGSize(width: bounds.width * 0.64, height: bounds.width * 0.64), CGPoint(x: bounds.width * 0.12, y: bounds.height * 0.10)),
            (CGSize(width: bounds.width * 0.58, height: bounds.width * 0.58), CGPoint(x: bounds.width * 0.54, y: bounds.height * 0.16)),
            (CGSize(width: bounds.width * 0.72, height: bounds.width * 0.72), CGPoint(x: bounds.width * 0.22, y: bounds.height * 0.60))
        ]

        zip(orbViews, configurations).forEach { orbView, configuration in
            let frame = CGRect(origin: configuration.1, size: configuration.0)
            orbView.frame = frame
            orbView.layer.cornerRadius = min(frame.width, frame.height) * 0.5
        }
    }

    // MARK: - Animation

    func startAnimatingIfNeeded() {
        guard !isAnimating, !UIAccessibility.isReduceMotionEnabled else { return }
        isAnimating = true

        animate(
            view: orbViews[0],
            duration: 9.8,
            translation: CGPoint(x: 28, y: -34),
            scale: 1.10
        )
        animate(
            view: orbViews[1],
            duration: 11.6,
            translation: CGPoint(x: -22, y: 26),
            scale: 1.08
        )
        animate(
            view: orbViews[2],
            duration: 13.4,
            translation: CGPoint(x: 24, y: -18),
            scale: 1.14
        )
    }

    private func animate(view: UIView, duration: TimeInterval, translation: CGPoint, scale: CGFloat) {
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [.allowUserInteraction, .autoreverse, .curveEaseInOut, .repeat]
        ) {
            view.transform = CGAffineTransform(translationX: translation.x, y: translation.y)
                .scaledBy(x: scale, y: scale)
        }
    }
}
