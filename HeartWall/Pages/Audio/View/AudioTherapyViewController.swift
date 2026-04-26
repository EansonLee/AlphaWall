//
//  AudioTherapyViewController.swift
//  HeartWall
//

import UIKit
import AVFoundation
import Combine

final class AudioTherapyViewController: BaseViewController {

    private let catalog = AudioTherapyCatalogProvider().makeCatalog()
    private var selectedCategoryID: String?
    private var currentItem: AudioTherapyItem?
    private var thumbnailTasks: [Task<Void, Never>] = []
    private var idleCacheTask: Task<Void, Never>?
    private var initialThumbnailTimeoutTask: Task<Void, Never>?
    private var pendingInitialThumbnailURLs = Set<URL>()
    private var hasInitialThumbnailDisplaySettled = false
    private var isDetailPresentationActive = false
    private var isPrimaryScrollInteracting = false

    private let idleCacheStartDelay: Duration = .seconds(3)
    private let idleCacheResumeDelay: Duration = .seconds(2)
    private let initialThumbnailTimeout: Duration = .seconds(6)

    private let backgroundImageView = UIImageView()
    private let backgroundVideoView = LoopingVideoView()
    private let topDimView = UIView()
    private let bottomFadeView = UIView()
    private let bottomFadeLayer = CAGradientLayer()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
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

    private var displayItem: AudioTherapyItem? {
        currentItem ?? catalog.defaultItem
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyDisplayBackground()
        playDisplayItem()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isDetailPresentationActive = false
        beginInitialThumbnailTrackingIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        backgroundVideoView.pause()
        thumbnailTasks.forEach { $0.cancel() }
        thumbnailTasks.removeAll()
        cancelIdleCacheTasks()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bottomFadeLayer.frame = bottomFadeView.bounds
    }

    override func setupUI() {
        view.backgroundColor = UIColor(red: 0.07, green: 0.11, blue: 0.14, alpha: 1)
        currentItem = catalog.defaultItem
        selectedCategoryID = displayItem?.categoryID ?? categories.first?.id
        configureBackground()
        configureHeader()
        configureContent()
        applyDisplayBackground()
        playDisplayItem()
        renderCategories()
        renderCards()
    }

    override func setupBindings() {
        NotificationCenter.default.publisher(for: VideoThumbnailLoader.thumbnailDidLoadNotification)
            .compactMap { $0.userInfo?[VideoThumbnailLoader.thumbnailURLUserInfoKey] as? URL }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] url in
                self?.handleThumbnailDidLoad(for: url)
            }
            .store(in: &cancellables)
    }

    private func configureBackground() {
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.backgroundColor = UIColor(red: 0.16, green: 0.29, blue: 0.35, alpha: 1)
        view.addSubview(backgroundImageView)
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false

        backgroundVideoView.backgroundColor = UIColor(red: 0.10, green: 0.24, blue: 0.28, alpha: 1)
        backgroundVideoView.isUserInteractionEnabled = false
        view.addSubview(backgroundVideoView)
        backgroundVideoView.translatesAutoresizingMaskIntoConstraints = false

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

            backgroundVideoView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundVideoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundVideoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundVideoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

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
        titleLabel.text = "音疗专区"
        titleLabel.font = .systemFont(ofSize: 22, weight: .heavy)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.94)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1

        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 42),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -42)
        ])
    }

    private func configureContent() {
        scrollView.delegate = self
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
        categoryStackView.spacing = 16
        categoryScrollView.addSubview(categoryStackView)
        categoryStackView.translatesAutoresizingMaskIntoConstraints = false

        cardsGridView.axis = .vertical
        cardsGridView.spacing = 12

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
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor, constant: 120),

            categoryScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            categoryScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            categoryScrollView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 622),
            categoryScrollView.heightAnchor.constraint(equalToConstant: 38),

            categoryStackView.leadingAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.leadingAnchor, constant: 18),
            categoryStackView.trailingAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.trailingAnchor, constant: -18),
            categoryStackView.centerYAnchor.constraint(equalTo: categoryScrollView.frameLayoutGuide.centerYAnchor),
            categoryStackView.heightAnchor.constraint(equalTo: categoryScrollView.frameLayoutGuide.heightAnchor),

            cardsGridView.topAnchor.constraint(equalTo: categoryScrollView.bottomAnchor, constant: 12),
            cardsGridView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 22),
            cardsGridView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -22),
            cardsGridView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])
    }

    private func applyDisplayBackground() {
        guard let item = displayItem else { return }
        applyBackground(for: item)
    }

    private func applyBackground(for item: AudioTherapyItem) {
        let videoURL = item.videoURL
        let task = Task { [weak self] in
            let image = await VideoThumbnailLoader.shared.loadThumbnail(for: videoURL)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard self?.displayItem?.videoURL == videoURL else { return }
                self?.backgroundImageView.image = image
            }
        }
        thumbnailTasks.append(task)
    }

    private func playDisplayItem() {
        guard let item = displayItem else { return }
        backgroundVideoView.configure(url: item.videoURL, isMuted: false, videoGravity: .resizeAspectFill)
        backgroundVideoView.play()
    }

    private func applyCurrentItem(_ item: AudioTherapyItem, shouldPlay: Bool) {
        currentItem = item
        selectedCategoryID = item.categoryID
        applyBackground(for: item)
        if shouldPlay {
            playDisplayItem()
        }
        renderCategories()
        renderCards()
    }

    private func renderCategories() {
        categoryButtons.forEach { $0.removeFromSuperview() }
        categoryButtons = []

        categories.enumerated().forEach { index, category in
            let isSelected = category.id == selectedCategoryID
            let button = UIButton(type: .system)
            button.tag = index
            button.setTitle(category.title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 15, weight: isSelected ? .heavy : .medium)
            button.tintColor = .white
            button.addTarget(self, action: #selector(handleCategoryTap(_:)), for: .touchUpInside)
            button.heightAnchor.constraint(equalToConstant: 38).isActive = true

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
                underline.widthAnchor.constraint(equalToConstant: 22),
                underline.heightAnchor.constraint(equalToConstant: 2)
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
            rowView.spacing = 12
            rowView.heightAnchor.constraint(equalToConstant: 162).isActive = true

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

        scheduleInitialThumbnailTrackingRefresh()
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
        isDetailPresentationActive = true
        applyCurrentItem(sender.item, shouldPlay: true)
        VideoCacheService.shared.recordVisitedDetailURL(sender.item.videoURL)
        cancelIdleCacheTasks()
        let playerViewController = AudioTherapyPlayerViewController(items: items, selectedItem: sender.item)
        playerViewController.onSelectedItemChanged = { [weak self] item in
            self?.applyCurrentItem(item, shouldPlay: false)
        }
        playerViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(playerViewController, animated: true)
    }

    private func scheduleInitialThumbnailTrackingRefresh() {
        guard isViewLoaded, view.window != nil else { return }

        DispatchQueue.main.async { [weak self] in
            self?.beginInitialThumbnailTrackingIfNeeded()
        }
    }

    private func beginInitialThumbnailTrackingIfNeeded() {
        guard view.window != nil else { return }

        cancelIdleCacheTasks()
        hasInitialThumbnailDisplaySettled = false
        pendingInitialThumbnailURLs = pendingVisibleThumbnailURLs()

        guard !pendingInitialThumbnailURLs.isEmpty else {
            completeInitialThumbnailDisplayIfNeeded()
            return
        }

        initialThumbnailTimeoutTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: self.initialThumbnailTimeout)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                self.completeInitialThumbnailDisplayIfNeeded()
            }
        }
    }

    private func completeInitialThumbnailDisplayIfNeeded() {
        guard !hasInitialThumbnailDisplaySettled else { return }

        hasInitialThumbnailDisplaySettled = true
        pendingInitialThumbnailURLs.removeAll()
        initialThumbnailTimeoutTask?.cancel()
        initialThumbnailTimeoutTask = nil
        armIdleCacheTask(after: idleCacheStartDelay)
    }

    private func handleThumbnailDidLoad(for url: URL) {
        guard pendingInitialThumbnailURLs.remove(url) != nil else { return }

        if pendingInitialThumbnailURLs.isEmpty {
            completeInitialThumbnailDisplayIfNeeded()
        }
    }

    private func pendingVisibleThumbnailURLs() -> Set<URL> {
        var urls = Set<URL>()

        if backgroundImageView.image == nil, let displayItem {
            urls.insert(displayItem.videoURL)
        }

        collectPendingThumbnailURLs(in: view, into: &urls)
        return urls
    }

    private func collectPendingThumbnailURLs(in rootView: UIView, into urls: inout Set<URL>) {
        if let thumbnailView = rootView as? VideoThumbnailImageView,
           thumbnailView.image == nil,
           let currentVideoURL = thumbnailView.currentVideoURL,
           thumbnailView.window != nil {
            let frame = thumbnailView.convert(thumbnailView.bounds, to: view)
            if view.bounds.intersects(frame) {
                urls.insert(currentVideoURL)
            }
        }

        rootView.subviews.forEach { subview in
            collectPendingThumbnailURLs(in: subview, into: &urls)
        }
    }

    private func armIdleCacheTask(after delay: Duration) {
        idleCacheTask?.cancel()

        guard hasInitialThumbnailDisplaySettled else { return }

        idleCacheTask = Task(priority: .background) { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }

            let canStartCaching = await MainActor.run {
                self.canStartIdleCaching()
            }
            guard canStartCaching else { return }

            await VideoCacheService.shared.cacheVisitedDetailVideosIfNeeded()
        }
    }

    private func canStartIdleCaching() -> Bool {
        hasInitialThumbnailDisplaySettled
            && view.window != nil
            && !isDetailPresentationActive
            && !isPrimaryScrollInteracting
            && presentedViewController == nil
    }

    private func cancelIdleCacheTasks() {
        idleCacheTask?.cancel()
        idleCacheTask = nil
        initialThumbnailTimeoutTask?.cancel()
        initialThumbnailTimeoutTask = nil
    }
}

extension AudioTherapyViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView === self.scrollView else { return }
        isPrimaryScrollInteracting = true
        idleCacheTask?.cancel()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView === self.scrollView, !decelerate else { return }
        isPrimaryScrollInteracting = false
        armIdleCacheTask(after: idleCacheResumeDelay)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === self.scrollView else { return }
        isPrimaryScrollInteracting = false
        armIdleCacheTask(after: idleCacheResumeDelay)
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

        imageView.layer.cornerRadius = 34
        imageView.layer.cornerCurve = .continuous
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.white.withAlphaComponent(0.16).cgColor

        playBadgeView.backgroundColor = UIColor(red: 0.36, green: 0.35, blue: 0.44, alpha: 0.90)
        playBadgeView.layer.cornerRadius = 16
        playBadgeView.layer.cornerCurve = .continuous
        playBadgeView.layer.borderWidth = 3
        playBadgeView.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor

        let playIcon = UIImageView(image: UIImage(systemName: "play.fill"))
        playIcon.tintColor = .white
        playIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        playBadgeView.addSubview(playIcon)
        playIcon.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 14, weight: .heavy)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.78

        countLabel.font = .systemFont(ofSize: 11, weight: .medium)
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
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 22),
            imageView.widthAnchor.constraint(equalToConstant: 68),
            imageView.heightAnchor.constraint(equalToConstant: 68),

            playBadgeView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10),
            playBadgeView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 5),
            playBadgeView.widthAnchor.constraint(equalToConstant: 32),
            playBadgeView.heightAnchor.constraint(equalToConstant: 32),

            playIcon.centerXAnchor.constraint(equalTo: playBadgeView.centerXAnchor, constant: 2),
            playIcon.centerYAnchor.constraint(equalTo: playBadgeView.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),

            countLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            countLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            countLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
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

    var currentVideoURL: URL? {
        videoURL
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
