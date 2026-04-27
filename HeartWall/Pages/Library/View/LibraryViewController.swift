//
//  LibraryViewController.swift
//  HeartWall
//

import UIKit
import Combine
import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins

final class LibraryViewController: BaseViewController {

    private struct FeaturedBackgroundTheme {
        let backgroundColors: [UIColor]
        let glowColors: [UIColor]
        let dimColor: UIColor
        let bottomFadeColor: UIColor
        let glowCenter: CGPoint
    }

    // MARK: - Properties

    private let viewModel = LibraryViewModel()
    private var featuredPages: [HeartQuotePage] = []
    private var sections: [HeartQuoteSection] = []
    private var allPages: [HeartQuotePage] = []
    private var carouselTimer: Timer?
    private var currentCarouselIndex = 0
    private var currentCarouselItem = 0
    private var appliedFeaturedLogicalIndex: Int?
    private var currentBackgroundVideoURL: URL?
    private var backgroundImageTask: Task<Void, Never>?
    private var idleCacheTask: Task<Void, Never>?
    private var initialThumbnailTimeoutTask: Task<Void, Never>?
    private var pendingInitialThumbnailURLs = Set<URL>()
    private var hasInitialThumbnailDisplaySettled = false
    private var isDetailPresentationActive = false
    private var isPrimaryScrollInteracting = false
    private var isCarouselScrollInteracting = false
    private let carouselLoopMultiplier = 400

    private let headerHeight: CGFloat = 72
    private let contentHorizontalInset: CGFloat = 16
    private let tabBarReservedHeight: CGFloat = 112
    private let idleCacheStartDelay: Duration = .seconds(3)
    private let idleCacheResumeDelay: Duration = .seconds(2)
    private let initialThumbnailTimeout: Duration = .seconds(6)
    private lazy var defaultBackgroundTheme = makeFallbackBackgroundTheme(seed: 0)
    private var generatedBackgroundThemes: [URL: FeaturedBackgroundTheme] = [:]

    // MARK: - UI

    private let backgroundImageView = UIImageView()
    private let backgroundGradientView = UIView()
    private let backgroundGlowView = UIView()
    private let backgroundGradientLayer = CAGradientLayer()
    private let backgroundGlowLayer = CAGradientLayer()
    private let dimView = UIView()
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let topHeaderView = UIView()
    private let monthLabel = UILabel()
    private let dayLabel = UILabel()
    private let greetingLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let appBadgeView = UIView()
    private let appBadgeTextLabel = UILabel()
    private let carouselCollectionView: UICollectionView
    private let featuredTitleLabel = UILabel()
    private let featuredSummaryLabel = UILabel()
    private let featuredTagStackView = UIStackView()
    private let bottomFadeView = UIView()
    private let bottomGradientLayer = CAGradientLayer()
    private let backgroundTransitionDuration: CFTimeInterval = 0.78
    private let colorAnalysisContext = CIContext(options: [
        .workingColorSpace: NSNull(),
        .outputColorSpace: NSNull()
    ])

    // MARK: - Lifecycle

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        carouselCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.viewDidLoad.send(())
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isDetailPresentationActive = false
        startCarouselTimerIfNeeded()
        beginInitialThumbnailTrackingIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCarouselTimer()
        cancelIdleCacheTasks()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradientLayer.frame = backgroundGradientView.bounds
        backgroundGlowLayer.frame = backgroundGlowView.bounds
        bottomGradientLayer.frame = bottomFadeView.bounds
        if let badgeGradient = appBadgeView.layer.sublayers?.first as? CAGradientLayer {
            badgeGradient.frame = appBadgeView.bounds
        }
        updateCarouselLayout()
        updateCarouselCardEmphasis()
    }

    // MARK: - Setup

    override func setupUI() {
        view.backgroundColor = UIColor(red: 0.22, green: 0.22, blue: 0.23, alpha: 1)
        configureBackground()
        configureScrollView()
        configureCarousel()
        configureHeader()
        configureBottomFade()
    }

    override func setupBindings() {
        viewModel.$featuredPages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pages in
                self?.featuredPages = pages
                self?.renderCarousel()
            }
            .store(in: &cancellables)

        viewModel.$sections
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sections in
                self?.sections = sections
                self?.renderSections(sections)
            }
            .store(in: &cancellables)

        viewModel.$allPages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pages in
                self?.allPages = pages
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: VideoThumbnailLoader.thumbnailDidLoadNotification)
            .compactMap { $0.userInfo?[VideoThumbnailLoader.thumbnailURLUserInfoKey] as? URL }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] url in
                self?.handleThumbnailDidLoad(for: url)
            }
            .store(in: &cancellables)
    }

    // MARK: - Configuration

    private func configureBackground() {
        backgroundImageView.image = nil
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.alpha = 0.22
        backgroundImageView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        view.addSubview(backgroundImageView)
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false

        backgroundGradientLayer.startPoint = CGPoint(x: 0.15, y: 0)
        backgroundGradientLayer.endPoint = CGPoint(x: 0.88, y: 1)
        backgroundGradientLayer.colors = defaultBackgroundTheme.backgroundColors.map(\.cgColor)
        backgroundGradientView.layer.addSublayer(backgroundGradientLayer)
        view.addSubview(backgroundGradientView)
        backgroundGradientView.translatesAutoresizingMaskIntoConstraints = false

        backgroundGlowLayer.type = .radial
        backgroundGlowLayer.startPoint = defaultBackgroundTheme.glowCenter
        backgroundGlowLayer.endPoint = CGPoint(x: 1, y: 1)
        backgroundGlowLayer.colors = defaultBackgroundTheme.glowColors.map(\.cgColor)
        backgroundGlowView.alpha = 0.9
        backgroundGlowView.layer.addSublayer(backgroundGlowLayer)
        view.addSubview(backgroundGlowView)
        backgroundGlowView.translatesAutoresizingMaskIntoConstraints = false

        dimView.backgroundColor = defaultBackgroundTheme.dimColor
        view.addSubview(dimView)
        dimView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            backgroundGradientView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundGradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundGradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundGradientView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            backgroundGlowView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundGlowView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundGlowView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundGlowView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureScrollView() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = self
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        stackView.axis = .vertical
        stackView.spacing = 24
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: headerHeight),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -tabBarReservedHeight),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    private func configureCarousel() {
        carouselCollectionView.backgroundColor = .clear
        carouselCollectionView.showsHorizontalScrollIndicator = false
        carouselCollectionView.isPagingEnabled = false
        carouselCollectionView.decelerationRate = .fast
        carouselCollectionView.contentInsetAdjustmentBehavior = .never
        carouselCollectionView.clipsToBounds = false
        carouselCollectionView.dataSource = self
        carouselCollectionView.delegate = self
        carouselCollectionView.register(HeartQuoteHeroCell.self, forCellWithReuseIdentifier: HeartQuoteHeroCell.reuseIdentifier)

        featuredTitleLabel.text = HeartQuoteTheme.banner.displayTitle
        featuredTitleLabel.font = UIFont.systemFont(ofSize: 20, weight: .black)
        featuredTitleLabel.textColor = .white
        featuredTitleLabel.textAlignment = .center

        featuredSummaryLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        featuredSummaryLabel.textColor = UIColor.white.withAlphaComponent(0.78)
        featuredSummaryLabel.textAlignment = .center
        featuredSummaryLabel.numberOfLines = 2

        featuredTagStackView.axis = .horizontal
        featuredTagStackView.alignment = .center
        featuredTagStackView.spacing = 8
        featuredTagStackView.distribution = .fillProportionally

        let container = UIView()
        container.clipsToBounds = false
        container.addSubview(featuredTitleLabel)
        container.addSubview(carouselCollectionView)
        container.addSubview(featuredSummaryLabel)
        container.addSubview(featuredTagStackView)
        featuredTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        carouselCollectionView.translatesAutoresizingMaskIntoConstraints = false
        featuredSummaryLabel.translatesAutoresizingMaskIntoConstraints = false
        featuredTagStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            featuredTitleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            featuredTitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            featuredTitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),

            carouselCollectionView.topAnchor.constraint(equalTo: featuredTitleLabel.bottomAnchor, constant: 12),
            carouselCollectionView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            carouselCollectionView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            carouselCollectionView.heightAnchor.constraint(equalToConstant: 236),

            featuredSummaryLabel.topAnchor.constraint(equalTo: carouselCollectionView.bottomAnchor, constant: 10),
            featuredSummaryLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 34),
            featuredSummaryLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -34),

            featuredTagStackView.topAnchor.constraint(equalTo: featuredSummaryLabel.bottomAnchor, constant: 8),
            featuredTagStackView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            featuredTagStackView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        stackView.addArrangedSubview(container)
    }

    private func configureHeader() {
        view.addSubview(topHeaderView)
        topHeaderView.translatesAutoresizingMaskIntoConstraints = false

        monthLabel.text = currentMonthText()
        monthLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        monthLabel.textColor = UIColor.white.withAlphaComponent(0.68)

        dayLabel.text = currentDayText()
        dayLabel.font = UIFont.systemFont(ofSize: 24, weight: .black)
        dayLabel.textColor = .white

        greetingLabel.text = currentGreetingText()
        greetingLabel.font = UIFont.systemFont(ofSize: 22, weight: .black)
        greetingLabel.textColor = .white

        subtitleLabel.text = "今日心语"
        subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.66)

        appBadgeView.layer.cornerRadius = 10
        appBadgeView.layer.cornerCurve = .continuous
        appBadgeView.layer.masksToBounds = true
        let badgeGradient = CAGradientLayer()
        badgeGradient.colors = [
            UIColor(red: 1.0, green: 0.88, blue: 0.60, alpha: 1).cgColor,
            UIColor(red: 0.98, green: 0.64, blue: 0.37, alpha: 1).cgColor
        ]
        badgeGradient.startPoint = CGPoint(x: 0, y: 0)
        badgeGradient.endPoint = CGPoint(x: 1, y: 1)
        appBadgeView.layer.insertSublayer(badgeGradient, at: 0)

        appBadgeTextLabel.text = "V"
        appBadgeTextLabel.font = UIFont.systemFont(ofSize: 14, weight: .black)
        appBadgeTextLabel.textColor = UIColor(red: 0.70, green: 0.42, blue: 0.27, alpha: 1)

        let dateStack = UIStackView(arrangedSubviews: [monthLabel, dayLabel])
        dateStack.axis = .vertical
        dateStack.alignment = .leading
        dateStack.spacing = -2

        let greetingStack = UIStackView(arrangedSubviews: [greetingLabel, subtitleLabel])
        greetingStack.axis = .vertical
        greetingStack.alignment = .leading
        greetingStack.spacing = 1

        topHeaderView.addSubview(dateStack)
        topHeaderView.addSubview(greetingStack)
        topHeaderView.addSubview(appBadgeView)
        appBadgeView.addSubview(appBadgeTextLabel)

        dateStack.translatesAutoresizingMaskIntoConstraints = false
        greetingStack.translatesAutoresizingMaskIntoConstraints = false
        appBadgeView.translatesAutoresizingMaskIntoConstraints = false
        appBadgeTextLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topHeaderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            topHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: contentHorizontalInset),
            topHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -contentHorizontalInset),
            topHeaderView.heightAnchor.constraint(equalToConstant: 58),

            dateStack.leadingAnchor.constraint(equalTo: topHeaderView.leadingAnchor),
            dateStack.centerYAnchor.constraint(equalTo: topHeaderView.centerYAnchor, constant: 2),

            greetingStack.leadingAnchor.constraint(equalTo: dateStack.trailingAnchor, constant: 14),
            greetingStack.centerYAnchor.constraint(equalTo: topHeaderView.centerYAnchor, constant: 2),
            greetingStack.trailingAnchor.constraint(lessThanOrEqualTo: appBadgeView.leadingAnchor, constant: -12),

            appBadgeView.trailingAnchor.constraint(equalTo: topHeaderView.trailingAnchor),
            appBadgeView.centerYAnchor.constraint(equalTo: topHeaderView.centerYAnchor, constant: 2),
            appBadgeView.widthAnchor.constraint(equalToConstant: 26),
            appBadgeView.heightAnchor.constraint(equalToConstant: 26),

            appBadgeTextLabel.centerXAnchor.constraint(equalTo: appBadgeView.centerXAnchor),
            appBadgeTextLabel.centerYAnchor.constraint(equalTo: appBadgeView.centerYAnchor)
        ])
    }

    private func configureBottomFade() {
        bottomGradientLayer.colors = [
            UIColor.clear.cgColor,
            defaultBackgroundTheme.bottomFadeColor.cgColor
        ]
        bottomGradientLayer.locations = [0, 1]
        bottomFadeView.isUserInteractionEnabled = false
        bottomFadeView.layer.addSublayer(bottomGradientLayer)
        view.addSubview(bottomFadeView)
        bottomFadeView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            bottomFadeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomFadeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomFadeView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomFadeView.heightAnchor.constraint(equalToConstant: 124)
        ])
    }

    // MARK: - Rendering

    private func renderCarousel() {
        stopCarouselTimer()
        currentCarouselIndex = 0
        appliedFeaturedLogicalIndex = nil
        currentCarouselItem = initialCarouselItem(for: 0)
        currentBackgroundVideoURL = nil
        backgroundImageTask?.cancel()
        carouselCollectionView.reloadData()
        view.layoutIfNeeded()
        scrollCarousel(toItem: currentCarouselItem, animated: false)
        startCarouselTimerIfNeeded()
        scheduleInitialThumbnailTrackingRefresh()
    }

    private func renderSections(_ sections: [HeartQuoteSection]) {
        stackView.arrangedSubviews.dropFirst().forEach { arrangedView in
            stackView.removeArrangedSubview(arrangedView)
            arrangedView.removeFromSuperview()
        }

        sections.enumerated().forEach { index, section in
            stackView.addArrangedSubview(HeartQuoteSectionView(section: section, chapterNumber: index + 1, target: self, action: #selector(handleCardTap(_:))))
        }

        scheduleInitialThumbnailTrackingRefresh()
    }

    private func updateCarouselLayout() {
        guard let layout = carouselCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let availableWidth = max(0, view.bounds.width)
        layout.minimumLineSpacing = 8
        let itemWidth = min(184, max(156, availableWidth * 0.44))
        let itemHeight = min(236, max(206, itemWidth * 1.28))
        let newSize = CGSize(width: itemWidth, height: itemHeight)
        if layout.itemSize != newSize {
            layout.itemSize = newSize
            layout.invalidateLayout()
        }
        let sideInset = max(contentHorizontalInset, (availableWidth - itemWidth) / 2)
        carouselCollectionView.contentInset = UIEdgeInsets(top: 0, left: sideInset, bottom: 0, right: sideInset)
    }

    // MARK: - Carousel

    private func startCarouselTimerIfNeeded() {
        guard carouselTimer == nil, featuredPages.count > 1, isViewLoaded, view.window != nil else { return }
        let timer = Timer(timeInterval: 3.6, repeats: true) { [weak self] _ in
            self?.advanceCarousel()
        }
        carouselTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopCarouselTimer() {
        carouselTimer?.invalidate()
        carouselTimer = nil
    }

    private func advanceCarousel() {
        guard featuredPages.count > 1 else { return }
        scrollCarousel(toItem: currentCarouselItem + 1, animated: true)
    }

    private func scrollCarousel(toItem item: Int, animated: Bool) {
        guard totalCarouselItems > 0 else { return }
        let safeItem = max(0, min(item, totalCarouselItems - 1))
        currentCarouselItem = safeItem
        updateSelectedFeaturedPage(logicalIndex: logicalIndex(forCarouselItem: safeItem), animated: animated)
        let indexPath = IndexPath(item: safeItem, section: 0)
        carouselCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
        if !animated {
            carouselCollectionView.layoutIfNeeded()
            updateCarouselCardEmphasis()
        }
    }

    // MARK: - Actions

    @objc
    private func handleCardTap(_ sender: HeartQuoteCardTapGestureRecognizer) {
        showDetail(page: sender.page)
    }

    private func showDetail(page: HeartQuotePage) {
        isDetailPresentationActive = true
        VideoCacheService.shared.recordVisitedDetailURL(page.videoURL)
        cancelIdleCacheTasks()
        let detailPages = allDetailPages()
        let initialIndex = detailPages.firstIndex { $0.videoURL == page.videoURL } ?? 0
        let detailViewController = HeartQuoteDetailViewController(pages: detailPages, initialIndex: initialIndex)
        detailViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailViewController, animated: true)
    }

    private func allDetailPages() -> [HeartQuotePage] {
        allPages.isEmpty ? featuredPages + sections.flatMap(\.items) : allPages
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

        if backgroundImageView.image == nil, let currentBackgroundVideoURL {
            urls.insert(currentBackgroundVideoURL)
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
            && !isCarouselScrollInteracting
            && presentedViewController == nil
    }

    private func cancelIdleCacheTasks() {
        idleCacheTask?.cancel()
        idleCacheTask = nil
        initialThumbnailTimeoutTask?.cancel()
        initialThumbnailTimeoutTask = nil
    }

    private func currentMonthText() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM"
        return formatter.string(from: Date()).uppercased()
    }

    private func currentDayText() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "d"
        return formatter.string(from: Date())
    }

    private func currentGreetingText() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "早上好"
        case 12..<18:
            return "下午好"
        default:
            return "晚上好"
        }
    }

    private func updateFeaturedSummary(for index: Int) {
        guard featuredPages.indices.contains(index) else {
            featuredSummaryLabel.text = nil
            featuredTagStackView.arrangedSubviews.forEach { view in
                featuredTagStackView.removeArrangedSubview(view)
                view.removeFromSuperview()
            }
            return
        }

        let page = featuredPages[index]
        featuredSummaryLabel.text = page.subtitle

        featuredTagStackView.arrangedSubviews.forEach { view in
            featuredTagStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        page.tags.prefix(4).forEach { tag in
            let label = InsetLabel(top: 4, left: 8, bottom: 4, right: 8)
            label.text = tag
            label.font = UIFont.systemFont(ofSize: 11, weight: .medium)
            label.textColor = UIColor.white.withAlphaComponent(0.76)
            label.backgroundColor = UIColor.white.withAlphaComponent(0.10)
            label.layer.cornerRadius = 8
            label.layer.cornerCurve = .continuous
            label.clipsToBounds = true
            featuredTagStackView.addArrangedSubview(label)
        }
    }

    private var totalCarouselItems: Int {
        guard featuredPages.count > 1 else { return featuredPages.count }
        return featuredPages.count * carouselLoopMultiplier
    }

    private func initialCarouselItem(for logicalIndex: Int) -> Int {
        guard featuredPages.count > 1 else { return logicalIndex }
        let middleLoopStart = (carouselLoopMultiplier / 2) * featuredPages.count
        return middleLoopStart + logicalIndex
    }

    private func logicalIndex(forCarouselItem item: Int) -> Int {
        guard !featuredPages.isEmpty else { return 0 }
        let count = featuredPages.count
        let remainder = item % count
        return remainder >= 0 ? remainder : remainder + count
    }

    private func nearestCarouselItemIndex(for contentOffsetX: CGFloat) -> Int? {
        guard totalCarouselItems > 0,
              let layout = carouselCollectionView.collectionViewLayout as? UICollectionViewFlowLayout,
              layout.itemSize.width > 0 else {
            return nil
        }

        let stride = layout.itemSize.width + layout.minimumLineSpacing
        let visibleCenterX = contentOffsetX + (carouselCollectionView.bounds.width / 2)
        let rawIndex = (visibleCenterX - (layout.itemSize.width / 2)) / stride
        let nearestIndex = Int(round(rawIndex))
        return max(0, min(nearestIndex, totalCarouselItems - 1))
    }

    private func updateSelectedFeaturedPage(logicalIndex: Int, animated: Bool) {
        guard featuredPages.indices.contains(logicalIndex) else { return }
        currentCarouselIndex = logicalIndex
        guard appliedFeaturedLogicalIndex != logicalIndex else { return }
        appliedFeaturedLogicalIndex = logicalIndex
        updateFeaturedSummary(for: logicalIndex)
        applyBackgroundTheme(for: logicalIndex, animated: animated)
    }

    private func normalizeCarouselPositionIfNeeded() {
        guard featuredPages.count > 1 else { return }
        let logicalIndex = logicalIndex(forCarouselItem: currentCarouselItem)
        let normalizedItem = initialCarouselItem(for: logicalIndex)
        let distanceFromCenter = abs(currentCarouselItem - normalizedItem)
        let shouldNormalize = distanceFromCenter > featuredPages.count * 20
            || currentCarouselItem < featuredPages.count * 4
            || currentCarouselItem > totalCarouselItems - (featuredPages.count * 4)

        guard shouldNormalize else { return }
        currentCarouselItem = normalizedItem
        carouselCollectionView.scrollToItem(at: IndexPath(item: normalizedItem, section: 0), at: .centeredHorizontally, animated: false)
        carouselCollectionView.layoutIfNeeded()
        updateCarouselCardEmphasis()
    }

    private func updateCarouselCardEmphasis() {
        guard let layout = carouselCollectionView.collectionViewLayout as? UICollectionViewFlowLayout,
              layout.itemSize.width > 0 else {
            return
        }

        let visibleCenterX = carouselCollectionView.contentOffset.x + (carouselCollectionView.bounds.width / 2)
        let stride = layout.itemSize.width + layout.minimumLineSpacing

        carouselCollectionView.visibleCells.forEach { cell in
            guard let heroCell = cell as? HeartQuoteHeroCell else { return }
            let distance = abs(heroCell.center.x - visibleCenterX)
            let ratio = min(1, distance / stride)
            heroCell.applyEmphasis(distanceRatio: ratio)
        }

        guard let nearestItem = nearestCarouselItemIndex(for: carouselCollectionView.contentOffset.x) else { return }
        currentCarouselItem = nearestItem
        updateSelectedFeaturedPage(logicalIndex: logicalIndex(forCarouselItem: nearestItem), animated: true)
    }

    private func applyBackgroundTheme(for logicalIndex: Int, animated: Bool) {
        guard featuredPages.indices.contains(logicalIndex) else { return }
        let page = featuredPages[logicalIndex]
        let theme = backgroundTheme(for: page)

        updateGradientLayer(backgroundGradientLayer, colors: theme.backgroundColors.map(\.cgColor), animated: animated)
        updateGradientLayer(backgroundGlowLayer, colors: theme.glowColors.map(\.cgColor), animated: animated)
        backgroundGlowLayer.startPoint = theme.glowCenter
        UIView.animate(withDuration: animated ? backgroundTransitionDuration : 0, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState]) {
            self.dimView.backgroundColor = theme.dimColor
            self.view.backgroundColor = theme.backgroundColors.last
        }
        updateGradientLayer(bottomGradientLayer, colors: [UIColor.clear.cgColor, theme.bottomFadeColor.cgColor], animated: animated)

        updateBackgroundImage(for: page, animated: animated)
    }

    private func updateGradientLayer(_ layer: CAGradientLayer, colors: [CGColor], animated: Bool) {
        guard animated, let previousColors = layer.presentation()?.colors ?? layer.colors else {
            layer.colors = colors
            return
        }

        let animation = CABasicAnimation(keyPath: "colors")
        animation.fromValue = previousColors
        animation.toValue = colors
        animation.duration = backgroundTransitionDuration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.colors = colors
        layer.add(animation, forKey: "colors")
    }

    private func backgroundTheme(for page: HeartQuotePage) -> FeaturedBackgroundTheme {
        if let theme = generatedBackgroundThemes[page.videoURL] {
            return theme
        }

        let theme = makeFallbackBackgroundTheme(seed: stableSeed(for: page.videoURL))
        generatedBackgroundThemes[page.videoURL] = theme
        return theme
    }

    private func storeExtractedBackgroundTheme(for page: HeartQuotePage, image: UIImage?) -> FeaturedBackgroundTheme {
        guard let image, let extractedTheme = makeExtractedBackgroundTheme(from: image, seed: stableSeed(for: page.videoURL)) else {
            return backgroundTheme(for: page)
        }

        generatedBackgroundThemes[page.videoURL] = extractedTheme
        return extractedTheme
    }

    private func makeExtractedBackgroundTheme(from image: UIImage, seed: UInt64) -> FeaturedBackgroundTheme? {
        guard let baseColor = averageColor(in: image),
              let accentColor = averageColor(in: image, normalizedRect: CGRect(x: 0.22, y: 0.14, width: 0.56, height: 0.44)) else {
            return nil
        }

        let normalizedBase = baseColor.normalizedForBackground(minSaturation: 0.22, brightnessRange: 0.28...0.52)
        let normalizedAccent = accentColor.normalizedForBackground(minSaturation: 0.38, brightnessRange: 0.48...0.76)
        let deepColor = normalizedBase.mixed(with: .black, amount: 0.54)
        let midColor = normalizedAccent.mixed(with: normalizedBase, amount: 0.34)
        let tailColor = deepColor.mixed(with: .black, amount: 0.24)

        return FeaturedBackgroundTheme(
            backgroundColors: [deepColor, midColor, tailColor],
            glowColors: [
                normalizedAccent.withAlphaComponent(0.40),
                normalizedBase.withAlphaComponent(0.18),
                UIColor.clear
            ],
            dimColor: tailColor.mixed(with: .black, amount: 0.16).withAlphaComponent(0.64),
            bottomFadeColor: tailColor.withAlphaComponent(0.90),
            glowCenter: glowCenter(seed: seed)
        )
    }

    private func makeFallbackBackgroundTheme(seed: UInt64) -> FeaturedBackgroundTheme {
        let primaryHue = CGFloat(seed % 360) / 360
        let secondaryHue = CGFloat((seed / 7) % 360) / 360
        let primary = UIColor(hue: primaryHue, saturation: 0.36, brightness: 0.34, alpha: 1)
        let secondary = UIColor(hue: secondaryHue, saturation: 0.46, brightness: 0.48, alpha: 1)
        let deepColor = primary.mixed(with: .black, amount: 0.52)
        let midColor = secondary.mixed(with: primary, amount: 0.30)
        let tailColor = deepColor.mixed(with: .black, amount: 0.20)

        return FeaturedBackgroundTheme(
            backgroundColors: [deepColor, midColor, tailColor],
            glowColors: [
                secondary.withAlphaComponent(0.34),
                primary.withAlphaComponent(0.16),
                UIColor.clear
            ],
            dimColor: tailColor.withAlphaComponent(0.64),
            bottomFadeColor: tailColor.withAlphaComponent(0.90),
            glowCenter: glowCenter(seed: seed)
        )
    }

    private func stableSeed(for url: URL) -> UInt64 {
        url.absoluteString.utf8.reduce(5381) { seed, byte in
            ((seed << 5) &+ seed) &+ UInt64(byte)
        }
    }

    private func glowCenter(seed: UInt64) -> CGPoint {
        let x = 0.18 + CGFloat(seed % 46) / 100
        let y = 0.12 + CGFloat((seed / 17) % 18) / 100
        return CGPoint(x: min(max(x, 0.18), 0.68), y: min(max(y, 0.12), 0.30))
    }

    private func averageColor(in image: UIImage, normalizedRect: CGRect? = nil) -> UIColor? {
        guard let ciImage = CIImage(image: image) else { return nil }

        let extent = ciImage.extent
        let sampleRect: CGRect
        if let normalizedRect {
            sampleRect = CGRect(
                x: extent.minX + (normalizedRect.minX * extent.width),
                y: extent.minY + (normalizedRect.minY * extent.height),
                width: normalizedRect.width * extent.width,
                height: normalizedRect.height * extent.height
            ).intersection(extent)
        } else {
            sampleRect = extent
        }

        guard !sampleRect.isNull, !sampleRect.isEmpty else { return nil }

        let filter = CIFilter.areaAverage()
        filter.inputImage = ciImage
        filter.extent = sampleRect

        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        colorAnalysisContext.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        return UIColor(
            red: CGFloat(bitmap[0]) / 255,
            green: CGFloat(bitmap[1]) / 255,
            blue: CGFloat(bitmap[2]) / 255,
            alpha: 1
        )
    }

    private func updateBackgroundImage(for page: HeartQuotePage, animated: Bool) {
        guard currentBackgroundVideoURL != page.videoURL else { return }
        currentBackgroundVideoURL = page.videoURL
        backgroundImageTask?.cancel()

        backgroundImageTask = Task { [weak self] in
            guard let self else { return }
            let image = await VideoThumbnailLoader.shared.loadThumbnail(for: page.videoURL)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard self.currentBackgroundVideoURL == page.videoURL else { return }
                let resolvedTheme = self.storeExtractedBackgroundTheme(for: page, image: image)

                let applyImage = {
                    self.backgroundImageView.image = image
                }

                guard animated else {
                    applyImage()
                    return
                }

                self.applyResolvedBackgroundTheme(resolvedTheme, animated: true)
                UIView.transition(
                    with: self.backgroundImageView,
                    duration: self.backgroundTransitionDuration,
                    options: [.transitionCrossDissolve, .beginFromCurrentState],
                    animations: applyImage
                )
            }
        }
    }

    private func applyResolvedBackgroundTheme(_ theme: FeaturedBackgroundTheme, animated: Bool) {
        updateGradientLayer(backgroundGradientLayer, colors: theme.backgroundColors.map(\.cgColor), animated: animated)
        updateGradientLayer(backgroundGlowLayer, colors: theme.glowColors.map(\.cgColor), animated: animated)
        backgroundGlowLayer.startPoint = theme.glowCenter
        UIView.animate(withDuration: animated ? backgroundTransitionDuration : 0, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState]) {
            self.dimView.backgroundColor = theme.dimColor
            self.view.backgroundColor = theme.backgroundColors.last
        }
        updateGradientLayer(bottomGradientLayer, colors: [UIColor.clear.cgColor, theme.bottomFadeColor.cgColor], animated: animated)
    }
}

// MARK: - UICollectionViewDataSource

extension LibraryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        totalCarouselItems
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HeartQuoteHeroCell.reuseIdentifier, for: indexPath) as? HeartQuoteHeroCell else {
            return UICollectionViewCell()
        }
        cell.configure(page: featuredPages[logicalIndex(forCarouselItem: indexPath.item)])
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension LibraryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showDetail(page: featuredPages[logicalIndex(forCarouselItem: indexPath.item)])
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView === carouselCollectionView {
            isCarouselScrollInteracting = true
            stopCarouselTimer()
            idleCacheTask?.cancel()
        } else if scrollView === self.scrollView {
            isPrimaryScrollInteracting = true
            idleCacheTask?.cancel()
        }
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView === carouselCollectionView,
              let targetItem = nearestCarouselItemIndex(for: targetContentOffset.pointee.x),
              let layout = carouselCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }

        let stride = layout.itemSize.width + layout.minimumLineSpacing
        let targetOffsetX = (CGFloat(targetItem) * stride) - (carouselCollectionView.bounds.width - layout.itemSize.width) / 2
        targetContentOffset.pointee.x = targetOffsetX
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView === carouselCollectionView {
            guard !decelerate else { return }
            isCarouselScrollInteracting = false
            updateCarouselIndexFromScrollPosition(animated: false)
            startCarouselTimerIfNeeded()
            armIdleCacheTask(after: idleCacheResumeDelay)
        } else if scrollView === self.scrollView, !decelerate {
            isPrimaryScrollInteracting = false
            armIdleCacheTask(after: idleCacheResumeDelay)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView === carouselCollectionView {
            isCarouselScrollInteracting = false
            updateCarouselIndexFromScrollPosition(animated: true)
            startCarouselTimerIfNeeded()
            armIdleCacheTask(after: idleCacheResumeDelay)
        } else if scrollView === self.scrollView {
            isPrimaryScrollInteracting = false
            armIdleCacheTask(after: idleCacheResumeDelay)
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if scrollView === carouselCollectionView {
            updateCarouselIndexFromScrollPosition(animated: true)
        }
    }
}

// MARK: - Scroll Handling

extension LibraryViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === self.scrollView {
            let y = max(scrollView.contentOffset.y, 0)
            backgroundImageView.alpha = max(0.16, 0.30 - (y / 1100))
        } else if scrollView === carouselCollectionView {
            updateCarouselCardEmphasis()
        }
    }

    private func updateCarouselIndexFromScrollPosition(animated: Bool) {
        guard let nearestItem = nearestCarouselItemIndex(for: carouselCollectionView.contentOffset.x) else { return }
        currentCarouselItem = nearestItem
        updateSelectedFeaturedPage(logicalIndex: logicalIndex(forCarouselItem: nearestItem), animated: animated)
        updateCarouselCardEmphasis()
        normalizeCarouselPositionIfNeeded()
    }
}

// MARK: - Views

private final class HeartQuoteHeroCell: UICollectionViewCell {

    static let reuseIdentifier = "HeartQuoteHeroCell"

    private let backCardRear = UIView()
    private let backCardFront = UIView()
    private let cardContainerView = UIView()
    private let imageView = VideoThumbnailImageView()
    private let gradientView = UIView()
    private let gradientLayer = CAGradientLayer()
    private let badgeLabel = InsetLabel()
    private let titleLabel = UILabel()

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
        gradientLayer.frame = gradientView.bounds
    }

    func configure(page: HeartQuotePage) {
        imageView.configure(videoURL: page.videoURL)
        titleLabel.text = page.title
        badgeLabel.text = page.badgeText
        badgeLabel.isHidden = page.badgeText == nil
    }

    private func configure() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.22
        layer.shadowRadius = 18
        layer.shadowOffset = CGSize(width: 0, height: 12)

        [backCardRear, backCardFront].forEach { backCard in
            backCard.layer.cornerRadius = 18
            backCard.layer.cornerCurve = .continuous
            backCard.backgroundColor = UIColor.black.withAlphaComponent(0.88)
            contentView.addSubview(backCard)
            backCard.translatesAutoresizingMaskIntoConstraints = false
        }

        backCardFront.backgroundColor = UIColor.black.withAlphaComponent(0.96)

        cardContainerView.layer.cornerRadius = 20
        cardContainerView.layer.cornerCurve = .continuous
        cardContainerView.layer.masksToBounds = true
        cardContainerView.layer.borderWidth = 1
        cardContainerView.layer.borderColor = UIColor.white.withAlphaComponent(0.46).cgColor
        cardContainerView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        contentView.addSubview(cardContainerView)
        cardContainerView.translatesAutoresizingMaskIntoConstraints = false

        cardContainerView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0.02).cgColor,
            UIColor.black.withAlphaComponent(0.18).cgColor,
            UIColor.black.withAlphaComponent(0.74).cgColor
        ]
        gradientLayer.locations = [0, 0.48, 1]
        gradientView.layer.addSublayer(gradientLayer)
        cardContainerView.addSubview(gradientView)
        gradientView.translatesAutoresizingMaskIntoConstraints = false

        badgeLabel.font = UIFont.systemFont(ofSize: 10, weight: .black)
        badgeLabel.textColor = UIColor(red: 1.0, green: 0.88, blue: 0.66, alpha: 1)
        badgeLabel.backgroundColor = UIColor.black.withAlphaComponent(0.42)
        badgeLabel.layer.cornerRadius = 8
        badgeLabel.layer.cornerCurve = .continuous
        badgeLabel.clipsToBounds = true

        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .black)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2

        cardContainerView.addSubview(badgeLabel)
        cardContainerView.addSubview(titleLabel)
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backCardRear.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            backCardRear.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            backCardRear.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backCardRear.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            backCardFront.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            backCardFront.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            backCardFront.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            backCardFront.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),

            cardContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            imageView.topAnchor.constraint(equalTo: cardContainerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: cardContainerView.bottomAnchor),

            gradientView.topAnchor.constraint(equalTo: cardContainerView.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: cardContainerView.bottomAnchor),

            badgeLabel.topAnchor.constraint(equalTo: cardContainerView.topAnchor, constant: 12),
            badgeLabel.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor, constant: 12),

            titleLabel.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor, constant: 13),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: cardContainerView.trailingAnchor, constant: -13),
            titleLabel.bottomAnchor.constraint(equalTo: cardContainerView.bottomAnchor, constant: -14)
        ])
    }

    func applyEmphasis(distanceRatio: CGFloat) {
        let clampedRatio = max(0, min(distanceRatio, 1))
        let focus = 1 - clampedRatio
        let scale = 0.82 + (focus * 0.22)
        let lift = 12 * clampedRatio

        transform = CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: 0, y: lift)
        layer.shadowOpacity = Float(0.08 + (focus * 0.28))
        layer.shadowRadius = 10 + (focus * 18)
        layer.zPosition = focus * 12

        backCardRear.alpha = 0.18 + (focus * 0.56)
        backCardFront.alpha = 0.36 + (focus * 0.54)
        cardContainerView.layer.borderColor = UIColor.white.withAlphaComponent(0.28 + (focus * 0.36)).cgColor
        badgeLabel.alpha = badgeLabel.isHidden ? 0 : 0.66 + (focus * 0.34)
        titleLabel.alpha = 0.78 + (focus * 0.22)
    }
}

private final class HeartQuoteSectionView: UIView {

    private let section: HeartQuoteSection
    private weak var target: AnyObject?
    private let action: Selector
    private let chapterNumber: Int

    init(section: HeartQuoteSection, chapterNumber: Int, target: AnyObject, action: Selector) {
        self.section = section
        self.target = target
        self.action = action
        self.chapterNumber = chapterNumber
        super.init(frame: .zero)
        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        guard !section.items.isEmpty else { return }

        let chapterLabel = UILabel()
        chapterLabel.text = String(format: "%02d", chapterNumber)
        chapterLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .bold)
        chapterLabel.textColor = UIColor(red: 1.0, green: 0.86, blue: 0.62, alpha: 0.92)

        let dividerView = UIView()
        dividerView.backgroundColor = UIColor.white.withAlphaComponent(0.18)

        let titleLabel = UILabel()
        titleLabel.text = section.title
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .black)
        titleLabel.textColor = .white

        let countLabel = UILabel()
        countLabel.text = section.countText
        countLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        countLabel.textColor = UIColor.white.withAlphaComponent(0.58)

        let titleStack = UIStackView(arrangedSubviews: [titleLabel, countLabel])
        titleStack.axis = .vertical
        titleStack.alignment = .leading
        titleStack.spacing = 3

        let chapterStack = UIStackView(arrangedSubviews: [chapterLabel, dividerView, titleStack])
        chapterStack.axis = .horizontal
        chapterStack.alignment = .center
        chapterStack.spacing = 10

        let galleryStack = UIStackView()
        galleryStack.axis = .horizontal
        galleryStack.spacing = 12
        galleryStack.alignment = .fill
        galleryStack.distribution = .fill

        let primaryCard = HeartQuoteSmallCardView(page: section.items[0], style: .cover)
        primaryCard.addGestureRecognizer(HeartQuoteCardTapGestureRecognizer(page: section.items[0], target: target, action: action))
        galleryStack.addArrangedSubview(primaryCard)

        let sideStack = UIStackView()
        sideStack.axis = .vertical
        sideStack.spacing = 12
        sideStack.distribution = .fillEqually

        section.items.dropFirst().prefix(2).forEach { page in
            let cardView = HeartQuoteSmallCardView(page: page, style: .chapter)
            cardView.addGestureRecognizer(HeartQuoteCardTapGestureRecognizer(page: page, target: target, action: action))
            sideStack.addArrangedSubview(cardView)
        }

        if sideStack.arrangedSubviews.isEmpty {
            sideStack.isHidden = true
        }

        galleryStack.addArrangedSubview(sideStack)

        let contentStack = UIStackView(arrangedSubviews: [chapterStack, galleryStack])
        contentStack.axis = .vertical
        contentStack.spacing = 10
        addSubview(contentStack)

        chapterLabel.translatesAutoresizingMaskIntoConstraints = false
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        primaryCard.translatesAutoresizingMaskIntoConstraints = false
        sideStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),

            dividerView.widthAnchor.constraint(equalToConstant: 34),
            dividerView.heightAnchor.constraint(equalToConstant: 1),

            galleryStack.heightAnchor.constraint(equalToConstant: 188),
            primaryCard.widthAnchor.constraint(equalTo: galleryStack.widthAnchor, multiplier: 0.58),
            sideStack.widthAnchor.constraint(equalTo: galleryStack.widthAnchor, multiplier: 0.34)
        ])
    }
}

private final class HeartQuoteSmallCardView: UIView {

    enum Style {
        case cover
        case chapter
    }

    private let style: Style
    private let imageView = VideoThumbnailImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let gradientView = UIView()
    private let gradientLayer = CAGradientLayer()

    init(page: HeartQuotePage, style: Style = .chapter) {
        self.style = style
        super.init(frame: .zero)
        configure()
        apply(page: page)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = gradientView.bounds
    }

    private func apply(page: HeartQuotePage) {
        imageView.configure(videoURL: page.videoURL)
        titleLabel.text = page.title
        subtitleLabel.text = page.subtitle
        subtitleLabel.isHidden = false
        accessibilityLabel = page.title
    }

    private func configure() {
        let isCover = style == .cover

        layer.cornerRadius = isCover ? 16 : 12
        layer.cornerCurve = .continuous
        clipsToBounds = true
        backgroundColor = UIColor.white.withAlphaComponent(isCover ? 0.08 : 0.06)
        isUserInteractionEnabled = true
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(isCover ? 0.26 : 0.16).cgColor

        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(isCover ? 0.18 : 0.08).cgColor,
            UIColor.black.withAlphaComponent(isCover ? 0.78 : 0.70).cgColor
        ]
        gradientLayer.locations = [0, 0.48, 1]
        gradientView.layer.addSublayer(gradientLayer)
        addSubview(gradientView)
        gradientView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = UIFont.systemFont(ofSize: isCover ? 15 : 11, weight: .black)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2

        subtitleLabel.font = UIFont.systemFont(ofSize: isCover ? 10 : 8, weight: .semibold)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(isCover ? 0.76 : 0.68)
        subtitleLabel.numberOfLines = isCover ? 3 : 2

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = isCover ? 4 : 2
        addSubview(textStack)
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let horizontalInset: CGFloat = isCover ? 13 : 8
        let bottomInset: CGFloat = isCover ? 13 : 8

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            gradientView.topAnchor.constraint(equalTo: topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: bottomAnchor),

            textStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalInset),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalInset),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -bottomInset)
        ])
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
        backgroundColor = UIColor.white.withAlphaComponent(0.06)
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
            guard let self else { return }
            let thumbnail = await VideoThumbnailLoader.shared.loadThumbnail(for: videoURL)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard self.videoURL == videoURL else { return }
                self.image = thumbnail
            }
        }
    }

    deinit {
        thumbnailTask?.cancel()
    }
}

private final class HeartQuoteCardTapGestureRecognizer: UITapGestureRecognizer {
    let page: HeartQuotePage

    init(page: HeartQuotePage, target: AnyObject?, action: Selector?) {
        self.page = page
        super.init(target: target, action: action)
    }
}

private final class InsetLabel: UILabel {

    private let insets: UIEdgeInsets

    init(top: CGFloat = 5, left: CGFloat = 10, bottom: CGFloat = 5, right: CGFloat = 10) {
        insets = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
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

    func normalizedForBackground(minSaturation: CGFloat, brightnessRange: ClosedRange<CGFloat>) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return UIColor(
                hue: hue,
                saturation: max(saturation, minSaturation),
                brightness: min(max(brightness, brightnessRange.lowerBound), brightnessRange.upperBound),
                alpha: 1
            )
        }

        var white: CGFloat = 0
        if getWhite(&white, alpha: &alpha) {
            let clamped = min(max(white, brightnessRange.lowerBound), brightnessRange.upperBound)
            return UIColor(white: clamped, alpha: 1)
        }

        return self
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
