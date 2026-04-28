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
    private let selectionIndicatorView = UIView()
    private let stackView = UIStackView()
    private let audioButton = FloatingHomeTabBarButton()
    private let quoteButton = FloatingHomeTabBarButton()
    private let profileButton = FloatingHomeTabBarButton()
    private lazy var buttons: [FloatingHomeTabBarButton] = [audioButton, quoteButton, profileButton]
    private var selectionIndicatorCenterXConstraint: NSLayoutConstraint?
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
            button.configure(title: item.title, iconName: item.iconName, selectedIconName: item.selectedIconName)
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
        backgroundView.contentView.backgroundColor = UIColor.black.withAlphaComponent(0.48)
        addSubview(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false

        tintView.backgroundColor = UIColor(white: 1, alpha: 0.025)
        tintView.isUserInteractionEnabled = false
        backgroundView.contentView.addSubview(tintView)
        tintView.translatesAutoresizingMaskIntoConstraints = false

        topSeparatorView.backgroundColor = UIColor.white.withAlphaComponent(0.11)
        topSeparatorView.isUserInteractionEnabled = false
        backgroundView.contentView.addSubview(topSeparatorView)
        topSeparatorView.translatesAutoresizingMaskIntoConstraints = false

        selectionIndicatorView.backgroundColor = UIColor.white.withAlphaComponent(0.94)
        selectionIndicatorView.layer.cornerRadius = 1.25
        selectionIndicatorView.layer.cornerCurve = .continuous
        selectionIndicatorView.layer.shadowColor = UIColor.white.cgColor
        selectionIndicatorView.layer.shadowOpacity = 0.32
        selectionIndicatorView.layer.shadowRadius = 6
        selectionIndicatorView.layer.shadowOffset = .zero
        selectionIndicatorView.isUserInteractionEnabled = false
        addSubview(selectionIndicatorView)
        selectionIndicatorView.translatesAutoresizingMaskIntoConstraints = false

        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = 0
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

            selectionIndicatorView.topAnchor.constraint(equalTo: topAnchor, constant: 1),
            selectionIndicatorView.widthAnchor.constraint(equalToConstant: 24),
            selectionIndicatorView.heightAnchor.constraint(equalToConstant: 2.5),

            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 7),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            stackView.heightAnchor.constraint(equalToConstant: 48)
        ])

        updateSelection(index: selectedIndex, animated: false)
    }

    private func updateSelection(index: Int, animated: Bool) {
        guard let selectedButton = buttons[safe: index], !selectedButton.isHidden else { return }
        selectedIndex = index

        buttons.enumerated().forEach { itemIndex, button in
            button.isSelected = itemIndex == index
        }

        selectionIndicatorCenterXConstraint?.isActive = false
        selectionIndicatorCenterXConstraint = selectionIndicatorView.centerXAnchor.constraint(equalTo: selectedButton.centerXAnchor)
        selectionIndicatorCenterXConstraint?.isActive = true

        let updates = {
            self.layoutIfNeeded()
            self.selectionIndicatorView.alpha = 1
        }

        guard animated, !UIAccessibility.isReduceMotionEnabled else {
            updates()
            return
        }

        UIView.animate(
            withDuration: 0.22,
            delay: 0,
            options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction],
            animations: updates
        )
    }

    @objc
    private func handleTap(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.55)
        updateSelection(index: sender.tag)
        onSelectionChanged?(sender.tag)
    }
}

private final class FloatingHomeTabBarButton: UIButton {

    private let contentStackView = UIStackView()
    private let iconImageView = UIImageView()
    private let titleLabelView = UILabel()
    private var iconName: String?
    private var selectedIconName: String?

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

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, iconName: String, selectedIconName: String?) {
        self.iconName = iconName
        self.selectedIconName = selectedIconName
        titleLabelView.text = title
        accessibilityLabel = title
        updateAppearance()
    }

    private func configure() {
        backgroundColor = .clear
        isExclusiveTouch = true
        isAccessibilityElement = true

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
        titleLabelView.minimumScaleFactor = 0.82
        contentStackView.addArrangedSubview(titleLabelView)

        NSLayoutConstraint.activate([
            contentStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStackView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 1),
            contentStackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4),
            trailingAnchor.constraint(greaterThanOrEqualTo: contentStackView.trailingAnchor, constant: 4),

            iconImageView.widthAnchor.constraint(equalToConstant: 25),
            iconImageView.heightAnchor.constraint(equalToConstant: 24)
        ])

        updateAppearance()
    }

    private func updateAppearance() {
        let targetColor = isSelected
            ? UIColor.white.withAlphaComponent(0.96)
            : UIColor.white.withAlphaComponent(isHighlighted ? 0.62 : 0.48)
        let targetAlpha: CGFloat = isSelected ? 1 : 0.72
        let pressedScale: CGFloat = isHighlighted ? 0.93 : 1
        let selectedOffset: CGFloat = isSelected ? -1 : 0

        if let image = resolvedIconImage(selected: isSelected) {
            iconImageView.image = image
        }

        let applyChanges = {
            self.iconImageView.tintColor = targetColor
            self.titleLabelView.textColor = targetColor
            self.titleLabelView.alpha = targetAlpha
            self.contentStackView.transform = CGAffineTransform(
                translationX: 0,
                y: selectedOffset
            ).scaledBy(x: pressedScale, y: pressedScale)
            self.accessibilityTraits = self.isSelected ? [.button, .selected] : .button
            self.accessibilityValue = self.isSelected ? L10n.text("common.current") : nil
        }

        guard !UIAccessibility.isReduceMotionEnabled else {
            applyChanges()
            return
        }

        UIView.animate(
            withDuration: isHighlighted ? 0.12 : 0.2,
            delay: 0,
            options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction],
            animations: applyChanges
        )
    }

    private func resolvedIconImage(selected: Bool) -> UIImage? {
        let symbolName = selected ? selectedIconName ?? iconName : iconName
        guard let symbolName else { return nil }

        let configuration = UIImage.SymbolConfiguration(
            pointSize: selected ? 20 : 19,
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
