//
//  SubscriptionViewController.swift
//  HeartWall
//

import UIKit

final class SubscriptionViewController: BaseViewController {

    enum Source {
        case appLaunch
        case modal
    }

    private enum CarouselConfig {
        static let loopMultiplier = 120
        static let autoScrollInterval: TimeInterval = 2.8
    }

    // MARK: - Properties

    private let videoResources = OnboardingVideoResource.allCases

    private lazy var loopedVideoResources: [OnboardingVideoResource] = {
        Array(repeating: videoResources, count: CarouselConfig.loopMultiplier).flatMap { $0 }
    }()

    private var currentLoopIndex: Int
    private var didSetInitialOffset = false
    private var lastKnownCarouselSize: CGSize = .zero
    private var autoScrollTimer: Timer?
    private var isUserInteracting = false
    private var didAnimateContentEntrance = false
    private let source: Source

    // MARK: - UI

    private let backgroundVideoCropView = UIView()
    private let backgroundVideoView = LoopingVideoView()
    private let backgroundDimView = UIView()
    private let carouselLayout = UICollectionViewFlowLayout()

    private lazy var carouselView: UICollectionView = {
        carouselLayout.scrollDirection = .horizontal
        carouselLayout.minimumLineSpacing = 16

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: carouselLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.decelerationRate = .fast
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.clipsToBounds = false
        collectionView.register(VideoCarouselCell.self, forCellWithReuseIdentifier: VideoCarouselCell.reuseIdentifier)
        return collectionView
    }()

    private let closeButton = UIButton(type: .system)
    private let restoreButton = UIButton(type: .system)
    private let bottomOverlayView = BottomRadiantOverlayView()
    private let contentStackView = UIStackView()
    private let benefitStackView = UIStackView()
    private let planTrayView = SubscriptionPlanTrayView()
    private let planStackView = UIStackView()
    private let weeklyPlanButton = SubscriptionPlanButton()
    private let yearlyPlanButton = SubscriptionPlanButton()
    private let trialButton = GradientCapsuleButton()
    private let priceLabel = UILabel()
    private let agreementView = AgreementRowView()
    private var selectedProductID: PremiumAccessStore.ProductID = .weekly

    // MARK: - Lifecycle

    init(videoResource: OnboardingVideoResource, source: Source = .appLaunch) {
        let preferredIndex = min(1, OnboardingVideoResource.allCases.count - 1)
        let middleCycle = max(0, CarouselConfig.loopMultiplier / 2)
        self.currentLoopIndex = (middleCycle * OnboardingVideoResource.allCases.count) + preferredIndex
        self.source = source
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAutoScrollIfNeeded()
        syncCurrentIndexFromScrollPosition()
        refreshVisibleCellState(animated: false)
        animateContentEntranceIfNeeded()
        trialButton.startBreathing()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopAutoScroll()
        backgroundVideoView.pause()
        pauseVisibleCells()
        trialButton.stopBreathing()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCarouselLayoutIfNeeded()

        guard carouselView.bounds.width > 0 else { return }

        if !didSetInitialOffset {
            didSetInitialOffset = true
            carouselView.layoutIfNeeded()
            scrollToLoopIndex(currentLoopIndex, animated: false)
            refreshVisibleCellState(animated: false)
        } else {
            updateCellTransforms()
        }
    }

    // MARK: - Setup

    override func setupUI() {
        view.backgroundColor = .black

        configureTopButtons()
        configureOverlayContent()
        configureBackgroundVideo()

        [backgroundVideoCropView, backgroundDimView, carouselView, bottomOverlayView, closeButton, restoreButton, contentStackView].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        backgroundVideoCropView.addSubview(backgroundVideoView)
        backgroundVideoView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundVideoCropView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundVideoCropView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundVideoCropView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundVideoCropView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            backgroundVideoView.topAnchor.constraint(equalTo: backgroundVideoCropView.topAnchor, constant: -84),
            backgroundVideoView.leadingAnchor.constraint(equalTo: backgroundVideoCropView.leadingAnchor, constant: -96),
            backgroundVideoView.trailingAnchor.constraint(equalTo: backgroundVideoCropView.trailingAnchor, constant: 96),
            backgroundVideoView.bottomAnchor.constraint(equalTo: backgroundVideoCropView.bottomAnchor, constant: 84),

            backgroundDimView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundDimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundDimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundDimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            carouselView.topAnchor.constraint(equalTo: view.topAnchor),
            carouselView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            carouselView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            carouselView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            bottomOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            bottomOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),

            restoreButton.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            restoreButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            contentStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            contentStackView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 78),

            trialButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    private func configureBackgroundVideo() {
        backgroundVideoCropView.clipsToBounds = true
        backgroundDimView.backgroundColor = UIColor.black.withAlphaComponent(0.22)
        syncBackgroundVideo()
    }

    private func configureTopButtons() {
        var closeConfiguration = UIButton.Configuration.plain()
        closeConfiguration.baseForegroundColor = UIColor.white.withAlphaComponent(0.82)
        closeConfiguration.contentInsets = .zero
        closeConfiguration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        closeButton.configuration = closeConfiguration
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        closeButton.layer.cornerRadius = 18
        closeButton.layer.cornerCurve = .continuous
        closeButton.layer.borderWidth = 1
        closeButton.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        closeButton.addTarget(self, action: #selector(handleEnterHome), for: .touchUpInside)

        var restoreConfiguration = UIButton.Configuration.plain()
        restoreConfiguration.attributedTitle = AttributedString(
            L10n.text("subscription.restore"),
            attributes: AttributeContainer([
                .font: UIFont.systemFont(ofSize: 12, weight: .medium)
            ])
        )
        restoreConfiguration.baseForegroundColor = UIColor.white.withAlphaComponent(0.58)
        restoreConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6)
        restoreButton.configuration = restoreConfiguration
        restoreButton.addTarget(self, action: #selector(handleRestore), for: .touchUpInside)
    }

    private func configureOverlayContent() {
        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.spacing = 8

        benefitStackView.axis = .vertical
        benefitStackView.alignment = .fill
        benefitStackView.spacing = 6

        let benefitTexts = [
            L10n.text("subscription.benefit.wallpapers"),
            L10n.text("subscription.benefit.audio"),
            L10n.text("subscription.benefit.features"),
            L10n.text("subscription.benefit.no_ads")
        ]

        for benefitText in benefitTexts {
            benefitStackView.addArrangedSubview(FeatureRowView(text: benefitText))
        }

        trialButton.setTitle(L10n.text("subscription.upgrade_now"), for: .normal)
        trialButton.addTarget(self, action: #selector(handleUpgrade), for: .touchUpInside)

        planStackView.axis = .vertical
        planStackView.alignment = .fill
        planStackView.spacing = 8
        weeklyPlanButton.addTarget(self, action: #selector(handleWeeklyPlanSelection), for: .touchUpInside)
        yearlyPlanButton.addTarget(self, action: #selector(handleYearlyPlanSelection), for: .touchUpInside)
        planTrayView.addContentView(planStackView)
        planStackView.addArrangedSubview(weeklyPlanButton)
        planStackView.addArrangedSubview(yearlyPlanButton)
        refreshPlanButtons()

        priceLabel.text = L10n.text("subscription.price_note")
        priceLabel.font = .systemFont(ofSize: 12, weight: .medium)
        priceLabel.textColor = UIColor.white.withAlphaComponent(0.70)
        priceLabel.textAlignment = .center

        agreementView.configure(text: L10n.text("subscription.agreement"))

        [benefitStackView, planTrayView, trialButton, priceLabel, agreementView].forEach {
            contentStackView.addArrangedSubview($0)
        }

        contentStackView.setCustomSpacing(14, after: benefitStackView)
        contentStackView.setCustomSpacing(12, after: planTrayView)
        contentStackView.setCustomSpacing(8, after: trialButton)
        contentStackView.setCustomSpacing(5, after: priceLabel)
    }

    override func setupBindings() {
        Task { [weak self] in
            await PremiumAccessStore.shared.refreshPurchasedProducts()
            if PremiumAccessStore.shared.isPremium {
                self?.finishSubscriptionFlow()
                return
            }

            do {
                try await PremiumAccessStore.shared.loadProducts()
                self?.refreshPlanButtons()
            } catch {
                self?.refreshPlanButtons()
            }
        }
    }

    // MARK: - Carousel

    private func updateCarouselLayoutIfNeeded() {
        guard carouselView.bounds.size != .zero else { return }
        guard carouselView.bounds.size != lastKnownCarouselSize else { return }

        lastKnownCarouselSize = carouselView.bounds.size

        let itemWidth = carouselView.bounds.width
        let itemHeight = carouselView.bounds.height
        let horizontalInset: CGFloat = 0

        carouselLayout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        carouselLayout.sectionInset = UIEdgeInsets(top: 0, left: horizontalInset, bottom: 0, right: horizontalInset)
        carouselLayout.invalidateLayout()
    }

    private var pageStride: CGFloat {
        carouselLayout.itemSize.width + carouselLayout.minimumLineSpacing
    }

    private func scrollToLoopIndex(_ index: Int, animated: Bool) {
        let targetX = CGFloat(index) * pageStride
        carouselView.setContentOffset(CGPoint(x: targetX, y: 0), animated: animated)
    }

    private func nearestLoopIndex(for contentOffsetX: CGFloat) -> Int {
        guard pageStride > 0 else { return 0 }
        let rawIndex = Int(round(contentOffsetX / pageStride))
        return max(0, min(loopedVideoResources.count - 1, rawIndex))
    }

    private func resource(for loopIndex: Int) -> OnboardingVideoResource {
        let safeIndex = ((loopIndex % videoResources.count) + videoResources.count) % videoResources.count
        return videoResources[safeIndex]
    }

    private func normalizedLoopIndex(_ loopIndex: Int) -> Int {
        guard !videoResources.isEmpty else { return 0 }
        let safeResourceIndex = ((loopIndex % videoResources.count) + videoResources.count) % videoResources.count
        let middleCycle = max(0, CarouselConfig.loopMultiplier / 2)
        return (middleCycle * videoResources.count) + safeResourceIndex
    }

    private func recenterLoopPositionIfNeeded() {
        let normalizedIndex = normalizedLoopIndex(currentLoopIndex)
        guard normalizedIndex != currentLoopIndex else { return }

        currentLoopIndex = normalizedIndex
        scrollToLoopIndex(normalizedIndex, animated: false)
    }

    private func syncCurrentIndexFromScrollPosition() {
        let nextLoopIndex = nearestLoopIndex(for: carouselView.contentOffset.x)
        guard nextLoopIndex != currentLoopIndex else {
            syncBackgroundVideo()
            refreshVisibleCellState(animated: true)
            return
        }

        currentLoopIndex = nextLoopIndex
        syncBackgroundVideo()
        refreshVisibleCellState(animated: true)
    }

    private func syncBackgroundVideo() {
        guard !videoResources.isEmpty else { return }
        guard let url = resource(for: currentLoopIndex).bundleURL() else { return }

        backgroundVideoView.configure(url: url, isMuted: false)
        backgroundVideoView.play()
    }

    private func refreshVisibleCellState(animated: Bool) {
        updateCellTransforms()

        for cell in carouselView.visibleCells.compactMap({ $0 as? VideoCarouselCell }) {
            guard let indexPath = carouselView.indexPath(for: cell) else { continue }
            let shouldPlay = indexPath.item == currentLoopIndex
            shouldPlay ? cell.play() : cell.pause()
            cell.setFocused(indexPath.item == currentLoopIndex, animated: animated)
        }
    }

    private func updateCellTransforms() {
        let visibleCenterX = carouselView.contentOffset.x + carouselView.bounds.width * 0.5

        for cell in carouselView.visibleCells.compactMap({ $0 as? VideoCarouselCell }) {
            let distance = abs(cell.center.x - visibleCenterX)
            let normalizedDistance = min(distance / max(pageStride, 1), 1)
            let focusProgress = 1 - normalizedDistance
            let scale = 0.98 + (focusProgress * 0.02)
            cell.transform = CGAffineTransform(scaleX: scale, y: scale)
            cell.applyFocusProgress(focusProgress)
            cell.layer.zPosition = focusProgress
        }
    }

    private func pauseVisibleCells() {
        for cell in carouselView.visibleCells.compactMap({ $0 as? VideoCarouselCell }) {
            cell.pause()
        }
    }

    private func startAutoScrollIfNeeded() {
        guard autoScrollTimer == nil, videoResources.count > 1 else { return }

        let timer = Timer.scheduledTimer(withTimeInterval: CarouselConfig.autoScrollInterval, repeats: true) { [weak self] _ in
            self?.advanceToNextVideoIfNeeded()
        }
        RunLoop.main.add(timer, forMode: .common)
        autoScrollTimer = timer
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    private func resumeAutoScrollIfNeeded() {
        stopAutoScroll()
        startAutoScrollIfNeeded()
    }

    private func advanceToNextVideoIfNeeded() {
        guard !isUserInteracting else { return }
        guard carouselView.window != nil else { return }

        currentLoopIndex = min(currentLoopIndex + 1, loopedVideoResources.count - 1)
        scrollToLoopIndex(currentLoopIndex, animated: true)
    }

    // MARK: - Actions

    @objc
    private func handleEnterHome() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        backgroundVideoView.pause()
        pauseVisibleCells()

        switch source {
        case .appLaunch:
            guard let navigationController else { return }
            SubscriptionRoute.replaceRootWithLaunch(from: navigationController)
        case .modal:
            dismiss(animated: true)
        }
    }

    @objc
    private func handleRestore() {
        runPurchaseTask {
            let restored = try await PremiumAccessStore.shared.restorePurchases()
            if restored {
                self.finishSubscriptionFlow()
            } else {
                self.presentMessage(
                    title: L10n.text("subscription.restore"),
                    message: L10n.text("subscription.restore.empty")
                )
            }
        }
    }

    @objc
    private func handleUpgrade() {
        purchase(selectedProductID)
    }

    @objc
    private func handleWeeklyPlanSelection() {
        selectProduct(.weekly, animated: true)
    }

    @objc
    private func handleYearlyPlanSelection() {
        selectProduct(.yearly, animated: true)
    }

    // MARK: - Helpers

    private func purchase(_ productID: PremiumAccessStore.ProductID) {
        runPurchaseTask {
            let didPurchase = try await PremiumAccessStore.shared.purchase(productID)
            if didPurchase {
                self.finishSubscriptionFlow()
            }
        }
    }

    private func runPurchaseTask(_ operation: @escaping @MainActor () async throws -> Void) {
        setPurchaseControlsEnabled(false)

        Task { [weak self] in
            guard let self else { return }

            do {
                try await operation()
            } catch {
                self.presentMessage(
                    title: L10n.text("subscription.error.title"),
                    message: error.localizedDescription
                )
            }

            self.setPurchaseControlsEnabled(true)
        }
    }

    private func finishSubscriptionFlow() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        handleEnterHome()
    }

    private func setPurchaseControlsEnabled(_ isEnabled: Bool) {
        [trialButton, restoreButton, weeklyPlanButton, yearlyPlanButton].forEach {
            $0.isEnabled = isEnabled
            $0.alpha = isEnabled ? 1 : 0.62
        }
    }

    private func refreshPlanButtons() {
        let weekly = PremiumAccessStore.shared.productDisplay(for: .weekly)
        let yearly = PremiumAccessStore.shared.productDisplay(for: .yearly)
        weeklyPlanButton.configure(
            title: weekly.title,
            price: weekly.priceText,
            caption: L10n.text("subscription.plan.weekly.caption"),
            isSelected: selectedProductID == .weekly,
            isRecommended: true,
            animated: false
        )
        yearlyPlanButton.configure(
            title: yearly.title,
            price: yearly.priceText,
            caption: L10n.text("subscription.plan.yearly.caption"),
            isSelected: selectedProductID == .yearly,
            isRecommended: false,
            animated: false
        )
    }

    private func selectProduct(_ productID: PremiumAccessStore.ProductID, animated: Bool) {
        guard selectedProductID != productID else {
            animateSelectedPlanConfirmation(for: productID)
            return
        }

        selectedProductID = productID
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        let weekly = PremiumAccessStore.shared.productDisplay(for: .weekly)
        let yearly = PremiumAccessStore.shared.productDisplay(for: .yearly)
        weeklyPlanButton.configure(
            title: weekly.title,
            price: weekly.priceText,
            caption: L10n.text("subscription.plan.weekly.caption"),
            isSelected: productID == .weekly,
            isRecommended: true,
            animated: animated
        )
        yearlyPlanButton.configure(
            title: yearly.title,
            price: yearly.priceText,
            caption: L10n.text("subscription.plan.yearly.caption"),
            isSelected: productID == .yearly,
            isRecommended: false,
            animated: animated
        )
    }

    private func animateSelectedPlanConfirmation(for productID: PremiumAccessStore.ProductID) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let button = productID == .weekly ? weeklyPlanButton : yearlyPlanButton
        let selectedTransform = CGAffineTransform(translationX: 0, y: -1)

        UIView.animate(
            withDuration: 0.12,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseOut]
        ) {
            button.transform = selectedTransform.scaledBy(x: 0.985, y: 0.985)
        } completion: { _ in
            UIView.animate(
                withDuration: 0.24,
                delay: 0,
                usingSpringWithDamping: 0.68,
                initialSpringVelocity: 0.28,
                options: [.beginFromCurrentState, .allowUserInteraction]
            ) {
                button.transform = selectedTransform
            }
        }
    }

    private func presentMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.text("common.ok"), style: .default))
        present(alert, animated: true)
    }

    private func animateContentEntranceIfNeeded() {
        guard !didAnimateContentEntrance else { return }
        didAnimateContentEntrance = true

        guard !UIAccessibility.isReduceMotionEnabled else {
            contentStackView.alpha = 1
            return
        }

        contentStackView.alpha = 0
        contentStackView.transform = CGAffineTransform(translationX: 0, y: 26).scaledBy(x: 0.985, y: 0.985)
        planTrayView.prepareForEntrance()

        UIView.animate(
            withDuration: 0.58,
            delay: 0.08,
            usingSpringWithDamping: 0.88,
            initialSpringVelocity: 0.38,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            self.contentStackView.alpha = 1
            self.contentStackView.transform = .identity
        } completion: { _ in
            self.planTrayView.animateEntrance()
        }
    }
}

// MARK: - UICollectionViewDataSource

extension SubscriptionViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        loopedVideoResources.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: VideoCarouselCell.reuseIdentifier,
            for: indexPath
        ) as? VideoCarouselCell else {
            return UICollectionViewCell()
        }

        let resource = loopedVideoResources[indexPath.item]
        cell.configure(resource: resource)
        cell.setFocused(indexPath.item == currentLoopIndex, animated: false)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension SubscriptionViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item != currentLoopIndex else { return }
        currentLoopIndex = indexPath.item
        scrollToLoopIndex(currentLoopIndex, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let videoCell = cell as? VideoCarouselCell else { return }
        videoCell.setFocused(indexPath.item == currentLoopIndex, animated: false)
        if indexPath.item == currentLoopIndex {
            videoCell.play()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? VideoCarouselCell)?.pause()
    }
}

// MARK: - UIScrollViewDelegate

extension SubscriptionViewController {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCellTransforms()
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isUserInteracting = true
        stopAutoScroll()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        syncCurrentIndexFromScrollPosition()
        recenterLoopPositionIfNeeded()
        isUserInteracting = false
        resumeAutoScrollIfNeeded()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            syncCurrentIndexFromScrollPosition()
            recenterLoopPositionIfNeeded()
            isUserInteracting = false
            resumeAutoScrollIfNeeded()
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        syncCurrentIndexFromScrollPosition()
        recenterLoopPositionIfNeeded()
    }

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        let targetIndex = nearestLoopIndex(for: targetContentOffset.pointee.x)
        targetContentOffset.pointee.x = CGFloat(targetIndex) * pageStride
    }
}

private final class VideoCarouselCell: UICollectionViewCell {

    static let reuseIdentifier = "VideoCarouselCell"

    private let videoContainerView = UIView()
    private let videoView = LoopingVideoView()
    private let dimView = UIView()
    private let borderView = UIView()

    private let fallbackGradientLayer = CAGradientLayer()
    private let glowOrbOne = UIView()
    private let glowOrbTwo = UIView()
    private let glowOrbThree = UIView()

    private var configuredResource: OnboardingVideoResource?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        fallbackGradientLayer.frame = videoContainerView.bounds
        layoutFallbackOrbs()
        layer.shadowPath = UIBezierPath(roundedRect: videoContainerView.frame, cornerRadius: 38).cgPath
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        configuredResource = nil
        pause()
    }

    func configure(resource: OnboardingVideoResource) {
        guard configuredResource != resource else { return }
        configuredResource = resource

        if let url = resource.bundleURL() {
            videoView.isHidden = false
            videoView.configure(url: url, isMuted: false)
        } else {
            videoView.isHidden = true
            pause()
        }
    }

    func setFocused(_ isFocused: Bool, animated: Bool) {
        let changes = {
            self.dimView.alpha = isFocused ? 0.08 : 0.24
            self.borderView.backgroundColor = .clear
        }

        if animated {
            UIView.animate(withDuration: 0.20, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: changes)
        } else {
            changes()
        }
    }

    func applyFocusProgress(_ progress: CGFloat) {
        let clamped = max(0, min(progress, 1))
        videoContainerView.alpha = 0.96 + (clamped * 0.04)
    }

    func play() {
        videoView.play()
    }

    func pause() {
        videoView.pause()
    }

    private func configureUI() {
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = false

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0
        layer.shadowRadius = 0
        layer.shadowOffset = .zero

        videoContainerView.layer.cornerRadius = 0
        videoContainerView.layer.cornerCurve = .continuous
        videoContainerView.clipsToBounds = true
        videoContainerView.layer.insertSublayer(fallbackGradientLayer, at: 0)

        fallbackGradientLayer.colors = [
            UIColor(red: 0.12, green: 0.16, blue: 0.10, alpha: 1).cgColor,
            UIColor(red: 0.55, green: 0.62, blue: 0.36, alpha: 1).cgColor,
            UIColor(red: 0.86, green: 0.85, blue: 0.59, alpha: 1).cgColor
        ]
        fallbackGradientLayer.startPoint = CGPoint(x: 0.10, y: 0.04)
        fallbackGradientLayer.endPoint = CGPoint(x: 0.92, y: 0.98)

        [glowOrbOne, glowOrbTwo, glowOrbThree].enumerated().forEach { index, orbView in
            orbView.backgroundColor = [
                UIColor.white.withAlphaComponent(0.18),
                UIColor(red: 1, green: 0.94, blue: 0.70, alpha: 0.16),
                UIColor(red: 0.77, green: 0.84, blue: 0.54, alpha: 0.18)
            ][index]
            orbView.isUserInteractionEnabled = false
            videoContainerView.addSubview(orbView)
        }

        dimView.backgroundColor = UIColor.black
        dimView.alpha = 0.12

        borderView.layer.cornerRadius = 38
        borderView.layer.cornerCurve = .continuous
        borderView.layer.borderWidth = 0
        borderView.layer.borderColor = UIColor.clear.cgColor
        borderView.backgroundColor = .clear
        borderView.isUserInteractionEnabled = false

        contentView.addSubview(videoContainerView)
        [videoView, dimView, borderView].forEach {
            videoContainerView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        videoContainerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            videoContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            videoContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            videoContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            videoContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            videoView.topAnchor.constraint(equalTo: videoContainerView.topAnchor),
            videoView.leadingAnchor.constraint(equalTo: videoContainerView.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: videoContainerView.trailingAnchor),
            videoView.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor),

            dimView.topAnchor.constraint(equalTo: videoContainerView.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: videoContainerView.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: videoContainerView.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor),

            borderView.topAnchor.constraint(equalTo: videoContainerView.topAnchor),
            borderView.leadingAnchor.constraint(equalTo: videoContainerView.leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: videoContainerView.trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor)
        ])
    }

    private func layoutFallbackOrbs() {
        let bounds = videoContainerView.bounds
        let orbFrames = [
            CGRect(x: bounds.width * 0.10, y: bounds.height * 0.16, width: bounds.width * 0.58, height: bounds.width * 0.58),
            CGRect(x: bounds.width * 0.46, y: bounds.height * 0.08, width: bounds.width * 0.52, height: bounds.width * 0.52),
            CGRect(x: bounds.width * 0.22, y: bounds.height * 0.56, width: bounds.width * 0.72, height: bounds.width * 0.72)
        ]

        zip([glowOrbOne, glowOrbTwo, glowOrbThree], orbFrames).forEach { orbView, frame in
            orbView.frame = frame
            orbView.layer.cornerRadius = min(frame.width, frame.height) * 0.5
            orbView.layer.cornerCurve = .continuous
        }
    }

}

private final class FeatureRowView: UIView {

    init(text: String) {
        super.init(frame: .zero)

        let iconView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        iconView.tintColor = UIColor(red: 1, green: 0.88, blue: 0.68, alpha: 1)
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = UIColor.white.withAlphaComponent(0.86)
        label.numberOfLines = 1

        let stackView = UIStackView(arrangedSubviews: [iconView, label])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 10

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),

            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class SubscriptionPlanTrayView: UIView {

    private let washLayer = CAGradientLayer()
    private let hairlineLayer = CAGradientLayer()

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
        washLayer.frame = bounds.insetBy(dx: -bounds.width * 0.16, dy: -bounds.height * 0.20)
        hairlineLayer.frame = CGRect(x: 18, y: 0, width: max(0, bounds.width - 36), height: 1)
    }

    func addContentView(_ contentView: UIView) {
        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    func prepareForEntrance() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: 10)
    }

    func animateEntrance() {
        guard !UIAccessibility.isReduceMotionEnabled else {
            alpha = 1
            transform = .identity
            return
        }

        UIView.animate(
            withDuration: 0.38,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            self.alpha = 1
            self.transform = .identity
        }
    }

    private func configure() {
        clipsToBounds = false

        washLayer.type = .radial
        washLayer.colors = [
            UIColor(red: 1.0, green: 0.86, blue: 0.62, alpha: 0.18).cgColor,
            UIColor(red: 0.77, green: 0.86, blue: 1.0, alpha: 0.07).cgColor,
            UIColor.clear.cgColor
        ]
        washLayer.locations = [0, 0.34, 1]
        washLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        washLayer.endPoint = CGPoint(x: 0.5, y: 0.0)

        hairlineLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.white.withAlphaComponent(0.20).cgColor,
            UIColor.clear.cgColor
        ]
        hairlineLayer.startPoint = CGPoint(x: 0, y: 0.5)
        hairlineLayer.endPoint = CGPoint(x: 1, y: 0.5)

        layer.insertSublayer(washLayer, at: 0)
        layer.insertSublayer(hairlineLayer, above: washLayer)
    }
}

private final class SubscriptionPlanButton: UIControl {

    private let backgroundLayer = CAGradientLayer()
    private let glowLayer = CAGradientLayer()
    private let separatorLayer = CAGradientLayer()
    private let selectionBorderView = UIView()
    private let selectedAccentColor = UIColor(red: 1.0, green: 0.88, blue: 0.66, alpha: 1)
    private let checkmarkView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
    private let titleLabel = UILabel()
    private let captionLabel = UILabel()
    private let priceLabel = UILabel()
    private let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
    private var isPlanSelected = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.16, delay: 0, options: [.beginFromCurrentState, .curveEaseOut]) {
                self.alpha = self.isHighlighted ? 0.76 : 1
                let baseTransform = self.isPlanSelected
                    ? CGAffineTransform(translationX: 0, y: -1)
                    : .identity
                self.transform = self.isHighlighted
                    ? baseTransform.scaledBy(x: 0.99, y: 0.99)
                    : baseTransform
            }
        }
    }

    func configure(
        title: String,
        price: String,
        caption: String,
        isSelected: Bool,
        isRecommended: Bool,
        animated: Bool
    ) {
        titleLabel.text = title
        captionLabel.text = caption
        priceLabel.text = price

        let changes = {
            self.layer.borderColor = UIColor.white.withAlphaComponent(isSelected ? 0.34 : 0.10).cgColor
            self.backgroundLayer.colors = [
                UIColor.white.withAlphaComponent(isSelected ? 0.16 : 0.052).cgColor,
                UIColor.black.withAlphaComponent(isSelected ? 0.26 : 0.17).cgColor
            ]
            self.applyPlanPalette(isSelected: isSelected, isRecommended: isRecommended)
            self.selectionBorderView.alpha = isSelected ? 1 : 0
            self.checkmarkView.alpha = isSelected ? 1 : 0
            self.checkmarkView.transform = isSelected ? .identity : CGAffineTransform(scaleX: 0.74, y: 0.74)
            self.chevronImageView.alpha = isSelected ? 0 : 0.38
            self.titleLabel.textColor = UIColor.white.withAlphaComponent(isSelected ? 0.98 : 0.78)
            self.captionLabel.textColor = UIColor.white.withAlphaComponent(isSelected ? 0.66 : 0.42)
            self.priceLabel.transform = isSelected ? CGAffineTransform(scaleX: 1.02, y: 1.02) : .identity
            self.transform = isSelected ? CGAffineTransform(translationX: 0, y: -1) : .identity
        }

        if animated, !UIAccessibility.isReduceMotionEnabled {
            UIView.animate(
                withDuration: 0.30,
                delay: 0,
                usingSpringWithDamping: 0.82,
                initialSpringVelocity: 0.22,
                options: [.beginFromCurrentState, .allowUserInteraction]
            ) {
                changes()
            }
            animateLayerSelectionTransition()
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            changes()
            CATransaction.commit()
        }

        isPlanSelected = isSelected
    }

    private func configure() {
        clipsToBounds = true
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.insertSublayer(backgroundLayer, at: 0)
        layer.insertSublayer(glowLayer, above: backgroundLayer)
        layer.insertSublayer(separatorLayer, above: glowLayer)

        backgroundLayer.startPoint = CGPoint(x: 0.1, y: 0)
        backgroundLayer.endPoint = CGPoint(x: 0.9, y: 1)

        glowLayer.type = .radial
        glowLayer.colors = [
            UIColor(red: 1.0, green: 0.86, blue: 0.62, alpha: 0.22).cgColor,
            UIColor(red: 0.76, green: 0.86, blue: 1.0, alpha: 0.08).cgColor,
            UIColor.clear.cgColor
        ]
        glowLayer.locations = [0, 0.36, 1]
        glowLayer.startPoint = CGPoint(x: 0.15, y: 1.0)
        glowLayer.endPoint = CGPoint(x: 1.0, y: 0.0)

        separatorLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.white.withAlphaComponent(0.24).cgColor,
            UIColor.clear.cgColor
        ]
        separatorLayer.startPoint = CGPoint(x: 0, y: 0.5)
        separatorLayer.endPoint = CGPoint(x: 1, y: 0.5)

        titleLabel.font = .systemFont(ofSize: 14, weight: .bold)

        captionLabel.font = .systemFont(ofSize: 11, weight: .medium)
        captionLabel.numberOfLines = 1

        priceLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .bold)
        priceLabel.textAlignment = .right
        priceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        chevronImageView.tintColor = UIColor.white.withAlphaComponent(0.40)
        chevronImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        chevronImageView.contentMode = .scaleAspectFit

        checkmarkView.tintColor = selectedAccentColor
        checkmarkView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        checkmarkView.contentMode = .scaleAspectFit
        checkmarkView.alpha = 0

        selectionBorderView.isUserInteractionEnabled = false
        selectionBorderView.alpha = 0
        selectionBorderView.layer.cornerRadius = 16
        selectionBorderView.layer.cornerCurve = .continuous
        selectionBorderView.layer.borderWidth = 1.6
        selectionBorderView.layer.borderColor = selectedAccentColor.withAlphaComponent(0.92).cgColor
        selectionBorderView.backgroundColor = .clear

        let titleStackView = UIStackView(arrangedSubviews: [titleLabel, checkmarkView])
        titleStackView.axis = .horizontal
        titleStackView.alignment = .center
        titleStackView.spacing = 6
        titleStackView.isUserInteractionEnabled = false

        let textStackView = UIStackView(arrangedSubviews: [titleStackView, captionLabel])
        textStackView.axis = .vertical
        textStackView.alignment = .leading
        textStackView.spacing = 2
        textStackView.isUserInteractionEnabled = false

        let stackView = UIStackView(arrangedSubviews: [textStackView, priceLabel, chevronImageView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 12
        stackView.isUserInteractionEnabled = false

        addSubview(selectionBorderView)
        addSubview(stackView)
        selectionBorderView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 54),

            selectionBorderView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            selectionBorderView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            selectionBorderView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            selectionBorderView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),

            checkmarkView.widthAnchor.constraint(equalToConstant: 16),
            checkmarkView.heightAnchor.constraint(equalToConstant: 16),

            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 12),

            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 9),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -9)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundLayer.frame = bounds
        backgroundLayer.cornerRadius = layer.cornerRadius
        glowLayer.frame = bounds.insetBy(dx: -bounds.width * 0.18, dy: -bounds.height * 0.52)
        separatorLayer.frame = CGRect(x: 16, y: 0, width: max(0, bounds.width - 32), height: 1)
    }

    private func applyPlanPalette(isSelected: Bool, isRecommended: Bool) {
        let primaryGlowAlpha: CGFloat = isSelected ? 0.24 : (isRecommended ? 0.18 : 0.12)
        let secondaryGlowAlpha: CGFloat = isSelected ? 0.08 : (isRecommended ? 0.06 : 0.04)

        glowLayer.colors = [
            selectedAccentColor.withAlphaComponent(primaryGlowAlpha).cgColor,
            UIColor(red: 1.0, green: 0.76, blue: 0.38, alpha: secondaryGlowAlpha).cgColor,
            UIColor.clear.cgColor
        ]
        glowLayer.opacity = isSelected ? 1 : (isRecommended ? 0.48 : 0.30)

        checkmarkView.tintColor = selectedAccentColor
        selectionBorderView.layer.borderColor = selectedAccentColor.withAlphaComponent(isSelected ? 0.92 : 0.0).cgColor
        priceLabel.textColor = isSelected
            ? selectedAccentColor
            : UIColor.white.withAlphaComponent(isRecommended ? 0.72 : 0.68)
    }

    private func animateLayerSelectionTransition() {
        let glowAnimation = CABasicAnimation(keyPath: "opacity")
        glowAnimation.fromValue = isPlanSelected ? 1 : 0.28
        glowAnimation.toValue = glowLayer.opacity
        glowAnimation.duration = 0.28
        glowAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        glowLayer.add(glowAnimation, forKey: "heartwall.plan.glow.selection")

        selectionBorderView.layer.removeAllAnimations()
    }
}

private final class AgreementRowView: UIView {

    private let iconView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        iconView.tintColor = UIColor(red: 0.35, green: 0.68, blue: 1.0, alpha: 1)
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)

        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.60)
        label.textAlignment = .center

        let stackView = UIStackView(arrangedSubviews: [iconView, label])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 6

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 14),
            iconView.heightAnchor.constraint(equalToConstant: 14),

            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(text: String) {
        label.text = text
    }
}

private final class GradientCapsuleButton: UIButton {

    private let gradientLayer = CAGradientLayer()
    private let glowLayer = CALayer()
    private let breathingAnimationKey = "heartwall.subscription.cta.breathing"
    private let glowBreathingAnimationKey = "heartwall.subscription.cta.glow.breathing"

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
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = bounds.height * 0.5
        glowLayer.frame = CGRect(x: bounds.width * 0.08, y: 7, width: bounds.width * 0.44, height: bounds.height * 0.28)
        glowLayer.cornerRadius = glowLayer.bounds.height * 0.5
    }

    func startBreathing() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        guard layer.animation(forKey: breathingAnimationKey) == nil else { return }

        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 1.078

        let shadowAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        shadowAnimation.fromValue = 0.28
        shadowAnimation.toValue = 0.62

        let group = CAAnimationGroup()
        group.animations = [scaleAnimation, shadowAnimation]
        group.duration = 0.96
        group.autoreverses = true
        group.repeatCount = .infinity
        group.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        group.isRemovedOnCompletion = false

        layer.add(group, forKey: breathingAnimationKey)

        let glowAnimation = CABasicAnimation(keyPath: "opacity")
        glowAnimation.fromValue = 0.30
        glowAnimation.toValue = 1.0
        glowAnimation.duration = 0.96
        glowAnimation.autoreverses = true
        glowAnimation.repeatCount = .infinity
        glowAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glowAnimation.isRemovedOnCompletion = false
        glowLayer.add(glowAnimation, forKey: glowBreathingAnimationKey)
    }

    func stopBreathing() {
        layer.removeAnimation(forKey: breathingAnimationKey)
        glowLayer.removeAnimation(forKey: glowBreathingAnimationKey)
    }

    private func configure() {
        clipsToBounds = false
        layer.cornerRadius = 29
        layer.cornerCurve = .continuous
        layer.insertSublayer(gradientLayer, at: 0)
        layer.insertSublayer(glowLayer, above: gradientLayer)
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.34).cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.28
        layer.shadowRadius = 40
        layer.shadowOffset = CGSize(width: 0, height: 16)

        gradientLayer.colors = [
            UIColor(red: 0.99, green: 0.91, blue: 0.78, alpha: 1).cgColor,
            UIColor(red: 0.96, green: 0.81, blue: 0.58, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.05, y: 0.50)
        gradientLayer.endPoint = CGPoint(x: 0.95, y: 0.50)

        glowLayer.backgroundColor = UIColor.white.withAlphaComponent(0.22).cgColor
        glowLayer.opacity = 0.78

        setTitleColor(UIColor(red: 0.35, green: 0.23, blue: 0.11, alpha: 1), for: .normal)
        titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
    }
}

private final class BottomRadiantOverlayView: UIView {

    private let radialGlowLayer = CAGradientLayer()
    private let verticalFadeLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false

        radialGlowLayer.type = .radial
        radialGlowLayer.colors = [
            UIColor(red: 0.98, green: 0.90, blue: 0.68, alpha: 0.34).cgColor,
            UIColor(red: 0.72, green: 0.84, blue: 1.00, alpha: 0.13).cgColor,
            UIColor.clear.cgColor
        ]
        radialGlowLayer.locations = [0, 0.30, 1]
        radialGlowLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        radialGlowLayer.endPoint = CGPoint(x: 0.5, y: 0.0)

        verticalFadeLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.04).cgColor,
            UIColor.black.withAlphaComponent(0.30).cgColor,
            UIColor.black.withAlphaComponent(0.74).cgColor,
            UIColor.black.withAlphaComponent(0.96).cgColor
        ]
        verticalFadeLayer.locations = [0, 0.30, 0.55, 0.80, 1]
        verticalFadeLayer.startPoint = CGPoint(x: 0.5, y: 0)
        verticalFadeLayer.endPoint = CGPoint(x: 0.5, y: 1)

        layer.addSublayer(radialGlowLayer)
        layer.addSublayer(verticalFadeLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        verticalFadeLayer.frame = bounds
        radialGlowLayer.frame = CGRect(
            x: -bounds.width * 0.42,
            y: bounds.height * 0.38,
            width: bounds.width * 1.84,
            height: bounds.height * 0.78
        )
    }
}
