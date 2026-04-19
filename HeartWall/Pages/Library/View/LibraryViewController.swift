//
//  LibraryViewController.swift
//  HeartWall
//

import UIKit
import Combine

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
    private var carouselTimer: Timer?
    private var currentCarouselIndex = 0
    private var currentCarouselItem = 0
    private var appliedFeaturedLogicalIndex: Int?
    private var currentBackgroundAssetName: String?
    private let carouselLoopMultiplier = 400

    private let headerHeight: CGFloat = 84
    private let contentHorizontalInset: CGFloat = 16
    private let tabBarReservedHeight: CGFloat = 112

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
    private let featuredSummaryLabel = UILabel()
    private let featuredTagStackView = UIStackView()
    private let bottomFadeView = UIView()
    private let bottomGradientLayer = CAGradientLayer()
    private let backgroundTransitionDuration: CFTimeInterval = 0.78

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
        startCarouselTimerIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCarouselTimer()
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
    }

    // MARK: - Configuration

    private func configureBackground() {
        backgroundImageView.image = UIImage(named: "HeartQuotePagePrimary")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.alpha = 0.22
        view.addSubview(backgroundImageView)
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false

        backgroundGradientLayer.startPoint = CGPoint(x: 0.15, y: 0)
        backgroundGradientLayer.endPoint = CGPoint(x: 0.88, y: 1)
        backgroundGradientLayer.colors = backgroundTheme(for: 0).backgroundColors.map(\.cgColor)
        backgroundGradientView.layer.addSublayer(backgroundGradientLayer)
        view.addSubview(backgroundGradientView)
        backgroundGradientView.translatesAutoresizingMaskIntoConstraints = false

        backgroundGlowLayer.type = .radial
        backgroundGlowLayer.startPoint = backgroundTheme(for: 0).glowCenter
        backgroundGlowLayer.endPoint = CGPoint(x: 1, y: 1)
        backgroundGlowLayer.colors = backgroundTheme(for: 0).glowColors.map(\.cgColor)
        backgroundGlowView.alpha = 0.9
        backgroundGlowView.layer.addSublayer(backgroundGlowLayer)
        view.addSubview(backgroundGlowView)
        backgroundGlowView.translatesAutoresizingMaskIntoConstraints = false

        dimView.backgroundColor = backgroundTheme(for: 0).dimColor
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
        stackView.spacing = 18
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

        featuredSummaryLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        featuredSummaryLabel.textColor = UIColor.white.withAlphaComponent(0.74)
        featuredSummaryLabel.textAlignment = .center
        featuredSummaryLabel.numberOfLines = 2

        featuredTagStackView.axis = .horizontal
        featuredTagStackView.alignment = .center
        featuredTagStackView.spacing = 8
        featuredTagStackView.distribution = .fillProportionally

        let container = UIView()
        container.clipsToBounds = false
        container.addSubview(carouselCollectionView)
        container.addSubview(featuredSummaryLabel)
        container.addSubview(featuredTagStackView)
        carouselCollectionView.translatesAutoresizingMaskIntoConstraints = false
        featuredSummaryLabel.translatesAutoresizingMaskIntoConstraints = false
        featuredTagStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            carouselCollectionView.topAnchor.constraint(equalTo: container.topAnchor),
            carouselCollectionView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            carouselCollectionView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            carouselCollectionView.heightAnchor.constraint(equalToConstant: 270),

            featuredSummaryLabel.topAnchor.constraint(equalTo: carouselCollectionView.bottomAnchor, constant: 14),
            featuredSummaryLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 42),
            featuredSummaryLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -42),

            featuredTagStackView.topAnchor.constraint(equalTo: featuredSummaryLabel.bottomAnchor, constant: 10),
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
        dayLabel.font = UIFont.systemFont(ofSize: 28, weight: .black)
        dayLabel.textColor = .white

        greetingLabel.text = currentGreetingText()
        greetingLabel.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        greetingLabel.textColor = .white

        subtitleLabel.text = "今日心语"
        subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.72)

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
        appBadgeTextLabel.font = UIFont.systemFont(ofSize: 16, weight: .black)
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
            topHeaderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            topHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: contentHorizontalInset),
            topHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -contentHorizontalInset),
            topHeaderView.heightAnchor.constraint(equalToConstant: 68),

            dateStack.leadingAnchor.constraint(equalTo: topHeaderView.leadingAnchor),
            dateStack.centerYAnchor.constraint(equalTo: topHeaderView.centerYAnchor, constant: 2),

            greetingStack.leadingAnchor.constraint(equalTo: dateStack.trailingAnchor, constant: 14),
            greetingStack.centerYAnchor.constraint(equalTo: topHeaderView.centerYAnchor, constant: 2),
            greetingStack.trailingAnchor.constraint(lessThanOrEqualTo: appBadgeView.leadingAnchor, constant: -12),

            appBadgeView.trailingAnchor.constraint(equalTo: topHeaderView.trailingAnchor),
            appBadgeView.centerYAnchor.constraint(equalTo: topHeaderView.centerYAnchor, constant: 2),
            appBadgeView.widthAnchor.constraint(equalToConstant: 30),
            appBadgeView.heightAnchor.constraint(equalToConstant: 30),

            appBadgeTextLabel.centerXAnchor.constraint(equalTo: appBadgeView.centerXAnchor),
            appBadgeTextLabel.centerYAnchor.constraint(equalTo: appBadgeView.centerYAnchor)
        ])
    }

    private func configureBottomFade() {
        bottomGradientLayer.colors = [
            UIColor.clear.cgColor,
            backgroundTheme(for: 0).bottomFadeColor.cgColor
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
        currentBackgroundAssetName = nil
        carouselCollectionView.reloadData()
        view.layoutIfNeeded()
        scrollCarousel(toItem: currentCarouselItem, animated: false)
        startCarouselTimerIfNeeded()
    }

    private func renderSections(_ sections: [HeartQuoteSection]) {
        stackView.arrangedSubviews.dropFirst().forEach { arrangedView in
            stackView.removeArrangedSubview(arrangedView)
            arrangedView.removeFromSuperview()
        }

        sections.forEach { section in
            stackView.addArrangedSubview(HeartQuoteSectionView(section: section, target: self, action: #selector(handleCardTap(_:))))
        }
    }

    private func updateCarouselLayout() {
        guard let layout = carouselCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let availableWidth = max(0, view.bounds.width)
        layout.minimumLineSpacing = 4
        let itemWidth = min(216, max(190, availableWidth * 0.535))
        let itemHeight = min(264, max(238, itemWidth * 1.23))
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
        showDetail(title: sender.page.title)
    }

    private func showDetail(title: String) {
        let detailViewController = HeartQuoteDetailViewController(titleText: title)
        detailViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailViewController, animated: true)
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

        page.tags.forEach { tag in
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
        let theme = backgroundTheme(for: logicalIndex)

        updateGradientLayer(backgroundGradientLayer, colors: theme.backgroundColors.map(\.cgColor), animated: animated)
        updateGradientLayer(backgroundGlowLayer, colors: theme.glowColors.map(\.cgColor), animated: animated)
        backgroundGlowLayer.startPoint = theme.glowCenter
        UIView.animate(withDuration: animated ? backgroundTransitionDuration : 0, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState]) {
            self.dimView.backgroundColor = theme.dimColor
            self.view.backgroundColor = theme.backgroundColors.last
        }
        updateGradientLayer(bottomGradientLayer, colors: [UIColor.clear.cgColor, theme.bottomFadeColor.cgColor], animated: animated)

        guard currentBackgroundAssetName != page.assetName else { return }
        currentBackgroundAssetName = page.assetName

        let nextImage = UIImage(named: page.assetName)
        guard animated else {
            backgroundImageView.image = nextImage
            return
        }

        UIView.transition(with: backgroundImageView, duration: backgroundTransitionDuration, options: [.transitionCrossDissolve, .beginFromCurrentState]) {
            self.backgroundImageView.image = nextImage
        }
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

    private func backgroundTheme(for logicalIndex: Int) -> FeaturedBackgroundTheme {
        switch logicalIndex {
        case 0:
            return FeaturedBackgroundTheme(
                backgroundColors: [
                    UIColor(red: 0.27, green: 0.26, blue: 0.30, alpha: 1),
                    UIColor(red: 0.44, green: 0.31, blue: 0.20, alpha: 1),
                    UIColor(red: 0.12, green: 0.11, blue: 0.12, alpha: 1)
                ],
                glowColors: [
                    UIColor(red: 0.91, green: 0.72, blue: 0.45, alpha: 0.46),
                    UIColor(red: 0.72, green: 0.48, blue: 0.28, alpha: 0.18),
                    UIColor.clear
                ],
                dimColor: UIColor(red: 0.09, green: 0.09, blue: 0.10, alpha: 0.62),
                bottomFadeColor: UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 0.88),
                glowCenter: CGPoint(x: 0.22, y: 0.18)
            )
        case 1:
            return FeaturedBackgroundTheme(
                backgroundColors: [
                    UIColor(red: 0.12, green: 0.19, blue: 0.23, alpha: 1),
                    UIColor(red: 0.30, green: 0.32, blue: 0.19, alpha: 1),
                    UIColor(red: 0.08, green: 0.10, blue: 0.12, alpha: 1)
                ],
                glowColors: [
                    UIColor(red: 0.56, green: 0.70, blue: 0.46, alpha: 0.38),
                    UIColor(red: 0.76, green: 0.62, blue: 0.34, alpha: 0.16),
                    UIColor.clear
                ],
                dimColor: UIColor(red: 0.08, green: 0.10, blue: 0.12, alpha: 0.64),
                bottomFadeColor: UIColor(red: 0.08, green: 0.10, blue: 0.11, alpha: 0.90),
                glowCenter: CGPoint(x: 0.78, y: 0.20)
            )
        default:
            return FeaturedBackgroundTheme(
                backgroundColors: [
                    UIColor(red: 0.15, green: 0.14, blue: 0.24, alpha: 1),
                    UIColor(red: 0.39, green: 0.23, blue: 0.22, alpha: 1),
                    UIColor(red: 0.08, green: 0.07, blue: 0.10, alpha: 1)
                ],
                glowColors: [
                    UIColor(red: 0.92, green: 0.54, blue: 0.31, alpha: 0.38),
                    UIColor(red: 0.62, green: 0.41, blue: 0.78, alpha: 0.16),
                    UIColor.clear
                ],
                dimColor: UIColor(red: 0.07, green: 0.07, blue: 0.10, alpha: 0.66),
                bottomFadeColor: UIColor(red: 0.08, green: 0.07, blue: 0.10, alpha: 0.90),
                glowCenter: CGPoint(x: 0.52, y: 0.10)
            )
        }
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
        showDetail(title: featuredPages[logicalIndex(forCarouselItem: indexPath.item)].title)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView === carouselCollectionView {
            stopCarouselTimer()
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
        guard scrollView === carouselCollectionView, !decelerate else { return }
        updateCarouselIndexFromScrollPosition(animated: false)
        startCarouselTimerIfNeeded()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView === carouselCollectionView {
            updateCarouselIndexFromScrollPosition(animated: true)
            startCarouselTimerIfNeeded()
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
    private let imageView = CroppedAssetImageView()
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
        imageView.configure(assetName: page.assetName, cropRect: page.cropRect)
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
        layer.shadowOffset = CGSize(width: 0, height: 10)

        [backCardRear, backCardFront].forEach { backCard in
            backCard.layer.cornerRadius = 26
            backCard.layer.cornerCurve = .continuous
            backCard.backgroundColor = UIColor.black.withAlphaComponent(0.88)
            contentView.addSubview(backCard)
            backCard.translatesAutoresizingMaskIntoConstraints = false
        }

        backCardFront.backgroundColor = UIColor.black.withAlphaComponent(0.96)

        cardContainerView.layer.cornerRadius = 28
        cardContainerView.layer.cornerCurve = .continuous
        cardContainerView.layer.masksToBounds = true
        cardContainerView.layer.borderWidth = 1
        cardContainerView.layer.borderColor = UIColor.white.withAlphaComponent(0.55).cgColor
        cardContainerView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        contentView.addSubview(cardContainerView)
        cardContainerView.translatesAutoresizingMaskIntoConstraints = false

        imageView.contentMode = .scaleAspectFill
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

        badgeLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        badgeLabel.textColor = .white
        badgeLabel.backgroundColor = UIColor(white: 0.22, alpha: 0.54)
        badgeLabel.layer.cornerRadius = 10
        badgeLabel.layer.cornerCurve = .continuous
        badgeLabel.clipsToBounds = true

        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .heavy)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2

        cardContainerView.addSubview(badgeLabel)
        cardContainerView.addSubview(titleLabel)
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backCardRear.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            backCardRear.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 26),
            backCardRear.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backCardRear.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            backCardFront.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            backCardFront.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            backCardFront.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            backCardFront.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            cardContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
            cardContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            imageView.topAnchor.constraint(equalTo: cardContainerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: cardContainerView.bottomAnchor),

            gradientView.topAnchor.constraint(equalTo: cardContainerView.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: cardContainerView.bottomAnchor),

            badgeLabel.topAnchor.constraint(equalTo: cardContainerView.topAnchor, constant: 14),
            badgeLabel.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor, constant: 12),

            titleLabel.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: cardContainerView.trailingAnchor, constant: -14),
            titleLabel.bottomAnchor.constraint(equalTo: cardContainerView.bottomAnchor, constant: -16)
        ])
    }

    func applyEmphasis(distanceRatio: CGFloat) {
        let clampedRatio = max(0, min(distanceRatio, 1))
        let focus = 1 - clampedRatio
        let scale = 0.80 + (focus * 0.28)
        let lift = 14 * clampedRatio

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

    init(section: HeartQuoteSection, target: AnyObject, action: Selector) {
        self.section = section
        self.target = target
        self.action = action
        super.init(frame: .zero)
        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        let titleLabel = UILabel()
        titleLabel.text = section.title
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .white

        let countLabel = UILabel()
        countLabel.text = section.countText + "  >"
        countLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        countLabel.textColor = UIColor.white.withAlphaComponent(0.70)

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, UIView(), countLabel])
        headerStack.axis = .horizontal
        headerStack.alignment = .center

        let cardStack = UIStackView()
        cardStack.axis = .horizontal
        cardStack.spacing = 10
        cardStack.distribution = .fillEqually

        section.items.forEach { page in
            let cardView = HeartQuoteSmallCardView(page: page)
            cardView.addGestureRecognizer(HeartQuoteCardTapGestureRecognizer(page: page, target: target, action: action))
            cardStack.addArrangedSubview(cardView)
        }

        let contentStack = UIStackView(arrangedSubviews: [headerStack, cardStack])
        contentStack.axis = .vertical
        contentStack.spacing = 12
        addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),

            cardStack.heightAnchor.constraint(equalToConstant: 172)
        ])
    }
}

private final class HeartQuoteSmallCardView: UIView {

    private let imageView = CroppedAssetImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let gradientView = UIView()
    private let gradientLayer = CAGradientLayer()

    init(page: HeartQuotePage) {
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
        imageView.configure(assetName: page.assetName, cropRect: page.cropRect)
        titleLabel.text = page.title
        subtitleLabel.text = nil
        accessibilityLabel = page.title
    }

    private func configure() {
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        clipsToBounds = true
        backgroundColor = UIColor.white.withAlphaComponent(0.08)
        isUserInteractionEnabled = true

        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.72).cgColor
        ]
        gradientLayer.locations = [0, 1]
        gradientView.layer.addSublayer(gradientLayer)
        addSubview(gradientView)
        gradientView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2

        subtitleLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.76)
        subtitleLabel.numberOfLines = 2
        subtitleLabel.isHidden = true

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        addSubview(textStack)
        textStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            gradientView.topAnchor.constraint(equalTo: topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: bottomAnchor),

            textStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }
}

private final class CroppedAssetImageView: UIImageView {

    private var assetName: String?
    private var cropRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)

    func configure(assetName: String, cropRect: CGRect) {
        self.assetName = assetName
        self.cropRect = cropRect
        image = UIImage(named: assetName)?.cropped(toNormalizedRect: cropRect)
        contentMode = .scaleAspectFill
        clipsToBounds = true
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

private extension UIImage {
    func cropped(toNormalizedRect normalizedRect: CGRect) -> UIImage {
        let safeRect = normalizedRect.intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
        guard safeRect.width > 0, safeRect.height > 0, let cgImage else { return self }

        let pixelRect = CGRect(
            x: safeRect.minX * size.width * scale,
            y: safeRect.minY * size.height * scale,
            width: safeRect.width * size.width * scale,
            height: safeRect.height * size.height * scale
        ).integral

        guard let croppedImage = cgImage.cropping(to: pixelRect) else { return self }
        return UIImage(cgImage: croppedImage, scale: scale, orientation: imageOrientation)
    }
}
