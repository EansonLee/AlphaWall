//
//  FloatingHomeTabBar.swift
//  HeartWall
//

import UIKit

final class FloatingHomeTabBar: UIView {

    struct Item {
        let title: String
        let iconName: String
    }

    var onSelectionChanged: ((Int) -> Void)?

    private let dockBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let dockStackView = UIStackView()
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

    func configure(items: [Item], selectedIndex: Int) {
        items.enumerated().forEach { index, item in
            guard let button = buttons[safe: index] else { return }
            button.configure(title: item.title, iconName: item.iconName)
            button.tag = index
        }

        updateSelection(index: selectedIndex)
    }

    func updateSelection(index: Int) {
        buttons.enumerated().forEach { itemIndex, button in
            button.isSelected = itemIndex == index
        }
    }

    private func configure() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.18
        layer.shadowRadius = 26
        layer.shadowOffset = CGSize(width: 0, height: 14)

        dockBlurView.layer.cornerRadius = 28
        dockBlurView.layer.cornerCurve = .continuous
        dockBlurView.clipsToBounds = true
        dockBlurView.layer.borderWidth = 1
        dockBlurView.layer.borderColor = UIColor.white.withAlphaComponent(0.16).cgColor
        addSubview(dockBlurView)
        dockBlurView.translatesAutoresizingMaskIntoConstraints = false

        dockStackView.axis = .horizontal
        dockStackView.distribution = .fillEqually
        dockStackView.alignment = .fill
        dockStackView.spacing = 8
        dockBlurView.contentView.addSubview(dockStackView)
        dockStackView.translatesAutoresizingMaskIntoConstraints = false

        [audioButton, quoteButton, profileButton].enumerated().forEach { index, button in
            button.tag = index
            button.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)
            dockStackView.addArrangedSubview(button)
        }

        NSLayoutConstraint.activate([
            dockBlurView.topAnchor.constraint(equalTo: topAnchor),
            dockBlurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dockBlurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dockBlurView.bottomAnchor.constraint(equalTo: bottomAnchor),

            dockStackView.topAnchor.constraint(equalTo: dockBlurView.contentView.topAnchor, constant: 6),
            dockStackView.leadingAnchor.constraint(equalTo: dockBlurView.contentView.leadingAnchor, constant: 8),
            dockStackView.trailingAnchor.constraint(equalTo: dockBlurView.contentView.trailingAnchor, constant: -8),
            dockStackView.bottomAnchor.constraint(equalTo: dockBlurView.contentView.bottomAnchor, constant: -6)
        ])
    }

    @objc
    private func handleTap(_ sender: UIButton) {
        updateSelection(index: sender.tag)
        onSelectionChanged?(sender.tag)
    }
}

private final class FloatingHomeTabBarButton: UIButton {

    private let selectionBackgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
    private let iconImageView = UIImageView()
    private let titleLabelView = UILabel()
    private let contentStackView = UIStackView()

    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: CGRect.zero)
        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, iconName: String) {
        titleLabelView.text = title
        iconImageView.image = UIImage(systemName: iconName)
    }

    private func configure() {
        selectionBackgroundView.layer.cornerRadius = 22
        selectionBackgroundView.layer.cornerCurve = .continuous
        selectionBackgroundView.layer.borderWidth = 1
        selectionBackgroundView.layer.borderColor = UIColor.white.withAlphaComponent(0.14).cgColor
        selectionBackgroundView.isUserInteractionEnabled = false
        addSubview(selectionBackgroundView)
        selectionBackgroundView.translatesAutoresizingMaskIntoConstraints = false

        contentStackView.axis = .vertical
        contentStackView.alignment = .center
        contentStackView.spacing = 1
        contentStackView.isUserInteractionEnabled = false
        isExclusiveTouch = true
        addSubview(contentStackView)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        iconImageView.tintColor = UIColor.white.withAlphaComponent(0.78)
        iconImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: 17,
            weight: .semibold
        )
        contentStackView.addArrangedSubview(iconImageView)

        titleLabelView.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        titleLabelView.textColor = UIColor.white.withAlphaComponent(0.78)
        contentStackView.addArrangedSubview(titleLabelView)

        NSLayoutConstraint.activate([
            selectionBackgroundView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            selectionBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            selectionBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            selectionBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),

            contentStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentStackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),
            trailingAnchor.constraint(greaterThanOrEqualTo: contentStackView.trailingAnchor, constant: 8)
        ])

        updateAppearance()
    }

    private func updateAppearance() {
        let tintColor = isSelected
            ? UIColor.white
            : UIColor.white.withAlphaComponent(0.58)

        selectionBackgroundView.alpha = isSelected ? 1 : 0
        iconImageView.tintColor = tintColor
        titleLabelView.textColor = tintColor
        titleLabelView.font = UIFont.systemFont(ofSize: isSelected ? 10.5 : 10, weight: isSelected ? .bold : .medium)

        let targetTransform = isSelected ? CGAffineTransform(scaleX: 1.02, y: 1.02) : .identity
        guard !UIAccessibility.isReduceMotionEnabled else {
            transform = targetTransform
            return
        }

        UIView.animate(
            withDuration: 0.22,
            delay: 0,
            options: [.curveEaseOut, .beginFromCurrentState]
        ) {
            self.transform = targetTransform
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
