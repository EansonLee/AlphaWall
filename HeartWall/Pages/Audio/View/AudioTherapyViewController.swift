//
//  AudioTherapyViewController.swift
//  HeartWall
//

import UIKit

final class AudioTherapyViewController: BaseViewController {

    private let catalog = AudioTherapyCatalogProvider().makeCatalog()
    private var selectedCategoryID: String?
    private var thumbnailTasks: [Task<Void, Never>] = []

    private let backgroundImageView = UIImageView()
    private let topDimView = UIView()
    private let bottomFadeView = UIView()
    private let bottomFadeLayer = CAGradientLayer()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let soundBadgeView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
    private let soundBadgeStackView = UIStackView()
    private let categoryScrollView = UIScrollView()
    private let categoryStackView = UIStackView()
    private let cardsGridView = UIStackView()
    private var categoryButtons: [UIButton] = []

    private var items: [AudioTherapyItem] {
        catalog.items
    }

    private var categories: [AudioTherapyCategory] {
        catalog.categories
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        thumbnailTasks.forEach { $0.cancel() }
        thumbnailTasks.removeAll()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bottomFadeLayer.frame = bottomFadeView.bounds
    }

    override func setupUI() {
        view.backgroundColor = UIColor(red: 0.07, green: 0.11, blue: 0.14, alpha: 1)
        selectedCategoryID = categories.first?.id
        configureBackground()
        configureHeader()
        configureContent()
        applyInitialBackground()
        renderCategories()
        renderCards()
    }

    private func configureBackground() {
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.backgroundColor = UIColor(red: 0.16, green: 0.29, blue: 0.35, alpha: 1)
        view.addSubview(backgroundImageView)
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false

        topDimView.backgroundColor = UIColor.black.withAlphaComponent(0.18)
        view.addSubview(topDimView)
        topDimView.translatesAutoresizingMaskIntoConstraints = false

        bottomFadeLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.60).cgColor,
            UIColor.black.withAlphaComponent(0.92).cgColor
        ]
        bottomFadeLayer.locations = [0, 0.48, 1]
        bottomFadeView.isUserInteractionEnabled = false
        bottomFadeView.layer.addSublayer(bottomFadeLayer)
        view.addSubview(bottomFadeView)
        bottomFadeView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            topDimView.topAnchor.constraint(equalTo: view.topAnchor),
            topDimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topDimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topDimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            bottomFadeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomFadeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomFadeView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomFadeView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.56)
        ])
    }

    private func configureHeader() {
        var backConfiguration = UIButton.Configuration.plain()
        backConfiguration.baseForegroundColor = UIColor.white.withAlphaComponent(0.94)
        backConfiguration.contentInsets = .zero
        backConfiguration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        backButton.configuration = backConfiguration
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        backButton.layer.cornerRadius = 28
        backButton.layer.cornerCurve = .continuous
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        view.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = "音疗专区"
        titleLabel.font = .systemFont(ofSize: 25, weight: .heavy)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        soundBadgeView.layer.cornerRadius = 18
        soundBadgeView.layer.cornerCurve = .continuous
        soundBadgeView.clipsToBounds = true
        soundBadgeView.alpha = 0.92

        let iconView = UIImageView(image: UIImage(systemName: "waveform"))
        iconView.tintColor = UIColor.white.withAlphaComponent(0.82)
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)

        let badgeLabel = UILabel()
        badgeLabel.text = "白噪音,水声,轻松"
        badgeLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        badgeLabel.textColor = UIColor.white.withAlphaComponent(0.82)

        soundBadgeStackView.axis = .horizontal
        soundBadgeStackView.alignment = .center
        soundBadgeStackView.spacing = 8
        soundBadgeStackView.addArrangedSubview(iconView)
        soundBadgeStackView.addArrangedSubview(badgeLabel)

        view.addSubview(soundBadgeView)
        soundBadgeView.contentView.addSubview(soundBadgeStackView)
        soundBadgeView.translatesAutoresizingMaskIntoConstraints = false
        soundBadgeStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            backButton.widthAnchor.constraint(equalToConstant: 56),
            backButton.heightAnchor.constraint(equalToConstant: 56),

            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -92),

            soundBadgeView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 28),
            soundBadgeView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            soundBadgeView.heightAnchor.constraint(equalToConstant: 48),
            soundBadgeView.widthAnchor.constraint(greaterThanOrEqualToConstant: 230),
            soundBadgeView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -80),

            soundBadgeStackView.centerXAnchor.constraint(equalTo: soundBadgeView.contentView.centerXAnchor),
            soundBadgeStackView.centerYAnchor.constraint(equalTo: soundBadgeView.contentView.centerYAnchor),
            soundBadgeStackView.leadingAnchor.constraint(greaterThanOrEqualTo: soundBadgeView.contentView.leadingAnchor, constant: 20),
            soundBadgeStackView.trailingAnchor.constraint(lessThanOrEqualTo: soundBadgeView.contentView.trailingAnchor, constant: -20)
        ])
    }

    private func configureContent() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        categoryScrollView.showsHorizontalScrollIndicator = false
        categoryScrollView.contentInsetAdjustmentBehavior = .never
        categoryStackView.axis = .horizontal
        categoryStackView.alignment = .center
        categoryStackView.spacing = 24
        categoryScrollView.addSubview(categoryStackView)
        categoryStackView.translatesAutoresizingMaskIntoConstraints = false

        cardsGridView.axis = .vertical
        cardsGridView.spacing = 16

        contentView.addSubview(categoryScrollView)
        contentView.addSubview(cardsGridView)
        categoryScrollView.translatesAutoresizingMaskIntoConstraints = false
        cardsGridView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -116),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor, constant: 260),

            categoryScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            categoryScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            categoryScrollView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 650),
            categoryScrollView.heightAnchor.constraint(equalToConstant: 58),

            categoryStackView.leadingAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.leadingAnchor, constant: 28),
            categoryStackView.trailingAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.trailingAnchor, constant: -28),
            categoryStackView.centerYAnchor.constraint(equalTo: categoryScrollView.frameLayoutGuide.centerYAnchor),
            categoryStackView.heightAnchor.constraint(equalTo: categoryScrollView.frameLayoutGuide.heightAnchor),

            cardsGridView.topAnchor.constraint(equalTo: categoryScrollView.bottomAnchor, constant: 18),
            cardsGridView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardsGridView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            cardsGridView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    private func applyInitialBackground() {
        guard let firstItem = catalog.defaultItem else { return }
        let task = Task { [weak self] in
            let image = await VideoThumbnailLoader.shared.loadThumbnail(for: firstItem.videoURL)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.backgroundImageView.image = image
            }
        }
        thumbnailTasks.append(task)
    }

    private func renderCategories() {
        categoryButtons.forEach { $0.removeFromSuperview() }
        categoryButtons = []

        categories.enumerated().forEach { index, category in
            let isSelected = category.id == selectedCategoryID
            let button = UIButton(type: .system)
            button.tag = index
            button.setTitle(category.title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 21, weight: isSelected ? .heavy : .medium)
            button.tintColor = .white
            button.addTarget(self, action: #selector(handleCategoryTap(_:)), for: .touchUpInside)
            button.heightAnchor.constraint(equalToConstant: 58).isActive = true

            let underline = UIView()
            underline.backgroundColor = UIColor(red: 0.33, green: 0.75, blue: 1.00, alpha: 1)
            underline.layer.cornerRadius = 2
            underline.layer.cornerCurve = .continuous
            underline.isUserInteractionEnabled = false
            underline.tag = 2001
            underline.isHidden = !isSelected
            button.addSubview(underline)
            underline.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                underline.centerXAnchor.constraint(equalTo: button.centerXAnchor),
                underline.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -2),
                underline.widthAnchor.constraint(equalToConstant: 34),
                underline.heightAnchor.constraint(equalToConstant: 4)
            ])

            categoryStackView.addArrangedSubview(button)
            categoryButtons.append(button)
        }
    }

    private func renderCards() {
        cardsGridView.arrangedSubviews.forEach { row in
            cardsGridView.removeArrangedSubview(row)
            row.removeFromSuperview()
        }

        let filtered = itemsForSelectedCategory()
        stride(from: 0, to: filtered.count, by: 2).forEach { start in
            let rowView = UIStackView()
            rowView.axis = .horizontal
            rowView.alignment = .fill
            rowView.distribution = .fillEqually
            rowView.spacing = 18
            rowView.heightAnchor.constraint(equalToConstant: 240).isActive = true

            [start, start + 1].forEach { index in
                if filtered.indices.contains(index) {
                    let cardView = AudioTherapyCardView(item: filtered[index])
                    cardView.addGestureRecognizer(AudioTherapyItemTapGestureRecognizer(item: filtered[index], target: self, action: #selector(handleItemTap(_:))))
                    rowView.addArrangedSubview(cardView)
                } else {
                    rowView.addArrangedSubview(UIView())
                }
            }

            cardsGridView.addArrangedSubview(rowView)
        }
    }

    private func itemsForSelectedCategory() -> [AudioTherapyItem] {
        guard let selectedCategoryID else { return items }
        let categoryItems = items.filter { $0.categoryID == selectedCategoryID }
        return categoryItems.isEmpty ? items : categoryItems
    }

    @objc
    private func handleCategoryTap(_ sender: UIButton) {
        guard let category = categories[safe: sender.tag] else { return }
        selectedCategoryID = category.id
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        renderCategories()
        renderCards()
    }

    @objc
    private func handleItemTap(_ sender: AudioTherapyItemTapGestureRecognizer) {
        let playerViewController = AudioTherapyPlayerViewController(items: items, selectedItem: sender.item)
        playerViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(playerViewController, animated: true)
    }

    @objc
    private func handleBack() {
        navigationController?.popViewController(animated: true)
    }
}

private final class AudioTherapyCardView: UIView {

    private let item: AudioTherapyItem
    private let imageView = VideoThumbnailImageView()
    private let playBadgeView = UIView()
    private let titleLabel = UILabel()
    private let countLabel = UILabel()

    init(item: AudioTherapyItem) {
        self.item = item
        super.init(frame: .zero)
        configure()
        apply(item: item)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        layer.cornerRadius = 8
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.13).cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.22
        layer.shadowRadius = 14
        layer.shadowOffset = CGSize(width: 0, height: 8)
        backgroundColor = item.accentColor.withAlphaComponent(0.90)
        isUserInteractionEnabled = true

        imageView.layer.cornerRadius = 52
        imageView.layer.cornerCurve = .continuous
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.white.withAlphaComponent(0.16).cgColor

        playBadgeView.backgroundColor = UIColor(red: 0.36, green: 0.35, blue: 0.44, alpha: 0.92)
        playBadgeView.layer.cornerRadius = 27
        playBadgeView.layer.cornerCurve = .continuous
        playBadgeView.layer.borderWidth = 6
        playBadgeView.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor

        let playIcon = UIImageView(image: UIImage(systemName: "play.fill"))
        playIcon.tintColor = .white
        playIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .bold)
        playBadgeView.addSubview(playIcon)
        playIcon.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 20, weight: .heavy)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.78

        countLabel.font = .systemFont(ofSize: 16, weight: .medium)
        countLabel.textColor = UIColor.white.withAlphaComponent(0.92)
        countLabel.textAlignment = .center

        addSubview(imageView)
        addSubview(playBadgeView)
        addSubview(titleLabel)
        addSubview(countLabel)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        playBadgeView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            imageView.widthAnchor.constraint(equalToConstant: 104),
            imageView.heightAnchor.constraint(equalToConstant: 104),

            playBadgeView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 19),
            playBadgeView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 7),
            playBadgeView.widthAnchor.constraint(equalToConstant: 54),
            playBadgeView.heightAnchor.constraint(equalToConstant: 54),

            playIcon.centerXAnchor.constraint(equalTo: playBadgeView.centerXAnchor, constant: 2),
            playIcon.centerYAnchor.constraint(equalTo: playBadgeView.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 26),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),

            countLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            countLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            countLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14)
        ])
    }

    private func apply(item: AudioTherapyItem) {
        imageView.configure(videoURL: item.videoURL)
        titleLabel.text = item.title
        countLabel.text = "\(item.listenerCount)人正在听"
        accessibilityLabel = "\(item.title)，\(item.listenerCount)人正在听"
    }
}

private final class AudioTherapyItemTapGestureRecognizer: UITapGestureRecognizer {
    let item: AudioTherapyItem

    init(item: AudioTherapyItem, target: AnyObject?, action: Selector?) {
        self.item = item
        super.init(target: target, action: action)
    }
}

private final class VideoThumbnailImageView: UIImageView {

    private var videoURL: URL?
    private var thumbnailTask: Task<Void, Never>?

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .scaleAspectFill
        clipsToBounds = true
        backgroundColor = UIColor.white.withAlphaComponent(0.08)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(videoURL: URL) {
        self.videoURL = videoURL
        image = nil
        thumbnailTask?.cancel()

        thumbnailTask = Task { [weak self] in
            let image = await VideoThumbnailLoader.shared.loadThumbnail(for: videoURL)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard self?.videoURL == videoURL else { return }
                self?.image = image
            }
        }
    }

    deinit {
        thumbnailTask?.cancel()
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
