//
//  AudioTherapyPlayerViewController.swift
//  HeartWall
//

import UIKit
import AVFoundation

final class AudioTherapyPlayerViewController: BaseViewController {

    private let items: [AudioTherapyItem]
    private var selectedItem: AudioTherapyItem
    private var isPlaying = true
    private var isListVisible = false

    private let videoView = LoopingVideoView()
    private let dimView = UIView()
    private let bottomFadeView = UIView()
    private let bottomFadeLayer = CAGradientLayer()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let countPillView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let countLabel = UILabel()
    private let listButton = UIButton(type: .system)
    private let playPauseButton = UIButton(type: .system)
    private let timerButton = UIButton(type: .system)
    private let homeIndicatorView = UIView()
    private let listOverlayView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let listGridView = UIStackView()

    init(items: [AudioTherapyItem], selectedItem: AudioTherapyItem) {
        self.items = items
        self.selectedItem = selectedItem
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        playSelectedItem()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        videoView.pause()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bottomFadeLayer.frame = bottomFadeView.bounds
    }

    override func setupUI() {
        view.backgroundColor = UIColor(red: 0.03, green: 0.10, blue: 0.12, alpha: 1)
        configureBackground()
        configureHeader()
        configureControls()
        configureInfo()
        configureListOverlay()
        configureHomeIndicator()
        configureTapGesture()
        updatePlayPauseButton()
        updateListVisibility(animated: false)
    }

    private func configureBackground() {
        videoView.backgroundColor = UIColor(red: 0.08, green: 0.24, blue: 0.27, alpha: 1)
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.12)

        bottomFadeLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.48).cgColor,
            UIColor.black.withAlphaComponent(0.82).cgColor
        ]
        bottomFadeLayer.locations = [0, 0.52, 1]
        bottomFadeView.isUserInteractionEnabled = false
        bottomFadeView.layer.addSublayer(bottomFadeLayer)

        view.addSubview(videoView)
        view.addSubview(dimView)
        view.addSubview(bottomFadeView)
        videoView.translatesAutoresizingMaskIntoConstraints = false
        dimView.translatesAutoresizingMaskIntoConstraints = false
        bottomFadeView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: view.topAnchor),
            videoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            bottomFadeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomFadeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomFadeView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomFadeView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.42)
        ])
    }

    private func configureHeader() {
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = UIColor.white.withAlphaComponent(0.72)
        configuration.contentInsets = .zero
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        backButton.configuration = configuration
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        backButton.layer.cornerRadius = 28
        backButton.layer.cornerCurve = .continuous
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)

        view.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            backButton.widthAnchor.constraint(equalToConstant: 56),
            backButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    private func configureInfo() {
        titleLabel.text = selectedItem.title
        titleLabel.font = .systemFont(ofSize: 27, weight: .heavy)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2

        countPillView.layer.cornerRadius = 10
        countPillView.layer.cornerCurve = .continuous
        countPillView.clipsToBounds = true
        countPillView.backgroundColor = UIColor.black.withAlphaComponent(0.14)

        let headphoneIcon = UIImageView(image: UIImage(systemName: "headphones"))
        headphoneIcon.tintColor = UIColor.white.withAlphaComponent(0.88)
        headphoneIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)

        countLabel.text = "\(selectedItem.listenerCount)人正在听"
        countLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        countLabel.textColor = UIColor.white.withAlphaComponent(0.82)

        let countStack = UIStackView(arrangedSubviews: [headphoneIcon, countLabel])
        countStack.axis = .horizontal
        countStack.alignment = .center
        countStack.spacing = 8

        view.addSubview(titleLabel)
        view.addSubview(countPillView)
        countPillView.contentView.addSubview(countStack)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        countPillView.translatesAutoresizingMaskIntoConstraints = false
        countStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            titleLabel.bottomAnchor.constraint(equalTo: countPillView.topAnchor, constant: -18),

            countPillView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            countPillView.bottomAnchor.constraint(equalTo: playPauseButton.topAnchor, constant: -54),
            countPillView.heightAnchor.constraint(equalToConstant: 45),

            countStack.leadingAnchor.constraint(equalTo: countPillView.contentView.leadingAnchor, constant: 14),
            countStack.trailingAnchor.constraint(equalTo: countPillView.contentView.trailingAnchor, constant: -14),
            countStack.centerYAnchor.constraint(equalTo: countPillView.contentView.centerYAnchor)
        ])
    }

    private func configureControls() {
        configureSecondaryControl(listButton, systemImageName: "square.grid.2x2")
        configureSecondaryControl(timerButton, systemImageName: "alarm")

        var playConfiguration = UIButton.Configuration.filled()
        playConfiguration.baseBackgroundColor = UIColor(red: 0.22, green: 0.18, blue: 0.15, alpha: 0.88)
        playConfiguration.baseForegroundColor = .white
        playConfiguration.contentInsets = .zero
        playConfiguration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 29, weight: .bold)
        playPauseButton.configuration = playConfiguration
        playPauseButton.layer.cornerRadius = 67
        playPauseButton.layer.cornerCurve = .continuous
        playPauseButton.layer.borderWidth = 3
        playPauseButton.layer.borderColor = UIColor.white.withAlphaComponent(0.34).cgColor
        playPauseButton.clipsToBounds = true
        playPauseButton.addTarget(self, action: #selector(handlePlayPause), for: .touchUpInside)

        listButton.addTarget(self, action: #selector(handleList), for: .touchUpInside)
        timerButton.addTarget(self, action: #selector(handleTimer), for: .touchUpInside)

        view.addSubview(listButton)
        view.addSubview(playPauseButton)
        view.addSubview(timerButton)
        listButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        timerButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            playPauseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playPauseButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -72),
            playPauseButton.widthAnchor.constraint(equalToConstant: 134),
            playPauseButton.heightAnchor.constraint(equalToConstant: 134),

            listButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            listButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            listButton.widthAnchor.constraint(equalToConstant: 56),
            listButton.heightAnchor.constraint(equalToConstant: 56),

            timerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            timerButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            timerButton.widthAnchor.constraint(equalToConstant: 56),
            timerButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    private func configureSecondaryControl(_ button: UIButton, systemImageName: String) {
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = UIColor.white.withAlphaComponent(0.78)
        configuration.contentInsets = .zero
        configuration.image = UIImage(systemName: systemImageName)
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 34, weight: .medium)
        button.configuration = configuration
    }

    private func configureHomeIndicator() {
        homeIndicatorView.backgroundColor = UIColor.white.withAlphaComponent(0.94)
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

    private func configureListOverlay() {
        listOverlayView.layer.cornerRadius = 26
        listOverlayView.layer.cornerCurve = .continuous
        listOverlayView.layer.borderWidth = 1
        listOverlayView.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        listOverlayView.clipsToBounds = true

        listGridView.axis = .vertical
        listGridView.spacing = 18

        view.addSubview(listOverlayView)
        listOverlayView.contentView.addSubview(listGridView)
        listOverlayView.translatesAutoresizingMaskIntoConstraints = false
        listGridView.translatesAutoresizingMaskIntoConstraints = false

        renderListCards()

        NSLayoutConstraint.activate([
            listOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            listOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            listOverlayView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -44),
            listOverlayView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.58),

            listGridView.topAnchor.constraint(equalTo: listOverlayView.contentView.topAnchor, constant: 18),
            listGridView.leadingAnchor.constraint(equalTo: listOverlayView.contentView.leadingAnchor, constant: 20),
            listGridView.trailingAnchor.constraint(equalTo: listOverlayView.contentView.trailingAnchor, constant: -20),
            listGridView.bottomAnchor.constraint(lessThanOrEqualTo: listOverlayView.contentView.bottomAnchor, constant: -18)
        ])
    }

    private func renderListCards() {
        listGridView.arrangedSubviews.forEach { row in
            listGridView.removeArrangedSubview(row)
            row.removeFromSuperview()
        }

        let visibleItems = Array(items.prefix(6))
        stride(from: 0, to: visibleItems.count, by: 2).forEach { start in
            let rowView = UIStackView()
            rowView.axis = .horizontal
            rowView.alignment = .fill
            rowView.distribution = .fillEqually
            rowView.spacing = 18
            rowView.heightAnchor.constraint(equalToConstant: 180).isActive = true

            [start, start + 1].forEach { index in
                if visibleItems.indices.contains(index) {
                    let cardView = AudioTherapyPlayerListCardView(item: visibleItems[index])
                    cardView.addGestureRecognizer(AudioTherapyPlayerItemTapGestureRecognizer(item: visibleItems[index], target: self, action: #selector(handleOverlayItemTap(_:))))
                    rowView.addArrangedSubview(cardView)
                } else {
                    rowView.addArrangedSubview(UIView())
                }
            }

            listGridView.addArrangedSubview(rowView)
        }
    }

    private func configureTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }

    private func playSelectedItem() {
        videoView.configure(url: selectedItem.videoURL, isMuted: false, videoGravity: .resizeAspectFill)
        if isPlaying {
            videoView.play()
        }
    }

    private func applySelectedItem(_ item: AudioTherapyItem) {
        selectedItem = item
        titleLabel.text = item.title
        countLabel.text = "\(item.listenerCount)人正在听"
        isPlaying = true
        playSelectedItem()
        updatePlayPauseButton()
        updateListVisibility(animated: true)
    }

    private func updatePlayPauseButton() {
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        playPauseButton.configuration?.image = UIImage(systemName: imageName)
    }

    private func updateListVisibility(animated: Bool) {
        let changes = {
            self.listOverlayView.alpha = self.isListVisible ? 1 : 0
            self.listOverlayView.transform = self.isListVisible
                ? .identity
                : CGAffineTransform(translationX: 0, y: 24).scaledBy(x: 0.96, y: 0.96)
            self.dimView.backgroundColor = UIColor.black.withAlphaComponent(self.isListVisible ? 0.48 : 0.12)
            self.titleLabel.alpha = self.isListVisible ? 0.18 : 1
            self.countPillView.alpha = self.isListVisible ? 0.18 : 1
        }

        listOverlayView.isUserInteractionEnabled = isListVisible

        guard animated, !UIAccessibility.isReduceMotionEnabled else {
            changes()
            return
        }

        UIView.animate(
            withDuration: 0.24,
            delay: 0,
            options: [.curveEaseOut, .beginFromCurrentState]
        ) {
            changes()
        }
    }

    @objc
    private func handleBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc
    private func handlePlayPause() {
        isPlaying.toggle()
        if isPlaying {
            videoView.play()
        } else {
            videoView.pause()
        }
        updatePlayPauseButton()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @objc
    private func handleList() {
        isListVisible.toggle()
        updateListVisibility(animated: true)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @objc
    private func handleTimer() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @objc
    private func handleScreenTap() {
        isListVisible.toggle()
        updateListVisibility(animated: true)
    }

    @objc
    private func handleOverlayItemTap(_ sender: AudioTherapyPlayerItemTapGestureRecognizer) {
        applySelectedItem(sender.item)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

extension AudioTherapyPlayerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer is UITapGestureRecognizer else { return true }
        guard let touchedView = touch.view else { return true }

        return touchedView.isDescendant(of: backButton) == false
            && touchedView.isDescendant(of: listButton) == false
            && touchedView.isDescendant(of: playPauseButton) == false
            && touchedView.isDescendant(of: timerButton) == false
            && touchedView.isDescendant(of: listOverlayView) == false
    }
}

private final class AudioTherapyPlayerListCardView: UIView {

    private let item: AudioTherapyItem
    private let imageView = PlayerVideoThumbnailImageView()
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
        backgroundColor = item.accentColor.withAlphaComponent(0.92)
        layer.cornerRadius = 8
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.13).cgColor
        clipsToBounds = true
        isUserInteractionEnabled = true

        imageView.layer.cornerRadius = 50
        imageView.layer.cornerCurve = .continuous
        imageView.layer.masksToBounds = true

        playBadgeView.backgroundColor = item.accentColor.withAlphaComponent(0.78)
        playBadgeView.layer.cornerRadius = 24
        playBadgeView.layer.cornerCurve = .continuous
        playBadgeView.layer.borderWidth = 5
        playBadgeView.layer.borderColor = UIColor.white.withAlphaComponent(0.42).cgColor

        let playIcon = UIImageView(image: UIImage(systemName: "play.fill"))
        playIcon.tintColor = .white
        playIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        playBadgeView.addSubview(playIcon)
        playIcon.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 19, weight: .heavy)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.78

        countLabel.font = .systemFont(ofSize: 15, weight: .medium)
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
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            imageView.widthAnchor.constraint(equalToConstant: 100),
            imageView.heightAnchor.constraint(equalToConstant: 100),

            playBadgeView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 18),
            playBadgeView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 5),
            playBadgeView.widthAnchor.constraint(equalToConstant: 48),
            playBadgeView.heightAnchor.constraint(equalToConstant: 48),

            playIcon.centerXAnchor.constraint(equalTo: playBadgeView.centerXAnchor, constant: 2),
            playIcon.centerYAnchor.constraint(equalTo: playBadgeView.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),

            countLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 7),
            countLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            countLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
        ])
    }

    private func apply(item: AudioTherapyItem) {
        imageView.configure(videoURL: item.videoURL)
        titleLabel.text = item.title
        countLabel.text = "\(item.listenerCount)人正在听"
    }
}

private final class AudioTherapyPlayerItemTapGestureRecognizer: UITapGestureRecognizer {
    let item: AudioTherapyItem

    init(item: AudioTherapyItem, target: AnyObject?, action: Selector?) {
        self.item = item
        super.init(target: target, action: action)
    }
}

private final class PlayerVideoThumbnailImageView: UIImageView {

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
