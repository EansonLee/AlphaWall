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
    private let heroTopBaseline: CGFloat = 150
    private let heroHeaderSpacing: CGFloat = 24

    private let backgroundImageView = UIImageView()
    private let backgroundVideoView = LoopingVideoView()
    private let topDimView = UIView()
    private let bottomFadeView = UIView()
    private let bottomFadeLayer = CAGradientLayer()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerStackView = UIStackView()
    private let eyebrowLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let heroPanelView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let heroImageView = VideoThumbnailImageView()
    private let heroAccentView = UIView()
    private let heroCategoryLabel = UILabel()
    private let heroTitleLabel = UILabel()
    private let heroMetaLabel = UILabel()
    private let listHeaderLabel = UILabel()
    private let categoryScrollView = UIScrollView()
    private let categoryStackView = UIStackView()
    private let cardsGridView = UIStackView()
    private var categoryButtons: [UIButton] = []
    private var heroTopConstraint: NSLayoutConstraint?

    private var items: [AudioTherapyItem] {
        catalog.items
    }

    private var categories: [AudioTherapyCategory] {
        catalog.categories
    }

    private var displayItem: AudioTherapyItem? {
        currentItem ?? catalog.defaultItem
    }

    private var selectedCategory: AudioTherapyCategory? {
        guard let selectedCategoryID else { return categories.first }
        return categories.first { $0.id == selectedCategoryID }
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
        updateHeroTopConstraint()
        categoryButtons.forEach {
            $0.layer.cornerRadius = $0.bounds.height * 0.5
        }
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
        updateHeroPanel()
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
        headerStackView.axis = .vertical
        headerStackView.alignment = .leading
        headerStackView.spacing = 5
        headerStackView.isUserInteractionEnabled = false

        eyebrowLabel.text = L10n.text("audio.eyebrow")
        eyebrowLabel.font = .monospacedSystemFont(ofSize: 11, weight: .semibold)
        eyebrowLabel.textColor = UIColor(red: 0.63, green: 0.91, blue: 0.93, alpha: 0.78)

        titleLabel.text = L10n.text("audio.title")
        titleLabel.font = .systemFont(ofSize: 31, weight: .heavy)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.96)
        titleLabel.numberOfLines = 1

        subtitleLabel.text = L10n.text("audio.subtitle")
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.62)
        subtitleLabel.numberOfLines = 1
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.minimumScaleFactor = 0.82

        [eyebrowLabel, titleLabel, subtitleLabel].forEach {
            headerStackView.addArrangedSubview($0)
        }

        view.addSubview(headerStackView)
        headerStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28),
            headerStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            headerStackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func configureContent() {
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 18, right: 0)
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        configureHeroPanel()

        categoryScrollView.showsHorizontalScrollIndicator = false
        categoryScrollView.contentInsetAdjustmentBehavior = .never
        categoryStackView.axis = .horizontal
        categoryStackView.alignment = .center
        categoryStackView.spacing = 10
        categoryScrollView.addSubview(categoryStackView)
        categoryStackView.translatesAutoresizingMaskIntoConstraints = false

        cardsGridView.axis = .vertical
        cardsGridView.spacing = 10

        listHeaderLabel.text = L10n.text("audio.list.header")
        listHeaderLabel.font = .systemFont(ofSize: 13, weight: .bold)
        listHeaderLabel.textColor = UIColor.white.withAlphaComponent(0.66)

        contentView.addSubview(heroPanelView)
        contentView.addSubview(categoryScrollView)
        contentView.addSubview(listHeaderLabel)
        contentView.addSubview(cardsGridView)
        heroPanelView.translatesAutoresizingMaskIntoConstraints = false
        categoryScrollView.translatesAutoresizingMaskIntoConstraints = false
        listHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        cardsGridView.translatesAutoresizingMaskIntoConstraints = false

        let heroTopConstraint = heroPanelView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: heroTopBaseline)
        self.heroTopConstraint = heroTopConstraint

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
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor, constant: 140),

            heroTopConstraint,
            heroPanelView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 22),
            heroPanelView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -22),
            heroPanelView.heightAnchor.constraint(equalToConstant: 282),

            categoryScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            categoryScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            categoryScrollView.topAnchor.constraint(equalTo: heroPanelView.bottomAnchor, constant: 22),
            categoryScrollView.heightAnchor.constraint(equalToConstant: 44),

            categoryStackView.leadingAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.leadingAnchor, constant: 18),
            categoryStackView.trailingAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.trailingAnchor, constant: -18),
            categoryStackView.centerYAnchor.constraint(equalTo: categoryScrollView.frameLayoutGuide.centerYAnchor),
            categoryStackView.heightAnchor.constraint(equalTo: categoryScrollView.frameLayoutGuide.heightAnchor),

            listHeaderLabel.topAnchor.constraint(equalTo: categoryScrollView.bottomAnchor, constant: 18),
            listHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            listHeaderLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            cardsGridView.topAnchor.constraint(equalTo: listHeaderLabel.bottomAnchor, constant: 10),
            cardsGridView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 22),
            cardsGridView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -22),
            cardsGridView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])
    }

    private func updateHeroTopConstraint() {
        guard let heroTopConstraint else { return }

        let headerBottomInScrollFrame = headerStackView.frame.maxY - scrollView.frame.minY
        let requiredTop = ceil(headerBottomInScrollFrame + heroHeaderSpacing)
        let nextTop = max(heroTopBaseline, requiredTop)

        if abs(heroTopConstraint.constant - nextTop) > 0.5 {
            heroTopConstraint.constant = nextTop
        }
    }

    private func configureHeroPanel() {
        heroPanelView.layer.cornerRadius = 24
        heroPanelView.layer.cornerCurve = .continuous
        heroPanelView.layer.borderWidth = 1
        heroPanelView.layer.borderColor = UIColor.white.withAlphaComponent(0.13).cgColor
        heroPanelView.clipsToBounds = true
        heroPanelView.backgroundColor = UIColor(red: 0.03, green: 0.12, blue: 0.14, alpha: 0.28)
        heroPanelView.isUserInteractionEnabled = true

        heroImageView.layer.cornerRadius = 18
        heroImageView.layer.cornerCurve = .continuous
        heroImageView.layer.borderWidth = 1
        heroImageView.layer.borderColor = UIColor.white.withAlphaComponent(0.14).cgColor

        heroAccentView.backgroundColor = UIColor(red: 0.09, green: 0.80, blue: 0.72, alpha: 1)
        heroAccentView.layer.cornerRadius = 3
        heroAccentView.layer.cornerCurve = .continuous

        heroCategoryLabel.font = .monospacedSystemFont(ofSize: 11, weight: .bold)
        heroCategoryLabel.textColor = UIColor.white.withAlphaComponent(0.58)

        heroTitleLabel.font = .systemFont(ofSize: 26, weight: .heavy)
        heroTitleLabel.textColor = UIColor.white.withAlphaComponent(0.97)
        heroTitleLabel.numberOfLines = 2
        heroTitleLabel.adjustsFontSizeToFitWidth = true
        heroTitleLabel.minimumScaleFactor = 0.78

        heroMetaLabel.font = .systemFont(ofSize: 13, weight: .medium)
        heroMetaLabel.textColor = UIColor.white.withAlphaComponent(0.62)
        heroMetaLabel.numberOfLines = 2

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleHeroTap))
        heroPanelView.addGestureRecognizer(tapGesture)

        [heroImageView, heroAccentView, heroCategoryLabel, heroTitleLabel, heroMetaLabel].forEach {
            heroPanelView.contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            heroImageView.topAnchor.constraint(equalTo: heroPanelView.contentView.topAnchor, constant: 14),
            heroImageView.leadingAnchor.constraint(equalTo: heroPanelView.contentView.leadingAnchor, constant: 14),
            heroImageView.trailingAnchor.constraint(equalTo: heroPanelView.contentView.trailingAnchor, constant: -14),
            heroImageView.heightAnchor.constraint(equalToConstant: 132),

            heroAccentView.leadingAnchor.constraint(equalTo: heroPanelView.contentView.leadingAnchor, constant: 18),
            heroAccentView.topAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: 20),
            heroAccentView.widthAnchor.constraint(equalToConstant: 6),
            heroAccentView.heightAnchor.constraint(equalToConstant: 38),

            heroCategoryLabel.leadingAnchor.constraint(equalTo: heroAccentView.trailingAnchor, constant: 12),
            heroCategoryLabel.trailingAnchor.constraint(equalTo: heroPanelView.contentView.trailingAnchor, constant: -18),
            heroCategoryLabel.topAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: 17),

            heroTitleLabel.leadingAnchor.constraint(equalTo: heroCategoryLabel.leadingAnchor),
            heroTitleLabel.trailingAnchor.constraint(equalTo: heroPanelView.contentView.trailingAnchor, constant: -18),
            heroTitleLabel.topAnchor.constraint(equalTo: heroCategoryLabel.bottomAnchor, constant: 4),

            heroMetaLabel.leadingAnchor.constraint(equalTo: heroPanelView.contentView.leadingAnchor, constant: 18),
            heroMetaLabel.trailingAnchor.constraint(equalTo: heroPanelView.contentView.trailingAnchor, constant: -18),
            heroMetaLabel.bottomAnchor.constraint(equalTo: heroPanelView.contentView.bottomAnchor, constant: -22)
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
        updateHeroPanel()
        renderCards()
    }

    private func updateHeroPanel() {
        guard let item = displayItem else { return }

        heroImageView.configure(videoURL: item.videoURL)
        heroAccentView.backgroundColor = item.accentColor.mixed(with: UIColor(red: 0.17, green: 0.90, blue: 0.82, alpha: 1), amount: 0.46)
        heroCategoryLabel.text = "\(item.categoryTitle.uppercased()) · \(L10n.text("audio.today_field"))"
        heroTitleLabel.text = item.title
        heroMetaLabel.text = L10n.text("audio.hero.meta", item.listenerCount)
        listHeaderLabel.text = L10n.text("audio.list.header.category", selectedCategory?.title ?? item.categoryTitle)
        heroPanelView.accessibilityLabel = L10n.text("audio.hero.accessibility", item.title, item.listenerCount)
    }

    private func renderCategories() {
        categoryButtons.forEach { $0.removeFromSuperview() }
        categoryButtons = []

        categories.enumerated().forEach { index, category in
            let isSelected = category.id == selectedCategoryID
            let button = UIButton(type: .system)
            button.tag = index
            button.setTitle(category.title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: isSelected ? .bold : .semibold)
            button.tintColor = isSelected ? .white : UIColor.white.withAlphaComponent(0.62)
            button.backgroundColor = isSelected
                ? UIColor(red: 0.08, green: 0.65, blue: 0.58, alpha: 0.78)
                : UIColor.white.withAlphaComponent(0.08)
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.white.withAlphaComponent(isSelected ? 0.20 : 0.08).cgColor
            button.layer.cornerRadius = 19
            button.layer.cornerCurve = .continuous
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            button.addTarget(self, action: #selector(handleCategoryTap(_:)), for: .touchUpInside)
            button.heightAnchor.constraint(equalToConstant: 38).isActive = true

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
        filtered.enumerated().forEach { index, item in
            let cardView = AudioTherapyCardView(item: item, rank: index + 1)
            cardView.addGestureRecognizer(AudioTherapyItemTapGestureRecognizer(item: item, target: self, action: #selector(handleItemTap(_:))))
            cardView.heightAnchor.constraint(equalToConstant: 92).isActive = true
            cardsGridView.addArrangedSubview(cardView)
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
        updateHeroPanel()
        renderCards()
    }

    @objc
    private func handleHeroTap() {
        guard let item = displayItem else { return }
        presentPlayer(for: item)
    }

    @objc
    private func handleItemTap(_ sender: AudioTherapyItemTapGestureRecognizer) {
        presentPlayer(for: sender.item)
    }

    private func presentPlayer(for item: AudioTherapyItem) {
        isDetailPresentationActive = true
        applyCurrentItem(item, shouldPlay: true)
        VideoCacheService.shared.recordVisitedDetailURL(item.videoURL)
        cancelIdleCacheTasks()
        let playerViewController = AudioTherapyPlayerViewController(items: items, selectedItem: item)
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
    private let rank: Int
    private let rankLabel = UILabel()
    private let imageView = VideoThumbnailImageView()
    private let titleLabel = UILabel()
    private let categoryLabel = UILabel()
    private let countLabel = UILabel()
    private let enterIconView = UIImageView(image: UIImage(systemName: "chevron.forward"))

    init(item: AudioTherapyItem, rank: Int) {
        self.item = item
        self.rank = rank
        super.init(frame: .zero)
        configure()
        apply(item: item)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        layer.cornerRadius = 20
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.16
        layer.shadowRadius = 16
        layer.shadowOffset = CGSize(width: 0, height: 10)
        backgroundColor = UIColor.black.withAlphaComponent(0.20)
        isUserInteractionEnabled = true

        rankLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .bold)
        rankLabel.textColor = UIColor.white.withAlphaComponent(0.48)
        rankLabel.textAlignment = .center

        imageView.layer.cornerRadius = 18
        imageView.layer.cornerCurve = .continuous
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor

        titleLabel.font = .systemFont(ofSize: 16, weight: .heavy)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.94)
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.82

        categoryLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        categoryLabel.textColor = UIColor(red: 0.63, green: 0.91, blue: 0.93, alpha: 0.66)

        countLabel.font = .systemFont(ofSize: 11, weight: .medium)
        countLabel.textColor = UIColor.white.withAlphaComponent(0.48)

        enterIconView.tintColor = UIColor.white.withAlphaComponent(0.40)
        enterIconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)

        addSubview(rankLabel)
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(categoryLabel)
        addSubview(countLabel)
        addSubview(enterIconView)
        rankLabel.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        enterIconView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            rankLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            rankLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            rankLabel.widthAnchor.constraint(equalToConstant: 24),

            imageView.leadingAnchor.constraint(equalTo: rankLabel.trailingAnchor, constant: 10),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 56),
            imageView.heightAnchor.constraint(equalToConstant: 56),

            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: enterIconView.leadingAnchor, constant: -12),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 18),

            categoryLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            categoryLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            categoryLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),

            countLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            countLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            countLabel.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 4),

            enterIconView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            enterIconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            enterIconView.widthAnchor.constraint(equalToConstant: 12),
            enterIconView.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    private func apply(item: AudioTherapyItem) {
        imageView.configure(videoURL: item.videoURL)
        rankLabel.text = String(format: "%02d", rank)
        titleLabel.text = item.title
        categoryLabel.text = item.categoryTitle
        countLabel.text = L10n.text("audio.card.count_action", item.listenerCount)
        accessibilityLabel = L10n.text("audio.card.accessibility", item.title, item.listenerCount)
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

private extension UIColor {
    func mixed(with other: UIColor, amount: CGFloat) -> UIColor {
        let amount = min(max(amount, 0), 1)
        let base = rgbaComponents
        let target = other.rgbaComponents

        return UIColor(
            red: base.red + ((target.red - base.red) * amount),
            green: base.green + ((target.green - base.green) * amount),
            blue: base.blue + ((target.blue - base.blue) * amount),
            alpha: base.alpha + ((target.alpha - base.alpha) * amount)
        )
    }

    private var rgbaComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        if getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return (red, green, blue, alpha)
        }

        var white: CGFloat = 0
        if getWhite(&white, alpha: &alpha) {
            return (white, white, white, alpha)
        }

        return (0, 0, 0, 1)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
