//
//  SubscriptionViewController.swift
//  HeartWall
//

import UIKit

final class SubscriptionViewController: BaseViewController {

    // MARK: - Properties

    private let initialResource: OnboardingVideoResource
    private let videoResources = OnboardingVideoResource.allCases

    private var currentIndex: Int
    private var didSetInitialOffset = false
    private var lastKnownCarouselSize: CGSize = .zero

    // MARK: - UI

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
    private let counterLabel = UILabel()
    private let bottomScrimView = VerticalScrimView()
    private let bottomBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let contentStackView = UIStackView()
    private let benefitStackView = UIStackView()
    private let titleLabel = UILabel()
    private let trialButton = GradientCapsuleButton()
    private let noteLabel = UILabel()
    private let legalLabel = UILabel()

    // MARK: - Lifecycle

    init(videoResource: OnboardingVideoResource) {
        self.initialResource = videoResource
        self.currentIndex = OnboardingVideoResource.allCases.firstIndex(of: videoResource) ?? 0
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
        syncCurrentIndexFromScrollPosition()
        refreshVisibleCellState(animated: false)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pauseVisibleCells()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCarouselLayoutIfNeeded()

        guard carouselView.bounds.width > 0 else { return }

        if !didSetInitialOffset {
            didSetInitialOffset = true
            carouselView.layoutIfNeeded()
            scrollToIndex(currentIndex, animated: false)
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
        updateCounterLabel()

        [carouselView, bottomScrimView, bottomBlurView, closeButton, restoreButton, counterLabel].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        bottomBlurView.alpha = 0.52

        bottomBlurView.contentView.addSubview(contentStackView)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            carouselView.topAnchor.constraint(equalTo: view.topAnchor),
            carouselView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            carouselView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            carouselView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            bottomScrimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomScrimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomScrimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomScrimView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.46),

            bottomBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBlurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBlurView.heightAnchor.constraint(equalTo: bottomScrimView.heightAnchor),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),

            restoreButton.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            restoreButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            counterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            counterLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),

            contentStackView.leadingAnchor.constraint(equalTo: bottomBlurView.contentView.leadingAnchor, constant: 24),
            contentStackView.trailingAnchor.constraint(equalTo: bottomBlurView.contentView.trailingAnchor, constant: -24),
            contentStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -14),
            contentStackView.topAnchor.constraint(greaterThanOrEqualTo: bottomBlurView.contentView.topAnchor, constant: 22),

            trialButton.heightAnchor.constraint(equalToConstant: 58)
        ])
    }

    private func configureTopButtons() {
        var closeConfiguration = UIButton.Configuration.plain()
        closeConfiguration.baseForegroundColor = UIColor.white.withAlphaComponent(0.88)
        closeConfiguration.contentInsets = .zero
        closeConfiguration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        closeButton.configuration = closeConfiguration
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.backgroundColor = UIColor.white.withAlphaComponent(0.09)
        closeButton.layer.cornerRadius = 18
        closeButton.layer.cornerCurve = .continuous
        closeButton.layer.borderWidth = 1
        closeButton.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor
        closeButton.addTarget(self, action: #selector(handleEnterHome), for: .touchUpInside)

        var restoreConfiguration = UIButton.Configuration.plain()
        restoreConfiguration.title = "恢复购买"
        restoreConfiguration.baseForegroundColor = UIColor.white.withAlphaComponent(0.76)
        restoreConfiguration.contentInsets = .zero
        restoreButton.configuration = restoreConfiguration
        restoreButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        restoreButton.addTarget(self, action: #selector(handleRestore), for: .touchUpInside)

        counterLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
        counterLabel.textColor = UIColor.white.withAlphaComponent(0.78)
        counterLabel.textAlignment = .center
    }

    private func configureOverlayContent() {
        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.spacing = 14

        benefitStackView.axis = .vertical
        benefitStackView.alignment = .fill
        benefitStackView.spacing = 8

        [
            "所有私密视频功能不限量使用",
            "导入、整理与预览体验持续解锁",
            "高清动态片段与质感动效完整可用",
            "沉浸式浏览过程保持无广告"
        ]
        .map(FeatureRowView.init)
        .forEach(benefitStackView.addArrangedSubview)

        titleLabel.text = "解锁完整私密视频体验"
        titleLabel.font = serifFont(size: 34, weight: .bold)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.98)
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .left

        trialButton.setTitle("免费试用", for: .normal)
        trialButton.addTarget(self, action: #selector(handleEnterHome), for: .touchUpInside)

        noteLabel.text = "当前为预览版本，订阅购买能力暂未接入"
        noteLabel.font = .systemFont(ofSize: 13, weight: .medium)
        noteLabel.textColor = UIColor.white.withAlphaComponent(0.78)
        noteLabel.textAlignment = .center
        noteLabel.numberOfLines = 0

        legalLabel.text = "继续即表示你已阅读《会员协议》与《自动续费说明》。本轮仅实现页面与跳转，不触发真实扣费。"
        legalLabel.font = .systemFont(ofSize: 11, weight: .medium)
        legalLabel.textColor = UIColor.white.withAlphaComponent(0.54)
        legalLabel.textAlignment = .center
        legalLabel.numberOfLines = 0

        [benefitStackView, titleLabel, trialButton, noteLabel, legalLabel].forEach {
            contentStackView.addArrangedSubview($0)
        }
    }

    // MARK: - Carousel

    private func updateCarouselLayoutIfNeeded() {
        guard carouselView.bounds.size != .zero else { return }
        guard carouselView.bounds.size != lastKnownCarouselSize else { return }

        lastKnownCarouselSize = carouselView.bounds.size

        let itemWidth = max(294, carouselView.bounds.width - 76)
        let itemHeight = max(560, carouselView.bounds.height - 24)
        let horizontalInset = max(18, (carouselView.bounds.width - itemWidth) * 0.5)

        carouselLayout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        carouselLayout.sectionInset = UIEdgeInsets(top: 12, left: horizontalInset, bottom: 12, right: horizontalInset)
        carouselLayout.invalidateLayout()
    }

    private var pageStride: CGFloat {
        carouselLayout.itemSize.width + carouselLayout.minimumLineSpacing
    }

    private func scrollToIndex(_ index: Int, animated: Bool) {
        let targetX = CGFloat(index) * pageStride
        carouselView.setContentOffset(CGPoint(x: targetX, y: 0), animated: animated)
    }

    private func nearestIndex(for contentOffsetX: CGFloat) -> Int {
        guard pageStride > 0 else { return 0 }
        let rawIndex = Int(round(contentOffsetX / pageStride))
        return max(0, min(videoResources.count - 1, rawIndex))
    }

    private func syncCurrentIndexFromScrollPosition() {
        let nextIndex = nearestIndex(for: carouselView.contentOffset.x)
        guard nextIndex != currentIndex else {
            updateCounterLabel()
            refreshVisibleCellState(animated: true)
            return
        }

        currentIndex = nextIndex
        updateCounterLabel()
        refreshVisibleCellState(animated: true)
    }

    private func refreshVisibleCellState(animated: Bool) {
        updateCellTransforms()

        for cell in carouselView.visibleCells.compactMap({ $0 as? VideoCarouselCell }) {
            guard let indexPath = carouselView.indexPath(for: cell) else { continue }
            let shouldPlay = abs(indexPath.item - currentIndex) <= 1
            shouldPlay ? cell.play() : cell.pause()
            cell.setFocused(indexPath.item == currentIndex, animated: animated)
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

    private func updateCounterLabel() {
        counterLabel.text = String(format: "%02d / %02d", currentIndex + 1, videoResources.count)
    }

    // MARK: - Actions

    @objc
    private func handleEnterHome() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
        videoResources.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: VideoCarouselCell.reuseIdentifier,
            for: indexPath
        ) as? VideoCarouselCell else {
            return UICollectionViewCell()
        }

        let resource = videoResources[indexPath.item]
        cell.configure(resource: resource, index: indexPath.item)
        cell.setFocused(indexPath.item == currentIndex, animated: false)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension SubscriptionViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item != currentIndex else { return }
        currentIndex = indexPath.item
        updateCounterLabel()
        scrollToIndex(currentIndex, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let videoCell = cell as? VideoCarouselCell else { return }
        videoCell.setFocused(indexPath.item == currentIndex, animated: false)
        if abs(indexPath.item - currentIndex) <= 1 {
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

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        syncCurrentIndexFromScrollPosition()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            syncCurrentIndexFromScrollPosition()
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        syncCurrentIndexFromScrollPosition()
    }

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        let targetIndex = nearestIndex(for: targetContentOffset.pointee.x)
        targetContentOffset.pointee.x = CGFloat(targetIndex) * pageStride
    }
}

private final class VideoCarouselCell: UICollectionViewCell {

    static let reuseIdentifier = "VideoCarouselCell"

    private let videoContainerView = UIView()
    private let videoView = LoopingVideoView()
    private let dimView = UIView()
    private let borderView = UIView()
    private let heroPillView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
    private let heroPillLabel = UILabel()
    private let dateLabel = UILabel()
    private let timeLabel = UILabel()

    private let fallbackGradientLayer = CAGradientLayer()
    private let glowOrbOne = UIView()
    private let glowOrbTwo = UIView()
    private let glowOrbThree = UIView()

    private var configuredResource: OnboardingVideoResource?

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
        fallbackGradientLayer.frame = videoContainerView.bounds
        layoutFallbackOrbs()
        layer.shadowPath = UIBezierPath(roundedRect: videoContainerView.frame, cornerRadius: 38).cgPath
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        pause()
    }

    func configure(resource: OnboardingVideoResource, index: Int) {
        heroPillLabel.text = String(format: "精选片段 %02d", index + 1)
        dateLabel.text = Self.dateFormatter.string(from: Date())
        timeLabel.text = Self.timeFormatter.string(from: Date())

        guard configuredResource != resource else { return }
        configuredResource = resource

        if let url = resource.bundleURL() {
            videoView.isHidden = false
            videoView.configure(url: url, isMuted: true)
        } else {
            videoView.isHidden = true
        }
    }

    func setFocused(_ isFocused: Bool, animated: Bool) {
        let changes = {
            self.dimView.alpha = isFocused ? 0.12 : 0.28
            self.borderView.layer.borderColor = UIColor.white.withAlphaComponent(isFocused ? 0.72 : 0.22).cgColor
            self.borderView.backgroundColor = UIColor.white.withAlphaComponent(isFocused ? 0.06 : 0.02)
        }

        if animated {
            UIView.animate(withDuration: 0.20, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: changes)
        } else {
            changes()
        }
    }

    func applyFocusProgress(_ progress: CGFloat) {
        let clamped = max(0, min(progress, 1))
        heroPillView.alpha = 0.36 + (clamped * 0.64)
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

    private func configure() {
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

        dimView.backgroundColor = UIColor.black.withAlphaComponent(1)
        dimView.alpha = 0.14

        borderView.layer.cornerRadius = 38
        borderView.layer.cornerCurve = .continuous
        borderView.layer.borderWidth = 1.2
        borderView.layer.borderColor = UIColor.white.withAlphaComponent(0.70).cgColor
        borderView.backgroundColor = UIColor.white.withAlphaComponent(0.04)
        borderView.isUserInteractionEnabled = false

        heroPillView.layer.cornerRadius = 16
        heroPillView.layer.cornerCurve = .continuous
        heroPillView.clipsToBounds = true
        heroPillView.layer.borderWidth = 1
        heroPillView.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor

        heroPillLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        heroPillLabel.textColor = UIColor.white.withAlphaComponent(0.92)
        heroPillLabel.textAlignment = .center

        dateLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        dateLabel.textColor = UIColor.white.withAlphaComponent(0.88)
        dateLabel.textAlignment = .center

        timeLabel.font = .monospacedDigitSystemFont(ofSize: 66, weight: .bold)
        timeLabel.textColor = UIColor.white.withAlphaComponent(0.97)
        timeLabel.textAlignment = .center

        [videoContainerView].forEach(contentView.addSubview)
        [videoView, dimView, borderView, heroPillView, dateLabel, timeLabel].forEach {
            videoContainerView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        heroPillView.contentView.addSubview(heroPillLabel)
        heroPillLabel.translatesAutoresizingMaskIntoConstraints = false

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
            borderView.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor),

            heroPillView.topAnchor.constraint(equalTo: videoContainerView.safeAreaLayoutGuide.topAnchor, constant: 22),
            heroPillView.centerXAnchor.constraint(equalTo: videoContainerView.centerXAnchor),

            heroPillLabel.topAnchor.constraint(equalTo: heroPillView.contentView.topAnchor, constant: 9),
            heroPillLabel.leadingAnchor.constraint(equalTo: heroPillView.contentView.leadingAnchor, constant: 16),
            heroPillLabel.trailingAnchor.constraint(equalTo: heroPillView.contentView.trailingAnchor, constant: -16),
            heroPillLabel.bottomAnchor.constraint(equalTo: heroPillView.contentView.bottomAnchor, constant: -9),

            dateLabel.centerXAnchor.constraint(equalTo: videoContainerView.centerXAnchor),
            dateLabel.centerYAnchor.constraint(equalTo: videoContainerView.centerYAnchor, constant: -106),

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

private final class VerticalScrimView: UIView {

    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    private var gradientLayer: CAGradientLayer {
        layer as! CAGradientLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.10).cgColor,
            UIColor.black.withAlphaComponent(0.42).cgColor,
            UIColor.black.withAlphaComponent(0.72).cgColor
        ]
        gradientLayer.locations = [0, 0.16, 0.58, 1]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
