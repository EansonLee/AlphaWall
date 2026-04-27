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

    private let dockBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
    private let dockTintView = GradientView()
    private let dockBottomShadeView = GradientView()
    private let dockTopSheenView = GradientView()
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

    override func layoutSubviews() {
        super.layoutSubviews()
        let cornerRadius = bounds.height * 0.5
        dockBlurView.layer.cornerRadius = cornerRadius
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
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
        layer.shadowOpacity = 0.24
        layer.shadowRadius = 30
        layer.shadowOffset = CGSize(width: 0, height: 18)

        dockBlurView.layer.cornerRadius = 32
        dockBlurView.layer.cornerCurve = .continuous
        dockBlurView.clipsToBounds = true
        dockBlurView.layer.borderWidth = 0.8
        dockBlurView.layer.borderColor = UIColor.white.withAlphaComponent(0.22).cgColor
        dockBlurView.contentView.backgroundColor = UIColor(red: 0.04, green: 0.05, blue: 0.07, alpha: 0.34)
        addSubview(dockBlurView)
        dockBlurView.translatesAutoresizingMaskIntoConstraints = false

        dockTintView.configure(
            colors: [
                UIColor.white.withAlphaComponent(0.16),
                UIColor(red: 1.00, green: 0.82, blue: 0.54, alpha: 0.10),
                UIColor(red: 0.42, green: 0.82, blue: 0.92, alpha: 0.08),
                UIColor.black.withAlphaComponent(0.18)
            ],
            locations: [0, 0.34, 0.72, 1],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1)
        )
        dockBottomShadeView.configure(
            colors: [
                UIColor.clear,
                UIColor.black.withAlphaComponent(0.26)
            ],
            locations: [0, 1],
            startPoint: CGPoint(x: 0.5, y: 0),
            endPoint: CGPoint(x: 0.5, y: 1)
        )
        dockTopSheenView.configure(
            colors: [
                UIColor.white.withAlphaComponent(0.46),
                UIColor.white.withAlphaComponent(0.16),
                UIColor.white.withAlphaComponent(0.02)
            ],
            locations: [0, 0.52, 1],
            startPoint: CGPoint(x: 0, y: 0.5),
            endPoint: CGPoint(x: 1, y: 0.5)
        )
        [dockTintView, dockBottomShadeView, dockTopSheenView].forEach {
            $0.isUserInteractionEnabled = false
            dockBlurView.contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        dockStackView.axis = .horizontal
        dockStackView.distribution = .fillEqually
        dockStackView.alignment = .fill
        dockStackView.spacing = 6
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

            dockTintView.topAnchor.constraint(equalTo: dockBlurView.contentView.topAnchor),
            dockTintView.leadingAnchor.constraint(equalTo: dockBlurView.contentView.leadingAnchor),
            dockTintView.trailingAnchor.constraint(equalTo: dockBlurView.contentView.trailingAnchor),
            dockTintView.bottomAnchor.constraint(equalTo: dockBlurView.contentView.bottomAnchor),

            dockBottomShadeView.leadingAnchor.constraint(equalTo: dockBlurView.contentView.leadingAnchor),
            dockBottomShadeView.trailingAnchor.constraint(equalTo: dockBlurView.contentView.trailingAnchor),
            dockBottomShadeView.bottomAnchor.constraint(equalTo: dockBlurView.contentView.bottomAnchor),
            dockBottomShadeView.heightAnchor.constraint(equalToConstant: 28),

            dockTopSheenView.topAnchor.constraint(equalTo: dockBlurView.contentView.topAnchor),
            dockTopSheenView.leadingAnchor.constraint(equalTo: dockBlurView.contentView.leadingAnchor, constant: 18),
            dockTopSheenView.trailingAnchor.constraint(equalTo: dockBlurView.contentView.trailingAnchor, constant: -18),
            dockTopSheenView.heightAnchor.constraint(equalToConstant: 1),

            dockStackView.topAnchor.constraint(equalTo: dockBlurView.contentView.topAnchor, constant: 7),
            dockStackView.leadingAnchor.constraint(equalTo: dockBlurView.contentView.leadingAnchor, constant: 8),
            dockStackView.trailingAnchor.constraint(equalTo: dockBlurView.contentView.trailingAnchor, constant: -8),
            dockStackView.bottomAnchor.constraint(equalTo: dockBlurView.contentView.bottomAnchor, constant: -7)
        ])
    }

    @objc
    private func handleTap(_ sender: UIButton) {
        updateSelection(index: sender.tag)
        onSelectionChanged?(sender.tag)
    }
}

private final class FloatingHomeTabBarButton: UIButton {

    private let selectionBackgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))
    private let selectionTintView = GradientView()
    private let selectionTopSheenView = GradientView()
    private let iconContainerView = UIView()
    private let iconHaloView = GradientView()
    private let iconImageView = UIImageView()
    private let titleLabelView = UILabel()
    private let contentStackView = UIStackView()

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
        super.init(frame: CGRect.zero)
        configure()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        selectionBackgroundView.layer.cornerRadius = selectionBackgroundView.bounds.height * 0.5
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, iconName: String) {
        titleLabelView.text = title
        iconImageView.image = UIImage(systemName: iconName)
        accessibilityLabel = title
    }

    private func configure() {
        selectionBackgroundView.layer.cornerRadius = 25
        selectionBackgroundView.layer.cornerCurve = .continuous
        selectionBackgroundView.layer.borderWidth = 1
        selectionBackgroundView.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor
        selectionBackgroundView.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        selectionBackgroundView.isUserInteractionEnabled = false
        addSubview(selectionBackgroundView)
        selectionBackgroundView.translatesAutoresizingMaskIntoConstraints = false

        selectionTintView.configure(
            colors: [
                UIColor.white.withAlphaComponent(0.20),
                UIColor(red: 1.00, green: 0.83, blue: 0.56, alpha: 0.16),
                UIColor(red: 0.50, green: 0.86, blue: 0.96, alpha: 0.12),
                UIColor.white.withAlphaComponent(0.07)
            ],
            locations: [0, 0.38, 0.74, 1],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1)
        )
        selectionTopSheenView.configure(
            colors: [
                UIColor.white.withAlphaComponent(0.56),
                UIColor.white.withAlphaComponent(0.16),
                UIColor.white.withAlphaComponent(0.01)
            ],
            locations: [0, 0.55, 1],
            startPoint: CGPoint(x: 0, y: 0.5),
            endPoint: CGPoint(x: 1, y: 0.5)
        )
        [selectionTintView, selectionTopSheenView].forEach {
            $0.isUserInteractionEnabled = false
            selectionBackgroundView.contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        contentStackView.axis = .vertical
        contentStackView.alignment = .center
        contentStackView.spacing = 2
        contentStackView.isUserInteractionEnabled = false
        isExclusiveTouch = true
        isAccessibilityElement = true
        addSubview(contentStackView)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        iconContainerView.isUserInteractionEnabled = false
        contentStackView.addArrangedSubview(iconContainerView)
        iconContainerView.translatesAutoresizingMaskIntoConstraints = false

        iconHaloView.configure(
            colors: [
                UIColor.white.withAlphaComponent(0.28),
                UIColor(red: 1.00, green: 0.78, blue: 0.46, alpha: 0.16),
                UIColor.clear
            ],
            locations: [0, 0.58, 1],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1)
        )
        iconHaloView.isUserInteractionEnabled = false
        iconContainerView.addSubview(iconHaloView)
        iconHaloView.translatesAutoresizingMaskIntoConstraints = false

        iconImageView.tintColor = UIColor.white.withAlphaComponent(0.78)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: 17,
            weight: .semibold
        )
        iconContainerView.addSubview(iconImageView)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        titleLabelView.font = UIFont.systemFont(ofSize: 10.5, weight: .medium)
        titleLabelView.textColor = UIColor.white.withAlphaComponent(0.78)
        titleLabelView.numberOfLines = 1
        titleLabelView.adjustsFontSizeToFitWidth = true
        titleLabelView.minimumScaleFactor = 0.82
        contentStackView.addArrangedSubview(titleLabelView)

        NSLayoutConstraint.activate([
            selectionBackgroundView.topAnchor.constraint(equalTo: topAnchor, constant: 3),
            selectionBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            selectionBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            selectionBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3),

            selectionTintView.topAnchor.constraint(equalTo: selectionBackgroundView.contentView.topAnchor),
            selectionTintView.leadingAnchor.constraint(equalTo: selectionBackgroundView.contentView.leadingAnchor),
            selectionTintView.trailingAnchor.constraint(equalTo: selectionBackgroundView.contentView.trailingAnchor),
            selectionTintView.bottomAnchor.constraint(equalTo: selectionBackgroundView.contentView.bottomAnchor),

            selectionTopSheenView.topAnchor.constraint(equalTo: selectionBackgroundView.contentView.topAnchor, constant: 1),
            selectionTopSheenView.leadingAnchor.constraint(equalTo: selectionBackgroundView.contentView.leadingAnchor, constant: 14),
            selectionTopSheenView.trailingAnchor.constraint(equalTo: selectionBackgroundView.contentView.trailingAnchor, constant: -14),
            selectionTopSheenView.heightAnchor.constraint(equalToConstant: 1),

            contentStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentStackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),
            trailingAnchor.constraint(greaterThanOrEqualTo: contentStackView.trailingAnchor, constant: 8),

            iconContainerView.widthAnchor.constraint(equalToConstant: 34),
            iconContainerView.heightAnchor.constraint(equalToConstant: 24),

            iconHaloView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconHaloView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            iconHaloView.widthAnchor.constraint(equalToConstant: 31),
            iconHaloView.heightAnchor.constraint(equalToConstant: 21),

            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 22)
        ])

        updateAppearance()
    }

    private func updateAppearance() {
        let tintColor = isSelected
            ? UIColor.white
            : UIColor.white.withAlphaComponent(0.58)
        let selectedScale: CGFloat = isSelected ? 1.018 : 1
        let pressedScale: CGFloat = isHighlighted ? 0.965 : 1
        let targetTransform = CGAffineTransform(scaleX: selectedScale * pressedScale, y: selectedScale * pressedScale)

        let applyChanges = {
            self.selectionBackgroundView.alpha = self.isSelected ? 1 : 0
            self.iconHaloView.alpha = self.isSelected ? 1 : 0
            self.iconImageView.tintColor = tintColor
            self.iconImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
                pointSize: self.isSelected ? 18 : 17,
                weight: self.isSelected ? .bold : .semibold
            )
            self.titleLabelView.textColor = tintColor
            self.titleLabelView.font = UIFont.systemFont(
                ofSize: self.isSelected ? 11 : 10.5,
                weight: self.isSelected ? .semibold : .medium
            )
            self.titleLabelView.alpha = self.isSelected ? 0.98 : 0.70
            self.transform = targetTransform
            self.accessibilityTraits = self.isSelected ? [.button, .selected] : .button
            self.accessibilityValue = self.isSelected ? "当前" : nil
        }

        guard !UIAccessibility.isReduceMotionEnabled else {
            applyChanges()
            return
        }

        UIView.animate(
            withDuration: 0.24,
            delay: 0,
            options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction],
            animations: applyChanges
        )
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
