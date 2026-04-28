//
//  FloatingHomeTabBar.swift
//  HeartWall
//

import UIKit

final class FloatingHomeTabBar: UIView {

    struct Item {
        let title: String
        let iconName: String
        let selectedIconName: String?

        init(title: String, iconName: String, selectedIconName: String? = nil) {
            self.title = title
            self.iconName = iconName
            self.selectedIconName = selectedIconName
        }
    }

    var onSelectionChanged: ((Int) -> Void)?

    private let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let tintView = UIView()
    private let topSeparatorView = UIView()
    private let railGlowView = GradientView()
    private let selectionScanView = GradientView()
    private let stackView = UIStackView()
    private let audioButton = FloatingHomeTabBarButton()
    private let quoteButton = FloatingHomeTabBarButton()
    private let profileButton = FloatingHomeTabBarButton()
    private lazy var buttons: [FloatingHomeTabBarButton] = [audioButton, quoteButton, profileButton]
    private var selectionScanCenterXConstraint: NSLayoutConstraint?
    private var selectedIndex: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(items: [Item], selectedIndex: Int) {
        buttons.enumerated().forEach { index, button in
            guard let item = items[safe: index] else {
                button.isHidden = true
                return
            }

            button.isHidden = false
            button.configure(
                title: item.title,
                iconName: item.iconName,
                selectedIconName: item.selectedIconName,
                isPrimaryItem: index == 1
            )
            button.tag = index
        }

        updateSelection(index: selectedIndex, animated: false)
    }

    func updateSelection(index: Int) {
        updateSelection(index: index, animated: true)
    }

    private func configure() {
        backgroundColor = .clear

        backgroundView.clipsToBounds = true
        backgroundView.contentView.backgroundColor = UIColor.black.withAlphaComponent(0.52)
        addSubview(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false

        tintView.backgroundColor = UIColor(red: 0.05, green: 0.08, blue: 0.10, alpha: 0.34)
        tintView.isUserInteractionEnabled = false
        backgroundView.contentView.addSubview(tintView)
        tintView.translatesAutoresizingMaskIntoConstraints = false

        topSeparatorView.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        topSeparatorView.isUserInteractionEnabled = false
        backgroundView.contentView.addSubview(topSeparatorView)
        topSeparatorView.translatesAutoresizingMaskIntoConstraints = false

        railGlowView.configure(
            colors: [
                UIColor.clear,
                UIColor(red: 0.68, green: 0.91, blue: 1.00, alpha: 0.26),
                UIColor.white.withAlphaComponent(0.22),
                UIColor.clear
            ],
            locations: [0, 0.36, 0.58, 1],
            startPoint: CGPoint(x: 0, y: 0.5),
            endPoint: CGPoint(x: 1, y: 0.5)
        )
        railGlowView.alpha = 0.82
        railGlowView.isUserInteractionEnabled = false
        addSubview(railGlowView)
        railGlowView.translatesAutoresizingMaskIntoConstraints = false

        selectionScanView.configure(
            colors: [
                UIColor.clear,
                UIColor(red: 0.64, green: 0.89, blue: 1.00, alpha: 0.82),
                UIColor.white.withAlphaComponent(0.98),
                UIColor.clear
            ],
            locations: [0, 0.38, 0.58, 1],
            startPoint: CGPoint(x: 0, y: 0.5),
            endPoint: CGPoint(x: 1, y: 0.5)
        )
        selectionScanView.layer.shadowColor = UIColor(red: 0.68, green: 0.91, blue: 1.00, alpha: 1).cgColor
        selectionScanView.layer.shadowOpacity = 0.34
        selectionScanView.layer.shadowRadius = 8
        selectionScanView.layer.shadowOffset = .zero
        selectionScanView.isUserInteractionEnabled = false
        addSubview(selectionScanView)
        selectionScanView.translatesAutoresizingMaskIntoConstraints = false

        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 18
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        [audioButton, quoteButton, profileButton].enumerated().forEach { index, button in
            button.tag = index
            button.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),

            tintView.topAnchor.constraint(equalTo: backgroundView.contentView.topAnchor),
            tintView.leadingAnchor.constraint(equalTo: backgroundView.contentView.leadingAnchor),
            tintView.trailingAnchor.constraint(equalTo: backgroundView.contentView.trailingAnchor),
            tintView.bottomAnchor.constraint(equalTo: backgroundView.contentView.bottomAnchor),

            topSeparatorView.topAnchor.constraint(equalTo: backgroundView.contentView.topAnchor),
            topSeparatorView.leadingAnchor.constraint(equalTo: backgroundView.contentView.leadingAnchor),
            topSeparatorView.trailingAnchor.constraint(equalTo: backgroundView.contentView.trailingAnchor),
            topSeparatorView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),

            railGlowView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            railGlowView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            railGlowView.bottomAnchor.constraint(equalTo: stackView.topAnchor, constant: -3),
            railGlowView.heightAnchor.constraint(equalToConstant: 1.5),

            selectionScanView.bottomAnchor.constraint(equalTo: stackView.topAnchor, constant: -2),
            selectionScanView.widthAnchor.constraint(equalToConstant: 44),
            selectionScanView.heightAnchor.constraint(equalToConstant: 3),

            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22),
            stackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -3),
            stackView.heightAnchor.constraint(equalToConstant: 48),

            profileButton.widthAnchor.constraint(equalTo: audioButton.widthAnchor),
            quoteButton.widthAnchor.constraint(equalTo: audioButton.widthAnchor, multiplier: 1.58)
        ])

        updateSelection(index: selectedIndex, animated: false)
    }

    private func updateSelection(index: Int, animated: Bool) {
        guard let selectedButton = buttons[safe: index], !selectedButton.isHidden else { return }
        selectedIndex = index

        buttons.enumerated().forEach { itemIndex, button in
            button.isSelected = itemIndex == index
        }

        selectionScanCenterXConstraint?.isActive = false
        selectionScanCenterXConstraint = selectionScanView.centerXAnchor.constraint(equalTo: selectedButton.centerXAnchor)
        selectionScanCenterXConstraint?.isActive = true

        let targetTransform = CGAffineTransform(scaleX: index == 1 ? 1.28 : 0.82, y: 1)
        let updates = {
            self.layoutIfNeeded()
            self.selectionScanView.alpha = 1
            self.selectionScanView.transform = targetTransform
        }

        guard animated, !UIAccessibility.isReduceMotionEnabled else {
            updates()
            return
        }

        UIView.animate(
            withDuration: 0.24,
            delay: 0,
            options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction],
            animations: updates
        )
    }

    @objc
    private func handleTap(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.62)
        if let button = sender as? FloatingHomeTabBarButton {
            button.playActivationPulse()
        }
        updateSelection(index: sender.tag)
        onSelectionChanged?(sender.tag)
    }
}

private final class FloatingHomeTabBarButton: UIButton {

    private let moduleView = UIView()
    private let pulseView = UIView()
    private let contentStackView = UIStackView()
    private let iconImageView = UIImageView()
    private let titleLabelView = UILabel()
    private let statusDotView = UIView()
    private var iconName: String?
    private var selectedIconName: String?
    private var isPrimaryItem = false

    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }

    override var isHighlighted: Bool {
        didSet {
            updateAppearance()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        moduleView.layer.cornerRadius = moduleView.bounds.height * 0.5
        pulseView.layer.cornerRadius = pulseView.bounds.height * 0.5
        statusDotView.layer.cornerRadius = statusDotView.bounds.height * 0.5
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, iconName: String, selectedIconName: String?, isPrimaryItem: Bool) {
        self.iconName = iconName
        self.selectedIconName = selectedIconName
        self.isPrimaryItem = isPrimaryItem
        titleLabelView.text = title
        accessibilityLabel = title
        updateAppearance()
    }

    func playActivationPulse() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }

        pulseView.layer.removeAllAnimations()
        pulseView.alpha = 0.32
        pulseView.transform = .identity

        UIView.animate(
            withDuration: 0.34,
            delay: 0,
            options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction],
            animations: {
                self.pulseView.alpha = 0
                self.pulseView.transform = CGAffineTransform(scaleX: 1.46, y: 1.32)
            }
        )
    }

    private func configure() {
        backgroundColor = .clear
        isExclusiveTouch = true
        isAccessibilityElement = true

        moduleView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        moduleView.layer.cornerCurve = .continuous
        moduleView.layer.borderWidth = 1
        moduleView.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor
        moduleView.isUserInteractionEnabled = false
        addSubview(moduleView)
        moduleView.translatesAutoresizingMaskIntoConstraints = false

        pulseView.backgroundColor = UIColor(red: 0.68, green: 0.91, blue: 1.00, alpha: 0.16)
        pulseView.layer.borderWidth = 1
        pulseView.layer.borderColor = UIColor(red: 0.70, green: 0.92, blue: 1.00, alpha: 0.34).cgColor
        pulseView.alpha = 0
        pulseView.isUserInteractionEnabled = false
        insertSubview(pulseView, belowSubview: moduleView)
        pulseView.translatesAutoresizingMaskIntoConstraints = false

        contentStackView.axis = .vertical
        contentStackView.alignment = .center
        contentStackView.spacing = 3
        contentStackView.isUserInteractionEnabled = false
        addSubview(contentStackView)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 19, weight: .regular)
        contentStackView.addArrangedSubview(iconImageView)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        titleLabelView.font = UIFont.systemFont(ofSize: 10.5, weight: .medium)
        titleLabelView.textAlignment = .center
        titleLabelView.numberOfLines = 1
        titleLabelView.adjustsFontSizeToFitWidth = true
        titleLabelView.minimumScaleFactor = 0.78
        contentStackView.addArrangedSubview(titleLabelView)

        statusDotView.backgroundColor = UIColor.white.withAlphaComponent(0.88)
        statusDotView.layer.shadowColor = UIColor(red: 0.70, green: 0.92, blue: 1.00, alpha: 1).cgColor
        statusDotView.layer.shadowOpacity = 0.34
        statusDotView.layer.shadowRadius = 5
        statusDotView.layer.shadowOffset = .zero
        statusDotView.isUserInteractionEnabled = false
        addSubview(statusDotView)
        statusDotView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            moduleView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            moduleView.leadingAnchor.constraint(equalTo: leadingAnchor),
            moduleView.trailingAnchor.constraint(equalTo: trailingAnchor),
            moduleView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),

            pulseView.topAnchor.constraint(equalTo: moduleView.topAnchor),
            pulseView.leadingAnchor.constraint(equalTo: moduleView.leadingAnchor),
            pulseView.trailingAnchor.constraint(equalTo: moduleView.trailingAnchor),
            pulseView.bottomAnchor.constraint(equalTo: moduleView.bottomAnchor),

            contentStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStackView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 1),
            contentStackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 5),
            trailingAnchor.constraint(greaterThanOrEqualTo: contentStackView.trailingAnchor, constant: 5),

            iconImageView.widthAnchor.constraint(equalToConstant: 25),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),

            statusDotView.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusDotView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
            statusDotView.widthAnchor.constraint(equalToConstant: 4),
            statusDotView.heightAnchor.constraint(equalToConstant: 4)
        ])

        updateAppearance()
    }

    private func updateAppearance() {
        let selectedColor = UIColor.white.withAlphaComponent(0.98)
        let idleColor = UIColor.white.withAlphaComponent(isHighlighted ? 0.66 : 0.50)
        let targetColor = isSelected ? selectedColor : idleColor
        let titleAlpha: CGFloat
        if isSelected {
            titleAlpha = 1
        } else {
            titleAlpha = isPrimaryItem ? 0.66 : 0
        }

        let moduleAlpha: CGFloat
        if isSelected {
            moduleAlpha = isPrimaryItem ? 0.94 : 0.76
        } else {
            moduleAlpha = isPrimaryItem ? 0.26 : 0.06
        }

        let pressedScale: CGFloat = isHighlighted ? 0.94 : 1
        let selectedOffset: CGFloat = isSelected ? (isPrimaryItem ? -4 : -2) : 0
        let contentScale: CGFloat = isSelected ? (isPrimaryItem ? 1.05 : 1.0) : 0.98
        let moduleScaleX: CGFloat = isSelected ? 1 : (isPrimaryItem ? 0.92 : 0.74)
        let moduleScaleY: CGFloat = isSelected ? 1 : 0.82

        if let image = resolvedIconImage(selected: isSelected) {
            iconImageView.image = image
        }

        let applyChanges = {
            self.iconImageView.tintColor = targetColor
            self.titleLabelView.textColor = targetColor
            self.titleLabelView.alpha = titleAlpha
            self.moduleView.alpha = moduleAlpha
            self.moduleView.backgroundColor = self.isSelected
                ? UIColor(red: 0.08, green: 0.12, blue: 0.15, alpha: 0.82)
                : UIColor.white.withAlphaComponent(0.07)
            self.moduleView.layer.borderColor = self.isSelected
                ? UIColor(red: 0.70, green: 0.92, blue: 1.00, alpha: 0.24).cgColor
                : UIColor.white.withAlphaComponent(0.08).cgColor
            self.moduleView.transform = CGAffineTransform(scaleX: moduleScaleX, y: moduleScaleY)
            self.contentStackView.transform = CGAffineTransform(
                translationX: 0,
                y: selectedOffset
            ).scaledBy(x: pressedScale * contentScale, y: pressedScale * contentScale)
            self.statusDotView.alpha = self.isSelected ? 1 : 0
            self.statusDotView.transform = CGAffineTransform(scaleX: self.isPrimaryItem ? 1.22 : 0.9, y: 1)
            self.accessibilityTraits = self.isSelected ? [.button, .selected] : .button
            self.accessibilityValue = self.isSelected ? L10n.text("common.current") : nil
        }

        guard !UIAccessibility.isReduceMotionEnabled else {
            applyChanges()
            return
        }

        UIView.animate(
            withDuration: isHighlighted ? 0.12 : 0.23,
            delay: 0,
            options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction],
            animations: applyChanges
        )
    }

    private func resolvedIconImage(selected: Bool) -> UIImage? {
        let symbolName = selected ? selectedIconName ?? iconName : iconName
        guard let symbolName else { return nil }

        let configuration = UIImage.SymbolConfiguration(
            pointSize: selected ? (isPrimaryItem ? 21 : 20) : 19,
            weight: selected ? .semibold : .regular
        )

        return UIImage(systemName: symbolName, withConfiguration: configuration)
            ?? UIImage(systemName: iconName ?? symbolName, withConfiguration: configuration)
    }
}

private final class GradientView: UIView {

    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    func configure(
        colors: [UIColor],
        locations: [NSNumber]? = nil,
        startPoint: CGPoint,
        endPoint: CGPoint
    ) {
        guard let gradientLayer = layer as? CAGradientLayer else { return }
        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.locations = locations
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height * 0.5
        layer.cornerCurve = .continuous
        clipsToBounds = true
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
