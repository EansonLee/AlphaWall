//
//  HeartQuoteDetailViewController.swift
//  HeartWall
//

import UIKit
import AVFoundation

final class HeartQuoteDetailViewController: BaseViewController {

    // MARK: - Properties

    private let pages: [HeartQuotePage]
    private var currentPageIndex: Int
    private var page: HeartQuotePage {
        pages[currentPageIndex]
    }
    private var isChromeVisible = false
    private var isFavorite = false
    private var isPlaying = false

    // MARK: - UI

    private let wallpaperVideoView = LoopingVideoView()
    private let dimOverlayView = UIView()
    private let topFadeView = UIView()
    private let topFadeLayer = CAGradientLayer()
    private let bottomFadeView = UIView()
    private let bottomFadeLayer = CAGradientLayer()
    private let lockStatusLabel = UILabel()
    private let timeLabel = UILabel()
    private let dateLabel = UILabel()
    private let headerView = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let pageCounterLabel = UILabel()
    private let vipBadgeView = UIView()
    private let vipBadgeLabel = UILabel()
    private let curationCardView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let curationEyebrowLabel = UILabel()
    private let curationTitleLabel = UILabel()
    private let curationSubtitleLabel = UILabel()
    private let curationTagStackView = UIStackView()
    private let actionBarView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let favoriteButton = UIButton(type: .system)
    private let playButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private let homeIndicatorView = UIView()

    // MARK: - Lifecycle

    init(page: HeartQuotePage) {
        pages = [page]
        currentPageIndex = 0
        super.init(nibName: nil, bundle: nil)
    }

    init(pages: [HeartQuotePage], initialIndex: Int) {
        precondition(!pages.isEmpty, "HeartQuoteDetailViewController requires at least one page.")
        self.pages = pages
        currentPageIndex = min(max(initialIndex, 0), pages.count - 1)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        topFadeLayer.frame = topFadeView.bounds
        bottomFadeLayer.frame = bottomFadeView.bounds
        if let vipGradient = vipBadgeView.layer.sublayers?.first as? CAGradientLayer {
            vipGradient.frame = vipBadgeView.bounds
        }
    }

    // MARK: - Setup

    override func setupUI() {
        view.backgroundColor = UIColor(red: 0.05, green: 0.08, blue: 0.09, alpha: 1)
        isFavorite = FavoriteWallpaperStore.shared.isFavorite(page)
        configureWallpaper()
        configureGradients()
        configureLockPreview()
        configureHeader()
        configureCurationCard()
        configureActions()
        configureHomeIndicator()
        configureTapGesture()
        configureSwipeGestures()
        updatePageMetadata()
        updateChromeVisibility(animated: false)
        updateFavoriteButton()
        updatePlayButton()
        startPlaybackIfPossible()
    }

    private func configureWallpaper() {
        wallpaperVideoView.backgroundColor = UIColor.black

        dimOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.20)

        view.addSubview(wallpaperVideoView)
        view.addSubview(dimOverlayView)
        wallpaperVideoView.translatesAutoresizingMaskIntoConstraints = false
        dimOverlayView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            wallpaperVideoView.topAnchor.constraint(equalTo: view.topAnchor),
            wallpaperVideoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wallpaperVideoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            wallpaperVideoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            dimOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            dimOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureGradients() {
        topFadeLayer.colors = [
            UIColor.black.withAlphaComponent(0.34).cgColor,
            UIColor.black.withAlphaComponent(0.08).cgColor,
            UIColor.clear.cgColor
        ]
        topFadeLayer.locations = [0, 0.58, 1]
        topFadeView.isUserInteractionEnabled = false
        topFadeView.layer.addSublayer(topFadeLayer)

        bottomFadeLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.34).cgColor,
            UIColor.black.withAlphaComponent(0.70).cgColor
        ]
        bottomFadeLayer.locations = [0, 0.48, 1]
        bottomFadeView.isUserInteractionEnabled = false
        bottomFadeView.layer.addSublayer(bottomFadeLayer)

        view.addSubview(topFadeView)
        view.addSubview(bottomFadeView)
        topFadeView.translatesAutoresizingMaskIntoConstraints = false
        bottomFadeView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topFadeView.topAnchor.constraint(equalTo: view.topAnchor),
            topFadeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topFadeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topFadeView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.26),

            bottomFadeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomFadeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomFadeView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomFadeView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.42)
        ])
    }

    private func configureLockPreview() {
        lockStatusLabel.text = page.theme.displayTitle
        lockStatusLabel.font = .systemFont(ofSize: 10, weight: .semibold)
        lockStatusLabel.textColor = UIColor.white.withAlphaComponent(0.44)
        lockStatusLabel.textAlignment = .center

        dateLabel.text = currentDateText()
        dateLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        dateLabel.textColor = UIColor.white.withAlphaComponent(0.72)
        dateLabel.textAlignment = .center

        timeLabel.text = currentTimeText()
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 56, weight: .semibold)
        timeLabel.textColor = UIColor.white.withAlphaComponent(0.84)
        timeLabel.textAlignment = .center
        timeLabel.adjustsFontSizeToFitWidth = true
        timeLabel.minimumScaleFactor = 0.72

        view.addSubview(lockStatusLabel)
        view.addSubview(dateLabel)
        view.addSubview(timeLabel)
        lockStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            lockStatusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 88),
            lockStatusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            lockStatusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            lockStatusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),

            dateLabel.topAnchor.constraint(equalTo: lockStatusLabel.bottomAnchor, constant: 1),
            dateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),

            timeLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 2),
            timeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 48),
            timeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -48)
        ])
    }

    private func configureHeader() {
        titleLabel.text = page.title
        titleLabel.font = .systemFont(ofSize: 13, weight: .bold)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.80)
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 1

        pageCounterLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        pageCounterLabel.textColor = UIColor.white.withAlphaComponent(0.54)
        pageCounterLabel.textAlignment = .left

        var backConfiguration = UIButton.Configuration.plain()
        backConfiguration.baseForegroundColor = UIColor.white.withAlphaComponent(0.90)
        backConfiguration.contentInsets = .zero
        backConfiguration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        backButton.configuration = backConfiguration
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.backgroundColor = UIColor.black.withAlphaComponent(0.24)
        backButton.layer.cornerRadius = 16
        backButton.layer.cornerCurve = .continuous
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)

        vipBadgeView.layer.cornerRadius = 5
        vipBadgeView.layer.cornerCurve = .continuous
        vipBadgeView.clipsToBounds = true
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 1.00, green: 0.90, blue: 0.68, alpha: 1).cgColor,
            UIColor(red: 0.98, green: 0.63, blue: 0.40, alpha: 1).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        vipBadgeView.layer.insertSublayer(gradient, at: 0)

        vipBadgeLabel.text = "V"
        vipBadgeLabel.font = .systemFont(ofSize: 13, weight: .black)
        vipBadgeLabel.textColor = UIColor(red: 0.64, green: 0.38, blue: 0.25, alpha: 1)
        vipBadgeLabel.textAlignment = .center

        view.addSubview(headerView)
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        headerView.addSubview(pageCounterLabel)
        headerView.addSubview(vipBadgeView)
        vipBadgeView.addSubview(vipBadgeLabel)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        pageCounterLabel.translatesAutoresizingMaskIntoConstraints = false
        vipBadgeView.translatesAutoresizingMaskIntoConstraints = false
        vipBadgeLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            headerView.heightAnchor.constraint(equalToConstant: 40),

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: vipBadgeView.leadingAnchor, constant: -14),

            pageCounterLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            pageCounterLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            pageCounterLabel.trailingAnchor.constraint(lessThanOrEqualTo: vipBadgeView.leadingAnchor, constant: -14),

            vipBadgeView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -2),
            vipBadgeView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            vipBadgeView.widthAnchor.constraint(equalToConstant: 23),
            vipBadgeView.heightAnchor.constraint(equalToConstant: 23),

            vipBadgeLabel.centerXAnchor.constraint(equalTo: vipBadgeView.centerXAnchor),
            vipBadgeLabel.centerYAnchor.constraint(equalTo: vipBadgeView.centerYAnchor)
        ])
    }

    private func configureCurationCard() {
        curationCardView.layer.cornerRadius = 24
        curationCardView.layer.cornerCurve = .continuous
        curationCardView.clipsToBounds = true
        curationCardView.layer.borderWidth = 1
        curationCardView.layer.borderColor = UIColor.white.withAlphaComponent(0.16).cgColor

        curationEyebrowLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        curationEyebrowLabel.textColor = UIColor(red: 1.0, green: 0.86, blue: 0.62, alpha: 0.78)

        curationTitleLabel.font = .systemFont(ofSize: 22, weight: .black)
        curationTitleLabel.textColor = UIColor.white.withAlphaComponent(0.96)
        curationTitleLabel.numberOfLines = 2

        curationSubtitleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        curationSubtitleLabel.textColor = UIColor.white.withAlphaComponent(0.68)
        curationSubtitleLabel.numberOfLines = 2

        curationTagStackView.axis = .horizontal
        curationTagStackView.alignment = .center
        curationTagStackView.spacing = 7
        curationTagStackView.distribution = .fillProportionally

        configureSaveButton()

        let textStack = UIStackView(arrangedSubviews: [
            curationEyebrowLabel,
            curationTitleLabel,
            curationSubtitleLabel,
            curationTagStackView
        ])
        textStack.axis = .vertical
        textStack.spacing = 7

        let contentStack = UIStackView(arrangedSubviews: [textStack, saveButton])
        contentStack.axis = .vertical
        contentStack.spacing = 14

        view.addSubview(curationCardView)
        curationCardView.contentView.addSubview(contentStack)
        curationCardView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            curationCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            curationCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            curationCardView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),

            contentStack.topAnchor.constraint(equalTo: curationCardView.contentView.topAnchor, constant: 18),
            contentStack.leadingAnchor.constraint(equalTo: curationCardView.contentView.leadingAnchor, constant: 18),
            contentStack.trailingAnchor.constraint(equalTo: curationCardView.contentView.trailingAnchor, constant: -18),
            contentStack.bottomAnchor.constraint(equalTo: curationCardView.contentView.bottomAnchor, constant: -18),

            saveButton.heightAnchor.constraint(equalToConstant: 46)
        ])
    }

    private func configureActions() {
        actionBarView.layer.cornerRadius = 20
        actionBarView.layer.cornerCurve = .continuous
        actionBarView.clipsToBounds = true
        actionBarView.layer.borderWidth = 1
        actionBarView.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor

        configureIconButton(favoriteButton, action: #selector(handleFavorite))
        configureIconButton(playButton, action: #selector(handlePlayPause))
        configureIconButton(shareButton, action: #selector(handleShare))

        shareButton.configuration?.image = UIImage(systemName: "square.and.arrow.up")

        let actionStack = UIStackView(arrangedSubviews: [favoriteButton, playButton, shareButton])
        actionStack.axis = .horizontal
        actionStack.alignment = .center
        actionStack.distribution = .equalSpacing
        actionStack.spacing = 18

        view.addSubview(actionBarView)
        actionBarView.contentView.addSubview(actionStack)
        actionBarView.translatesAutoresizingMaskIntoConstraints = false
        actionStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            actionBarView.trailingAnchor.constraint(equalTo: curationCardView.trailingAnchor, constant: -16),
            actionBarView.bottomAnchor.constraint(equalTo: curationCardView.topAnchor, constant: -12),
            actionBarView.widthAnchor.constraint(equalToConstant: 150),
            actionBarView.heightAnchor.constraint(equalToConstant: 40),

            actionStack.leadingAnchor.constraint(equalTo: actionBarView.contentView.leadingAnchor, constant: 22),
            actionStack.trailingAnchor.constraint(equalTo: actionBarView.contentView.trailingAnchor, constant: -22),
            actionStack.centerYAnchor.constraint(equalTo: actionBarView.contentView.centerYAnchor),

            favoriteButton.widthAnchor.constraint(equalToConstant: 26),
            favoriteButton.heightAnchor.constraint(equalToConstant: 26),
            playButton.widthAnchor.constraint(equalToConstant: 26),
            playButton.heightAnchor.constraint(equalToConstant: 26),
            shareButton.widthAnchor.constraint(equalToConstant: 26),
            shareButton.heightAnchor.constraint(equalToConstant: 26)
        ])
    }

    private func configureIconButton(_ button: UIButton, action: Selector) {
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = UIColor.white.withAlphaComponent(0.92)
        configuration.contentInsets = .zero
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 19, weight: .semibold)
        button.configuration = configuration
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    private func configureSaveButton() {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "保存壁纸"
        configuration.image = UIImage(systemName: "arrow.down.to.line")
        configuration.imagePadding = 7
        configuration.baseBackgroundColor = UIColor(red: 1.00, green: 0.82, blue: 0.55, alpha: 1)
        configuration.baseForegroundColor = UIColor(red: 0.21, green: 0.16, blue: 0.10, alpha: 1)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 14, weight: .bold)
            return outgoing
        }
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)

        saveButton.configuration = configuration
        saveButton.layer.cornerRadius = 23
        saveButton.layer.cornerCurve = .continuous
        saveButton.clipsToBounds = true
        saveButton.addTarget(self, action: #selector(handleDownload), for: .touchUpInside)
    }

    private func configureHomeIndicator() {
        homeIndicatorView.backgroundColor = UIColor.white.withAlphaComponent(0.92)
        homeIndicatorView.layer.cornerRadius = 2
        homeIndicatorView.layer.cornerCurve = .continuous
        homeIndicatorView.isUserInteractionEnabled = false

        view.addSubview(homeIndicatorView)
        homeIndicatorView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            homeIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            homeIndicatorView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -2),
            homeIndicatorView.widthAnchor.constraint(equalToConstant: 134),
            homeIndicatorView.heightAnchor.constraint(equalToConstant: 4)
        ])
    }

    private func configureTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handlePreviewTap))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }

    private func configureSwipeGestures() {
        let swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleWallpaperSwipe(_:)))
        swipeUpGesture.direction = .up
        swipeUpGesture.delegate = self

        let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleWallpaperSwipe(_:)))
        swipeDownGesture.direction = .down
        swipeDownGesture.delegate = self

        view.addGestureRecognizer(swipeUpGesture)
        view.addGestureRecognizer(swipeDownGesture)
    }

    // MARK: - Actions

    @objc
    private func handlePreviewTap() {
        isChromeVisible.toggle()
        updateChromeVisibility(animated: true)
    }

    @objc
    private func handleWallpaperSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard pages.count > 1 else { return }

        switch gesture.direction {
        case .up:
            showAdjacentWallpaper(offset: 1)
        case .down:
            showAdjacentWallpaper(offset: -1)
        default:
            break
        }
    }

    @objc
    private func handleBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc
    private func handleFavorite() {
        isFavorite = FavoriteWallpaperStore.shared.toggleFavorite(page)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        updateFavoriteButton()
    }

    @objc
    private func handlePlayPause() {
        isPlaying.toggle()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if isPlaying {
            wallpaperVideoView.play()
        } else {
            wallpaperVideoView.pause()
        }
        updatePlayButton()
    }

    @objc
    private func handleShare() {
        var activityItems: [Any] = []
        if let image = wallpaperSnapshotImage() {
            activityItems.append(image)
        }
        activityItems.append("\(page.title)\n\(page.subtitle)\n\(page.videoURL.absoluteString)")

        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = shareButton
        activityViewController.popoverPresentationController?.sourceRect = shareButton.bounds
        present(activityViewController, animated: true)
    }

    @objc
    private func handleDownload() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let subscriptionViewController = SubscriptionViewController(videoResource: OnboardingVideoProvider.shared.selectedResource)
        subscriptionViewController.hidesBottomBarWhenPushed = true

        if let navigationController {
            navigationController.pushViewController(subscriptionViewController, animated: true)
        } else {
            let navigationController = UINavigationController(rootViewController: subscriptionViewController)
            navigationController.modalPresentationStyle = .fullScreen
            navigationController.setNavigationBarHidden(true, animated: false)
            present(navigationController, animated: true)
        }
    }

    // MARK: - State

    private func updateChromeVisibility(animated: Bool) {
        let changes = {
            self.headerView.alpha = 1
            self.curationCardView.alpha = 1
            self.actionBarView.alpha = self.isChromeVisible ? 1 : 0
            self.lockStatusLabel.alpha = self.isChromeVisible ? 0.18 : 1
            self.dateLabel.alpha = self.isChromeVisible ? 0.18 : 1
            self.timeLabel.alpha = self.isChromeVisible ? 0.18 : 1
            self.dimOverlayView.backgroundColor = UIColor.black.withAlphaComponent(self.isChromeVisible ? 0.22 : 0.16)
        }

        guard animated, !UIAccessibility.isReduceMotionEnabled else {
            changes()
            return
        }

        let shownTransform = CGAffineTransform.identity
        let hiddenBottomTransform = CGAffineTransform(translationX: 0, y: 16)

        if isChromeVisible {
            actionBarView.transform = hiddenBottomTransform
        }

        UIView.animate(
            withDuration: 0.26,
            delay: 0,
            options: [.curveEaseOut, .beginFromCurrentState]
        ) {
            changes()
            self.headerView.transform = shownTransform
            self.curationCardView.transform = shownTransform
            self.actionBarView.transform = self.isChromeVisible ? shownTransform : hiddenBottomTransform
        }
    }

    private func updateFavoriteButton() {
        let imageName = isFavorite ? "heart.fill" : "heart"
        favoriteButton.configuration?.image = UIImage(systemName: imageName)
        favoriteButton.configuration?.baseForegroundColor = isFavorite
            ? UIColor(red: 1.00, green: 0.82, blue: 0.55, alpha: 1)
            : UIColor.white.withAlphaComponent(0.92)
    }

    private func updatePlayButton() {
        let imageName = isPlaying ? "pause.circle" : "play.circle"
        playButton.configuration?.image = UIImage(systemName: imageName)
    }

    private func updatePageMetadata() {
        titleLabel.text = page.title
        pageCounterLabel.text = String(format: "%02d / %02d", currentPageIndex + 1, pages.count)
        lockStatusLabel.text = page.theme.displayTitle
        curationEyebrowLabel.text = page.theme.displayTitle
        curationTitleLabel.text = page.title
        curationSubtitleLabel.text = page.subtitle
        updateCurationTags()
    }

    private func updateCurationTags() {
        curationTagStackView.arrangedSubviews.forEach { view in
            curationTagStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let tags = page.tags.isEmpty ? [page.theme.displayTitle] : Array(page.tags.prefix(3))
        tags.forEach { tag in
            let label = InsetLabel(top: 4, left: 8, bottom: 4, right: 8)
            label.text = tag
            label.font = .systemFont(ofSize: 10, weight: .semibold)
            label.textColor = UIColor.white.withAlphaComponent(0.72)
            label.backgroundColor = UIColor.white.withAlphaComponent(0.10)
            label.layer.cornerRadius = 8
            label.layer.cornerCurve = .continuous
            label.clipsToBounds = true
            curationTagStackView.addArrangedSubview(label)
        }
    }

    // MARK: - Helpers

    private func showAdjacentWallpaper(offset: Int) {
        let nextIndex = wrappedPageIndex(from: currentPageIndex + offset)
        guard nextIndex != currentPageIndex else { return }

        let previousDirection: CGFloat = offset > 0 ? -1 : 1
        currentPageIndex = nextIndex
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        applyCurrentPageTransition(verticalDirection: previousDirection)
    }

    private func wrappedPageIndex(from index: Int) -> Int {
        let count = pages.count
        let remainder = index % count
        return remainder >= 0 ? remainder : remainder + count
    }

    private func applyCurrentPageTransition(verticalDirection: CGFloat) {
        updatePageMetadata()
        isFavorite = FavoriteWallpaperStore.shared.isFavorite(page)
        updateFavoriteButton()
        startPlaybackIfPossible()

        guard !UIAccessibility.isReduceMotionEnabled else { return }

        let offsetY = verticalDirection * view.bounds.height * 0.08
        let originalTransform = wallpaperVideoView.transform
        wallpaperVideoView.alpha = 0.35
        wallpaperVideoView.transform = CGAffineTransform(translationX: 0, y: -offsetY)
        dimOverlayView.alpha = 0.72

        UIView.animate(
            withDuration: 0.24,
            delay: 0,
            options: [.curveEaseOut, .beginFromCurrentState]
        ) {
            self.wallpaperVideoView.alpha = 1
            self.wallpaperVideoView.transform = originalTransform
            self.dimOverlayView.alpha = 1
        }
    }

    private func startPlaybackIfPossible() {
        VideoCacheService.shared.recordVisitedDetailURL(page.videoURL)
        wallpaperVideoView.configure(url: page.videoURL, isMuted: false, videoGravity: .resizeAspectFill)
        isPlaying = true
        wallpaperVideoView.play()
        updatePlayButton()
    }

    private func wallpaperSnapshotImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: wallpaperVideoView.bounds)
        return renderer.image { context in
            wallpaperVideoView.layer.render(in: context.cgContext)
        }
    }

    private func currentTimeText() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }

    private func currentDateText() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "M 月 d 日 EEEE"
        return formatter.string(from: Date())
    }
}

// MARK: - UIGestureRecognizerDelegate

extension HeartQuoteDetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let touchedView = touch.view
        return touchedView?.isDescendant(of: headerView) != true
            && touchedView?.isDescendant(of: actionBarView) != true
            && touchedView?.isDescendant(of: curationCardView) != true
    }
}

private final class InsetLabel: UILabel {

    private let insets: UIEdgeInsets

    init(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
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
