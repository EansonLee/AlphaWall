//
//  SubscriptionViewController.swift
//  HeartWall
//

import UIKit

final class SubscriptionViewController: BaseViewController {

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
    private let titleLabel = UILabel()
    private let trialButton = GradientCapsuleButton()
    private let priceLabel = UILabel()
    private let agreementView = AgreementRowView()

    // MARK: - Lifecycle

    init(videoResource: OnboardingVideoResource) {
        let preferredIndex = min(1, OnboardingVideoResource.allCases.count - 1)
        let middleCycle = max(0, CarouselConfig.loopMultiplier / 2)
        self.currentLoopIndex = (middleCycle * OnboardingVideoResource.allCases.count) + preferredIndex
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
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopAutoScroll()
        backgroundVideoView.pause()
        pauseVisibleCells()
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
            contentStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -14),
            contentStackView.topAnchor.constraint(greaterThanOrEqualTo: view.centerYAnchor, constant: 70),

            trialButton.heightAnchor.constraint(equalToConstant: 58)
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
        restoreConfiguration.title = "恢复购买"
        restoreConfiguration.baseForegroundColor = UIColor.white.withAlphaComponent(0.72)
        restoreConfiguration.contentInsets = .zero
        restoreButton.configuration = restoreConfiguration
        restoreButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        restoreButton.addTarget(self, action: #selector(handleRestore), for: .touchUpInside)
    }

    private func configureOverlayContent() {
        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.spacing = 12

        benefitStackView.axis = .vertical
        benefitStackView.alignment = .fill
        benefitStackView.spacing = 7

        [
            "所有壁纸无限下载",
            "白噪音无限畅听",
            "最新功能抢先体验",
            "沉浸体验无广告"
        ]
        .map(FeatureRowView.init)
        .forEach(benefitStackView.addArrangedSubview)

        titleLabel.text = "海量动态壁纸高清下载"
        titleLabel.font = serifFont(size: 35, weight: .bold)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.98)
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .left

        trialButton.setTitle("免费试用", for: .normal)
        trialButton.addTarget(self, action: #selector(handleEnterHome), for: .touchUpInside)

        priceLabel.text = "首周 ¥9.9 后自动续费 ¥48/月，可随时取消"
        priceLabel.font = .systemFont(ofSize: 12, weight: .medium)
        priceLabel.textColor = UIColor.white.withAlphaComponent(0.70)
        priceLabel.textAlignment = .center

        agreementView.configure(text: "同意《会员协议》和《自动续费协议》")

        [benefitStackView, titleLabel, trialButton, priceLabel, agreementView].forEach {
            contentStackView.addArrangedSubview($0)
        }

        contentStackView.setCustomSpacing(16, after: benefitStackView)
        contentStackView.setCustomSpacing(18, after: titleLabel)
        contentStackView.setCustomSpacing(10, after: trialButton)
        contentStackView.setCustomSpacing(6, after: priceLabel)
    }

    // MARK: - Carousel

    private func updateCarouselLayoutIfNeeded() {
        guard carouselView.bounds.size != .zero else { return }
        guard carouselView.bounds.size != lastKnownCarouselSize else { return }

        lastKnownCarouselSize = carouselView.bounds.size

        let itemWidth = max(286, carouselView.bounds.width - 90)
        let itemHeight = max(560, carouselView.bounds.height - 8)
        let horizontalInset = max(18, (carouselView.bounds.width - itemWidth) * 0.5)

        carouselLayout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        carouselLayout.sectionInset = UIEdgeInsets(top: 4, left: horizontalInset, bottom: 4, right: horizontalInset)
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

        backgroundVideoView.configure(url: url, isMuted: true)
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
            let scale = 0.90 + (focusProgress * 0.10)
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

        guard let navigationController else { return }
        let libraryViewController = LibraryViewController()

        UIView.transition(
            with: navigationController.view,
            duration: UIAccessibility.isReduceMotionEnabled ? 0.15 : 0.40,
            options: [.transitionCrossDissolve, .allowAnimatedContent]
        ) {
            navigationController.setViewControllers([libraryViewController], animated: false)
        }
    }

    @objc
    private func handleRestore() {
        let alert = UIAlertController(title: "恢复购买", message: "当前版本仅完成订阅页预览，真实购买能力暂未接入。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "知道了", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Helpers

    private func serifFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        let descriptor = systemFont.fontDescriptor.withDesign(.serif) ?? systemFont.fontDescriptor
        return UIFont(descriptor: descriptor, size: size)
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
    private let videoCropView = UIView()
    private let videoView = LoopingVideoView()
    private let dimView = UIView()
    private let borderView = UIView()
    private let dateLabel = UILabel()
    private let timeLabel = UILabel()

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
        dateLabel.text = Self.dateFormatter.string(from: Date())
        timeLabel.text = Self.timeFormatter.string(from: Date())

        guard configuredResource != resource else { return }
        configuredResource = resource

        if let url = resource.bundleURL() {
            videoView.isHidden = false
            videoView.configure(url: url, isMuted: true)
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
        dateLabel.alpha = 0.30 + (clamped * 0.70)
        timeLabel.alpha = 0.38 + (clamped * 0.62)
        dateLabel.transform = CGAffineTransform(scaleX: 0.96 + (clamped * 0.04), y: 0.96 + (clamped * 0.04))
        timeLabel.transform = CGAffineTransform(scaleX: 0.94 + (clamped * 0.06), y: 0.94 + (clamped * 0.06))
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
        layer.shadowOpacity = 0.26
        layer.shadowRadius = 34
        layer.shadowOffset = CGSize(width: 0, height: 18)

        videoContainerView.layer.cornerRadius = 38
        videoContainerView.layer.cornerCurve = .continuous
        videoContainerView.clipsToBounds = true
        videoContainerView.layer.insertSublayer(fallbackGradientLayer, at: 0)

        videoCropView.clipsToBounds = true

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

        dateLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        dateLabel.textColor = UIColor.white.withAlphaComponent(0.88)
        dateLabel.textAlignment = .center

        timeLabel.font = .monospacedDigitSystemFont(ofSize: 68, weight: .heavy)
        timeLabel.textColor = UIColor.white.withAlphaComponent(0.97)
        timeLabel.textAlignment = .center

        contentView.addSubview(videoContainerView)
        [videoCropView, dimView, borderView, dateLabel, timeLabel].forEach {
            videoContainerView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        videoCropView.addSubview(videoView)
        videoView.translatesAutoresizingMaskIntoConstraints = false
        videoContainerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            videoContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            videoContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            videoContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            videoContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            videoCropView.topAnchor.constraint(equalTo: videoContainerView.topAnchor),
            videoCropView.leadingAnchor.constraint(equalTo: videoContainerView.leadingAnchor),
            videoCropView.trailingAnchor.constraint(equalTo: videoContainerView.trailingAnchor),
            videoCropView.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor),

            videoView.topAnchor.constraint(equalTo: videoCropView.topAnchor, constant: -20),
            videoView.leadingAnchor.constraint(equalTo: videoCropView.leadingAnchor, constant: -36),
            videoView.trailingAnchor.constraint(equalTo: videoCropView.trailingAnchor, constant: 36),
            videoView.bottomAnchor.constraint(equalTo: videoCropView.bottomAnchor, constant: 20),

            dimView.topAnchor.constraint(equalTo: videoContainerView.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: videoContainerView.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: videoContainerView.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor),

            borderView.topAnchor.constraint(equalTo: videoContainerView.topAnchor),
            borderView.leadingAnchor.constraint(equalTo: videoContainerView.leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: videoContainerView.trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor),

            dateLabel.centerXAnchor.constraint(equalTo: videoContainerView.centerXAnchor),
            dateLabel.topAnchor.constraint(equalTo: videoContainerView.safeAreaLayoutGuide.topAnchor, constant: 78),

            timeLabel.centerXAnchor.constraint(equalTo: videoContainerView.centerXAnchor),
            timeLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8)
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

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
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

    private func configure() {
        clipsToBounds = false
        layer.cornerRadius = 29
        layer.cornerCurve = .continuous
        layer.insertSublayer(gradientLayer, at: 0)
        layer.insertSublayer(glowLayer, above: gradientLayer)
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.34).cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.18
        layer.shadowRadius = 24
        layer.shadowOffset = CGSize(width: 0, height: 10)

        gradientLayer.colors = [
            UIColor(red: 0.99, green: 0.91, blue: 0.78, alpha: 1).cgColor,
            UIColor(red: 0.96, green: 0.81, blue: 0.58, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.05, y: 0.50)
        gradientLayer.endPoint = CGPoint(x: 0.95, y: 0.50)

        glowLayer.backgroundColor = UIColor.white.withAlphaComponent(0.22).cgColor
        glowLayer.opacity = 1

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
            UIColor(red: 0.96, green: 0.84, blue: 0.58, alpha: 0.12).cgColor,
            UIColor.clear.cgColor
        ]
        radialGlowLayer.locations = [0, 0.28, 1]
        radialGlowLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        radialGlowLayer.endPoint = CGPoint(x: 0.5, y: 0.0)

        verticalFadeLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.04).cgColor,
            UIColor.black.withAlphaComponent(0.24).cgColor,
            UIColor.black.withAlphaComponent(0.68).cgColor,
            UIColor.black.withAlphaComponent(0.94).cgColor
        ]
        verticalFadeLayer.locations = [0, 0.40, 0.60, 0.82, 1]
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
            x: -bounds.width * 0.28,
            y: bounds.height * 0.22,
            width: bounds.width * 1.56,
            height: bounds.height * 0.96
        )
    }
}
