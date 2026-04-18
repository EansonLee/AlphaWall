//
//  PremiumAppIconView.swift
//  HeartWall
//

import UIKit

final class PremiumAppIconView: UIView {

    // MARK: - Properties

    private let sideLength: CGFloat

    // MARK: - UI

    private let baseView = UIView()
    private let symbolImageView = UIImageView()
    private let accentBadge = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialLight))
    private let accentImageView = UIImageView()
    private let highlightView = UIView()
    private let gradientLayer = CAGradientLayer()

    // MARK: - Lifecycle

    init(sideLength: CGFloat) {
        self.sideLength = sideLength
        super.init(frame: .zero)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: sideLength, height: sideLength)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = baseView.bounds
    }

    // MARK: - Setup

    private func configure() {
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(baseView)
        baseView.translatesAutoresizingMaskIntoConstraints = false
        baseView.layer.cornerRadius = sideLength * 0.28
        baseView.layer.cornerCurve = .continuous
        baseView.layer.borderWidth = 1
        baseView.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
        baseView.layer.shadowColor = UIColor.black.cgColor
        baseView.layer.shadowOpacity = 0.20
        baseView.layer.shadowRadius = 22
        baseView.layer.shadowOffset = CGSize(width: 0, height: 12)
        baseView.layer.insertSublayer(gradientLayer, at: 0)

        gradientLayer.colors = [
            UIColor(red: 0.31, green: 0.92, blue: 0.84, alpha: 1).cgColor,
            UIColor(red: 0.41, green: 0.65, blue: 0.98, alpha: 1).cgColor,
            UIColor(red: 0.98, green: 0.82, blue: 0.66, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)

        highlightView.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        highlightView.layer.cornerRadius = sideLength * 0.18
        highlightView.layer.cornerCurve = .continuous
        baseView.addSubview(highlightView)
        highlightView.translatesAutoresizingMaskIntoConstraints = false

        symbolImageView.image = UIImage(systemName: "play.rectangle.fill")
        symbolImageView.tintColor = UIColor.white.withAlphaComponent(0.96)
        symbolImageView.contentMode = .scaleAspectFit
        symbolImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: sideLength * 0.38, weight: .medium)
        baseView.addSubview(symbolImageView)
        symbolImageView.translatesAutoresizingMaskIntoConstraints = false

        accentBadge.layer.cornerRadius = sideLength * 0.15
        accentBadge.layer.cornerCurve = .continuous
        accentBadge.layer.borderWidth = 1
        accentBadge.layer.borderColor = UIColor.white.withAlphaComponent(0.22).cgColor
        accentBadge.clipsToBounds = true
        baseView.addSubview(accentBadge)
        accentBadge.translatesAutoresizingMaskIntoConstraints = false

        accentImageView.image = UIImage(systemName: "heart.fill")
        accentImageView.tintColor = UIColor(red: 1, green: 0.53, blue: 0.58, alpha: 1)
        accentImageView.contentMode = .scaleAspectFit
        accentImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: sideLength * 0.16, weight: .semibold)
        accentBadge.contentView.addSubview(accentImageView)
        accentImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            baseView.topAnchor.constraint(equalTo: topAnchor),
            baseView.leadingAnchor.constraint(equalTo: leadingAnchor),
            baseView.trailingAnchor.constraint(equalTo: trailingAnchor),
            baseView.bottomAnchor.constraint(equalTo: bottomAnchor),

            highlightView.topAnchor.constraint(equalTo: baseView.topAnchor, constant: sideLength * 0.12),
            highlightView.leadingAnchor.constraint(equalTo: baseView.leadingAnchor, constant: sideLength * 0.14),
            highlightView.widthAnchor.constraint(equalToConstant: sideLength * 0.46),
            highlightView.heightAnchor.constraint(equalToConstant: sideLength * 0.22),

            symbolImageView.centerXAnchor.constraint(equalTo: baseView.centerXAnchor),
            symbolImageView.centerYAnchor.constraint(equalTo: baseView.centerYAnchor, constant: sideLength * 0.02),

            accentBadge.widthAnchor.constraint(equalToConstant: sideLength * 0.30),
            accentBadge.heightAnchor.constraint(equalTo: accentBadge.widthAnchor),
            accentBadge.trailingAnchor.constraint(equalTo: baseView.trailingAnchor, constant: -sideLength * 0.08),
            accentBadge.bottomAnchor.constraint(equalTo: baseView.bottomAnchor, constant: -sideLength * 0.08),

            accentImageView.centerXAnchor.constraint(equalTo: accentBadge.contentView.centerXAnchor),
            accentImageView.centerYAnchor.constraint(equalTo: accentBadge.contentView.centerYAnchor)
        ])
    }
}
