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

    private let capsuleBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
    private let capsuleStackView = UIStackView()
    private let audioButton = FloatingHomeTabBarButton(style: .orb)
    private let quoteButton = FloatingHomeTabBarButton(style: .capsule)
    private let profileButton = FloatingHomeTabBarButton(style: .capsule)
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
        layer.shadowOpacity = 0.10
        layer.shadowRadius = 18
        layer.shadowOffset = CGSize(width: 0, height: 10)

        capsuleBlurView.layer.cornerRadius = 21
        capsuleBlurView.layer.cornerCurve = .continuous
        capsuleBlurView.clipsToBounds = true
        capsuleBlurView.layer.borderWidth = 1
        capsuleBlurView.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor
        addSubview(capsuleBlurView)
        addSubview(audioButton)
        capsuleBlurView.translatesAutoresizingMaskIntoConstraints = false
        audioButton.translatesAutoresizingMaskIntoConstraints = false

        capsuleStackView.axis = .horizontal
        capsuleStackView.distribution = .fillEqually
        capsuleStackView.spacing = 4
        capsuleBlurView.contentView.addSubview(capsuleStackView)
        capsuleStackView.translatesAutoresizingMaskIntoConstraints = false

        [audioButton, quoteButton, profileButton].enumerated().forEach { index, button in
            button.tag = index
            button.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)
        }

        capsuleStackView.addArrangedSubview(quoteButton)
        capsuleStackView.addArrangedSubview(profileButton)

        NSLayoutConstraint.activate([
            capsuleBlurView.widthAnchor.constraint(equalToConstant: 136),
            capsuleBlurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            capsuleBlurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            capsuleBlurView.heightAnchor.constraint(equalToConstant: 46),

            audioButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            audioButton.trailingAnchor.constraint(lessThanOrEqualTo: capsuleBlurView.leadingAnchor, constant: -24),
            audioButton.centerYAnchor.constraint(equalTo: capsuleBlurView.centerYAnchor),
            audioButton.widthAnchor.constraint(equalToConstant: 46),
            audioButton.heightAnchor.constraint(equalToConstant: 46),

            capsuleStackView.topAnchor.constraint(equalTo: capsuleBlurView.contentView.topAnchor, constant: 4),
            capsuleStackView.leadingAnchor.constraint(equalTo: capsuleBlurView.contentView.leadingAnchor, constant: 6),
            capsuleStackView.trailingAnchor.constraint(equalTo: capsuleBlurView.contentView.trailingAnchor, constant: -6),
            capsuleStackView.bottomAnchor.constraint(equalTo: capsuleBlurView.contentView.bottomAnchor, constant: -4)
        ])
    }

    @objc
    private func handleTap(_ sender: UIButton) {
        updateSelection(index: sender.tag)
        onSelectionChanged?(sender.tag)
    }
}

private final class FloatingHomeTabBarButton: UIButton {

    enum Style {
        case orb
        case capsule
    }

    private let style: Style

    private let selectionBackgroundView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabelView = UILabel()
    private let contentStackView = UIStackView()

    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }

    init(style: Style) {
        self.style = style
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
        selectionBackgroundView.layer.cornerRadius = style == .orb ? 23 : 17
        selectionBackgroundView.layer.cornerCurve = .continuous
        selectionBackgroundView.backgroundColor = style == .orb
            ? UIColor.white.withAlphaComponent(0.12)
            : UIColor.white.withAlphaComponent(0.14)
        addSubview(selectionBackgroundView)
        selectionBackgroundView.translatesAutoresizingMaskIntoConstraints = false

        contentStackView.axis = .vertical
        contentStackView.alignment = .center
        contentStackView.spacing = 1
        isExclusiveTouch = true
        addSubview(contentStackView)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        iconImageView.tintColor = UIColor.white.withAlphaComponent(0.78)
        iconImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: 16,
            weight: .semibold
        )
        contentStackView.addArrangedSubview(iconImageView)

        titleLabelView.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        titleLabelView.textColor = UIColor.white.withAlphaComponent(0.78)
        contentStackView.addArrangedSubview(titleLabelView)

        NSLayoutConstraint.activate([
            selectionBackgroundView.topAnchor.constraint(equalTo: topAnchor),
            selectionBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            selectionBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            selectionBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        updateAppearance()
    }

    private func updateAppearance() {
        let alpha: CGFloat = isSelected ? 1 : 0
        selectionBackgroundView.alpha = alpha

        let tintColor = isSelected ? UIColor.white : UIColor.white.withAlphaComponent(0.74)
        iconImageView.tintColor = tintColor
        titleLabelView.textColor = tintColor
        if style == .orb {
            selectionBackgroundView.backgroundColor = isSelected
                ? UIColor.white.withAlphaComponent(0.18)
                : UIColor.white.withAlphaComponent(0.08)
            selectionBackgroundView.alpha = 1
        } else {
            selectionBackgroundView.backgroundColor = UIColor.white.withAlphaComponent(isSelected ? 0.18 : 0.10)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
