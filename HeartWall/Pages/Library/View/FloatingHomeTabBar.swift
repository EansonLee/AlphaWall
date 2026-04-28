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

    private let stackView = UIStackView()
    private let audioButton = FloatingHomeTabBarButton()
    private let quoteButton = FloatingHomeTabBarButton()
    private let profileButton = FloatingHomeTabBarButton()
    private lazy var buttons: [FloatingHomeTabBarButton] = [audioButton, quoteButton, profileButton]

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        buttons.contains { button in
            guard !button.isHidden, button.alpha > 0.01 else { return false }
            let buttonPoint = convert(point, to: button)
            return button.point(inside: buttonPoint, with: event)
        }
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

        updateSelection(index: selectedIndex)
    }

    func updateSelection(index: Int) {
        guard buttons.indices.contains(index) else { return }
        buttons.enumerated().forEach { itemIndex, button in
            button.isSelected = itemIndex == index
        }
    }

    private func configure() {
        backgroundColor = .clear

        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.spacing = 16
        stackView.isUserInteractionEnabled = true
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        [audioButton, quoteButton, profileButton].enumerated().forEach { index, button in
            button.tag = index
            button.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -8),
            stackView.heightAnchor.constraint(equalToConstant: 54),

            audioButton.widthAnchor.constraint(equalToConstant: 68),
            audioButton.heightAnchor.constraint(equalToConstant: 54),
            quoteButton.widthAnchor.constraint(equalToConstant: 112),
            quoteButton.heightAnchor.constraint(equalToConstant: 54),
            profileButton.widthAnchor.constraint(equalToConstant: 68),
            profileButton.heightAnchor.constraint(equalToConstant: 54)
        ])
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

    private let pulseView = UIView()
    private let capsuleView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
    private let capsuleTintView = UIView()
    private let activeLineView = UIView()
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
        let capsuleRadius = capsuleView.bounds.height * 0.5
        capsuleView.layer.cornerRadius = capsuleRadius
        pulseView.layer.cornerRadius = pulseView.bounds.height * 0.5
        activeLineView.layer.cornerRadius = activeLineView.bounds.height * 0.5
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
        pulseView.alpha = 0.34
        pulseView.transform = .identity

        UIView.animate(
            withDuration: 0.34,
            delay: 0,
            options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction],
            animations: {
                self.pulseView.alpha = 0
                self.pulseView.transform = CGAffineTransform(scaleX: 1.44, y: 1.30)
            }
        )
    }

    private func configure() {
        backgroundColor = .clear
        clipsToBounds = false
        isExclusiveTouch = true
        isAccessibilityElement = true

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.28
        layer.shadowRadius = 18
        layer.shadowOffset = CGSize(width: 0, height: 10)

        pulseView.backgroundColor = UIColor(red: 0.68, green: 0.91, blue: 1.00, alpha: 0.16)
        pulseView.layer.borderWidth = 1
        pulseView.layer.borderColor = UIColor(red: 0.70, green: 0.92, blue: 1.00, alpha: 0.32).cgColor
        pulseView.alpha = 0
        pulseView.isUserInteractionEnabled = false
        addSubview(pulseView)
        pulseView.translatesAutoresizingMaskIntoConstraints = false

        capsuleView.clipsToBounds = true
        capsuleView.layer.cornerCurve = .continuous
        capsuleView.layer.borderWidth = 1
        capsuleView.layer.borderColor = UIColor.white.withAlphaComponent(0.13).cgColor
        capsuleView.isUserInteractionEnabled = false
        addSubview(capsuleView)
        capsuleView.translatesAutoresizingMaskIntoConstraints = false

        capsuleTintView.backgroundColor = UIColor(red: 0.05, green: 0.08, blue: 0.10, alpha: 0.44)
        capsuleTintView.isUserInteractionEnabled = false
        capsuleView.contentView.addSubview(capsuleTintView)
        capsuleTintView.translatesAutoresizingMaskIntoConstraints = false

        activeLineView.backgroundColor = UIColor(red: 0.70, green: 0.92, blue: 1.00, alpha: 0.94)
        activeLineView.layer.shadowColor = UIColor(red: 0.70, green: 0.92, blue: 1.00, alpha: 1).cgColor
        activeLineView.layer.shadowOpacity = 0.45
        activeLineView.layer.shadowRadius = 6
        activeLineView.layer.shadowOffset = .zero
        activeLineView.isUserInteractionEnabled = false
        addSubview(activeLineView)
        activeLineView.translatesAutoresizingMaskIntoConstraints = false

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

        statusDotView.backgroundColor = UIColor.white.withAlphaComponent(0.92)
        statusDotView.layer.shadowColor = UIColor(red: 0.70, green: 0.92, blue: 1.00, alpha: 1).cgColor
        statusDotView.layer.shadowOpacity = 0.38
        statusDotView.layer.shadowRadius = 5
        statusDotView.layer.shadowOffset = .zero
        statusDotView.isUserInteractionEnabled = false
        addSubview(statusDotView)
        statusDotView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            pulseView.topAnchor.constraint(equalTo: capsuleView.topAnchor),
            pulseView.leadingAnchor.constraint(equalTo: capsuleView.leadingAnchor),
            pulseView.trailingAnchor.constraint(equalTo: capsuleView.trailingAnchor),
            pulseView.bottomAnchor.constraint(equalTo: capsuleView.bottomAnchor),

            capsuleView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            capsuleView.leadingAnchor.constraint(equalTo: leadingAnchor),
            capsuleView.trailingAnchor.constraint(equalTo: trailingAnchor),
            capsuleView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),

            capsuleTintView.topAnchor.constraint(equalTo: capsuleView.contentView.topAnchor),
            capsuleTintView.leadingAnchor.constraint(equalTo: capsuleView.contentView.leadingAnchor),
            capsuleTintView.trailingAnchor.constraint(equalTo: capsuleView.contentView.trailingAnchor),
            capsuleTintView.bottomAnchor.constraint(equalTo: capsuleView.contentView.bottomAnchor),

            activeLineView.topAnchor.constraint(equalTo: capsuleView.topAnchor, constant: 4),
            activeLineView.centerXAnchor.constraint(equalTo: centerXAnchor),
            activeLineView.widthAnchor.constraint(equalToConstant: 22),
            activeLineView.heightAnchor.constraint(equalToConstant: 2),

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
        let idleColor = UIColor.white.withAlphaComponent(isHighlighted ? 0.72 : 0.58)
        let targetColor = isSelected ? selectedColor : idleColor
        let titleAlpha: CGFloat
        if isSelected {
            titleAlpha = 1
        } else {
            titleAlpha = isPrimaryItem ? 0.74 : 0
        }

        let capsuleAlpha: CGFloat
        if isSelected {
            capsuleAlpha = isPrimaryItem ? 0.96 : 0.88
        } else {
            capsuleAlpha = isPrimaryItem ? 0.58 : 0.50
        }

        let pressedScale: CGFloat = isHighlighted ? 0.94 : 1
        let selectedOffset: CGFloat = isSelected ? (isPrimaryItem ? -3 : -2) : 0
        let contentScale: CGFloat = isSelected ? (isPrimaryItem ? 1.05 : 1.0) : 0.98
        let capsuleScale: CGFloat = isSelected ? 1 : 0.94

        if let image = resolvedIconImage(selected: isSelected) {
            iconImageView.image = image
        }

        let applyChanges = {
            self.iconImageView.tintColor = targetColor
            self.titleLabelView.textColor = targetColor
            self.titleLabelView.alpha = titleAlpha
            self.capsuleView.alpha = capsuleAlpha
            self.capsuleTintView.backgroundColor = self.isSelected
                ? UIColor(red: 0.07, green: 0.11, blue: 0.14, alpha: 0.58)
                : UIColor(red: 0.05, green: 0.08, blue: 0.10, alpha: 0.42)
            self.capsuleView.layer.borderColor = self.isSelected
                ? UIColor(red: 0.70, green: 0.92, blue: 1.00, alpha: 0.28).cgColor
                : UIColor.white.withAlphaComponent(0.13).cgColor
            self.capsuleView.transform = CGAffineTransform(scaleX: capsuleScale, y: capsuleScale)
            self.activeLineView.alpha = self.isSelected ? 1 : 0
            self.activeLineView.transform = CGAffineTransform(scaleX: self.isPrimaryItem ? 1.55 : 0.9, y: 1)
            self.contentStackView.transform = CGAffineTransform(
                translationX: 0,
                y: selectedOffset
            ).scaledBy(x: pressedScale * contentScale, y: pressedScale * contentScale)
            self.statusDotView.alpha = self.isSelected ? 1 : 0
            self.statusDotView.transform = CGAffineTransform(scaleX: self.isPrimaryItem ? 1.25 : 0.9, y: 1)
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

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
