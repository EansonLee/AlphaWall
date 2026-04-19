//
//  HeartQuoteDetailViewController.swift
//  HeartWall
//

import UIKit

final class HeartQuoteDetailViewController: BaseViewController {

    // MARK: - Properties

    private let page: HeartQuotePage
    private var isChromeVisible = false
    private var isFavorite = false
    private var isPlaying = false

    // MARK: - UI

    private let wallpaperImageView = UIImageView()
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
    private let vipBadgeView = UIView()
    private let vipBadgeLabel = UILabel()
    private let actionBarView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let favoriteButton = UIButton(type: .system)
    private let playButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    private let downloadButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private let homeIndicatorView = UIView()

    // MARK: - Lifecycle

    init(page: HeartQuotePage) {
        self.page = page
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
        configureWallpaper()
        configureGradients()
        configureLockPreview()
        configureHeader()
        configureActions()
        configureSaveButton()
        configureHomeIndicator()
        configureTapGesture()
        updateChromeVisibility(animated: false)
        updateFavoriteButton()
        updatePlayButton()
    }

    private func configureWallpaper() {
        wallpaperImageView.image = wallpaperImage()
        wallpaperImageView.contentMode = .scaleAspectFill
        wallpaperImageView.clipsToBounds = true

        dimOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.20)

        view.addSubview(wallpaperImageView)
        view.addSubview(dimOverlayView)
        wallpaperImageView.translatesAutoresizingMaskIntoConstraints = false
        dimOverlayView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            wallpaperImageView.topAnchor.constraint(equalTo: view.topAnchor),
            wallpaperImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wallpaperImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            wallpaperImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            dimOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            dimOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureGradients() {
        topFadeLayer.colors = [
            UIColor.black.withAlphaComponent(0.48).cgColor,
            UIColor.black.withAlphaComponent(0.14).cgColor,
            UIColor.clear.cgColor
        ]
        topFadeLayer.locations = [0, 0.55, 1]
        topFadeView.isUserInteractionEnabled = false
        topFadeView.layer.addSublayer(topFadeLayer)

        bottomFadeLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.42).cgColor,
            UIColor.black.withAlphaComponent(0.76).cgColor
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
            topFadeView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.32),

            bottomFadeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomFadeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomFadeView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomFadeView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.35)
        ])
    }

    private func configureLockPreview() {
        lockStatusLabel.text = "James Branch Cabell · 未来"
        lockStatusLabel.font = .italicSystemFont(ofSize: 10)
        lockStatusLabel.textColor = UIColor.white.withAlphaComponent(0.56)
        lockStatusLabel.textAlignment = .center

        dateLabel.text = currentDateText()
        dateLabel.font = .systemFont(ofSize: 19, weight: .semibold)
        dateLabel.textColor = UIColor.white.withAlphaComponent(0.88)
        dateLabel.textAlignment = .center

        timeLabel.text = currentTimeText()
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 82, weight: .semibold)
        timeLabel.textColor = UIColor.white.withAlphaComponent(0.96)
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
            lockStatusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 54),
            lockStatusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            lockStatusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            lockStatusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),

            dateLabel.topAnchor.constraint(equalTo: lockStatusLabel.bottomAnchor, constant: 1),
            dateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),

            timeLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 2),
            timeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26),
            timeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -26)
        ])
    }

    private func configureHeader() {
        titleLabel.text = page.title
        titleLabel.font = .systemFont(ofSize: 17, weight: .heavy)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.94)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1

        var backConfiguration = UIButton.Configuration.plain()
        backConfiguration.baseForegroundColor = UIColor.white.withAlphaComponent(0.90)
        backConfiguration.contentInsets = .zero
        backConfiguration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        backButton.configuration = backConfiguration
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.backgroundColor = UIColor.white.withAlphaComponent(0.18)
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
        headerView.addSubview(vipBadgeView)
        vipBadgeView.addSubview(vipBadgeLabel)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        vipBadgeView.translatesAutoresizingMaskIntoConstraints = false
        vipBadgeLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            headerView.heightAnchor.constraint(equalToConstant: 40),

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: vipBadgeView.leadingAnchor, constant: -14),

            vipBadgeView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -2),
            vipBadgeView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            vipBadgeView.widthAnchor.constraint(equalToConstant: 23),
            vipBadgeView.heightAnchor.constraint(equalToConstant: 23),

            vipBadgeLabel.centerXAnchor.constraint(equalTo: vipBadgeView.centerXAnchor),
            vipBadgeLabel.centerYAnchor.constraint(equalTo: vipBadgeView.centerYAnchor)
        ])
    }

    private func configureActions() {
        actionBarView.layer.cornerRadius = 24
        actionBarView.layer.cornerCurve = .continuous
        actionBarView.clipsToBounds = true
        actionBarView.layer.borderWidth = 1
        actionBarView.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor

        configureIconButton(favoriteButton, action: #selector(handleFavorite))
        configureIconButton(playButton, action: #selector(handlePlayPause))
        configureIconButton(shareButton, action: #selector(handleShare))
        configureDownloadButton()

        shareButton.configuration?.image = UIImage(systemName: "square.and.arrow.up")

        let actionStack = UIStackView(arrangedSubviews: [favoriteButton, playButton, shareButton])
        actionStack.axis = .horizontal
        actionStack.alignment = .center
        actionStack.distribution = .equalSpacing
        actionStack.spacing = 18

        view.addSubview(actionBarView)
        actionBarView.contentView.addSubview(actionStack)
        view.addSubview(downloadButton)
        actionBarView.translatesAutoresizingMaskIntoConstraints = false
        actionStack.translatesAutoresizingMaskIntoConstraints = false
        downloadButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            actionBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            actionBarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            actionBarView.widthAnchor.constraint(equalToConstant: 186),
            actionBarView.heightAnchor.constraint(equalToConstant: 49),

            actionStack.leadingAnchor.constraint(equalTo: actionBarView.contentView.leadingAnchor, constant: 30),
            actionStack.trailingAnchor.constraint(equalTo: actionBarView.contentView.trailingAnchor, constant: -30),
            actionStack.centerYAnchor.constraint(equalTo: actionBarView.contentView.centerYAnchor),

            favoriteButton.widthAnchor.constraint(equalToConstant: 30),
            favoriteButton.heightAnchor.constraint(equalToConstant: 30),
            playButton.widthAnchor.constraint(equalToConstant: 30),
            playButton.heightAnchor.constraint(equalToConstant: 30),
            shareButton.widthAnchor.constraint(equalToConstant: 30),
            shareButton.heightAnchor.constraint(equalToConstant: 30),

            downloadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -17),
            downloadButton.centerYAnchor.constraint(equalTo: actionBarView.centerYAnchor),
            downloadButton.widthAnchor.constraint(equalToConstant: 87),
            downloadButton.heightAnchor.constraint(equalToConstant: 49)
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

    private func configureDownloadButton() {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = UIColor(red: 1.00, green: 0.82, blue: 0.55, alpha: 1)
        configuration.baseForegroundColor = UIColor(red: 0.21, green: 0.16, blue: 0.10, alpha: 1)
        configuration.contentInsets = .zero
        configuration.image = UIImage(systemName: "arrow.down.to.line")
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        downloadButton.configuration = configuration
        downloadButton.layer.cornerRadius = 24.5
        downloadButton.layer.cornerCurve = .continuous
        downloadButton.clipsToBounds = true
        downloadButton.addTarget(self, action: #selector(handleDownload), for: .touchUpInside)
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
        saveButton.layer.cornerRadius = 25
        saveButton.layer.cornerCurve = .continuous
        saveButton.clipsToBounds = true
        saveButton.addTarget(self, action: #selector(handleDownload), for: .touchUpInside)

        view.addSubview(saveButton)
        saveButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            saveButton.widthAnchor.constraint(equalToConstant: 204),
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
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

    // MARK: - Actions

    @objc
    private func handlePreviewTap() {
        isChromeVisible.toggle()
        updateChromeVisibility(animated: true)
    }

    @objc
    private func handleBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc
    private func handleFavorite() {
        isFavorite.toggle()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        updateFavoriteButton()
    }

    @objc
    private func handlePlayPause() {
        isPlaying.toggle()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        updatePlayButton()
    }

    @objc
    private func handleShare() {
        var activityItems: [Any] = []
        if let image = wallpaperImage() {
            activityItems.append(image)
        }
        activityItems.append("\(page.title)\n\(page.subtitle)")

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
            self.headerView.alpha = self.isChromeVisible ? 1 : 0
            self.actionBarView.alpha = self.isChromeVisible ? 1 : 0
            self.downloadButton.alpha = self.isChromeVisible ? 1 : 0
            self.saveButton.alpha = self.isChromeVisible ? 0 : 1
            self.lockStatusLabel.alpha = self.isChromeVisible ? 0 : 1
            self.dateLabel.alpha = self.isChromeVisible ? 0 : 1
            self.timeLabel.alpha = self.isChromeVisible ? 0 : 1
            self.dimOverlayView.backgroundColor = UIColor.black.withAlphaComponent(self.isChromeVisible ? 0.28 : 0.20)
        }

        guard animated, !UIAccessibility.isReduceMotionEnabled else {
            changes()
            return
        }

        let shownTransform = CGAffineTransform.identity
        let hiddenTopTransform = CGAffineTransform(translationX: 0, y: -14)
        let hiddenBottomTransform = CGAffineTransform(translationX: 0, y: 16)

        if isChromeVisible {
            headerView.transform = hiddenTopTransform
            actionBarView.transform = hiddenBottomTransform
            downloadButton.transform = hiddenBottomTransform
            saveButton.transform = shownTransform
        }

        UIView.animate(
            withDuration: 0.26,
            delay: 0,
            options: [.curveEaseOut, .beginFromCurrentState]
        ) {
            changes()
            self.headerView.transform = self.isChromeVisible ? shownTransform : hiddenTopTransform
            self.actionBarView.transform = self.isChromeVisible ? shownTransform : hiddenBottomTransform
            self.downloadButton.transform = self.isChromeVisible ? shownTransform : hiddenBottomTransform
            self.saveButton.transform = self.isChromeVisible ? hiddenBottomTransform : shownTransform
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

    // MARK: - Helpers

    private func wallpaperImage() -> UIImage? {
        UIImage(named: page.assetName)?.cropped(toNormalizedRect: page.cropRect)
            ?? UIImage(named: page.assetName)
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
            && touchedView?.isDescendant(of: downloadButton) != true
            && touchedView?.isDescendant(of: saveButton) != true
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
