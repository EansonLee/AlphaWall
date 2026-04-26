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
    private var isTimerPanelVisible = false
    private var selectedTimerMinutes = 5
    private var countdownRemainingSeconds = 0
    private var countdownTimer: Timer?
    private let timerOptions = [5, 10, 15, 30, 45, 60]

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
    private let timerPanelView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let timerTitleLabel = UILabel()
    private let timerValueLabel = UILabel()
    private let timerPickerView = UIPickerView()
    private let timerCloseButton = UIButton(type: .system)
    private let timerConfirmButton = UIButton(type: .system)

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
        countdownTimer?.invalidate()
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
        configureTimerPanel()
        configureHomeIndicator()
        configureTapGesture()
        updatePlayPauseButton()
        updateListVisibility(animated: false)
        updateTimerPanelVisibility(animated: false)
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
        configuration.baseForegroundColor = UIColor.white.withAlphaComponent(0.76)
        configuration.contentInsets = .zero
        configuration.image = UIImage(systemName: "chevron.backward")
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 19, weight: .medium)
        backButton.configuration = configuration
        backButton.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        backButton.layer.cornerRadius = 23
        backButton.layer.cornerCurve = .continuous
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)

        view.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 22),
            backButton.widthAnchor.constraint(equalToConstant: 46),
            backButton.heightAnchor.constraint(equalToConstant: 46)
        ])
    }

    private func configureInfo() {
        titleLabel.text = selectedItem.title
        titleLabel.font = .systemFont(ofSize: 23, weight: .heavy)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2

        countPillView.layer.cornerRadius = 9
        countPillView.layer.cornerCurve = .continuous
        countPillView.clipsToBounds = true
        countPillView.backgroundColor = UIColor.black.withAlphaComponent(0.14)

        let headphoneIcon = UIImageView(image: UIImage(systemName: "waveform.path.ecg"))
        headphoneIcon.tintColor = UIColor.white.withAlphaComponent(0.84)
        headphoneIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)

        countLabel.text = "\(selectedItem.listenerCount)人正在听"
        countLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        countLabel.textColor = UIColor.white.withAlphaComponent(0.82)

        let countStack = UIStackView(arrangedSubviews: [headphoneIcon, countLabel])
        countStack.axis = .horizontal
        countStack.alignment = .center
        countStack.spacing = 7

        view.addSubview(titleLabel)
        view.addSubview(countPillView)
        countPillView.contentView.addSubview(countStack)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        countPillView.translatesAutoresizingMaskIntoConstraints = false
        countStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            titleLabel.bottomAnchor.constraint(equalTo: countPillView.topAnchor, constant: -12),

            countPillView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            countPillView.bottomAnchor.constraint(equalTo: playPauseButton.topAnchor, constant: -38),
            countPillView.heightAnchor.constraint(equalToConstant: 36),

            countStack.leadingAnchor.constraint(equalTo: countPillView.contentView.leadingAnchor, constant: 12),
            countStack.trailingAnchor.constraint(equalTo: countPillView.contentView.trailingAnchor, constant: -12),
            countStack.centerYAnchor.constraint(equalTo: countPillView.contentView.centerYAnchor)
        ])
    }

    private func configureControls() {
        configureSecondaryControl(listButton, systemImageName: "square.grid.3x3")
        configureSecondaryControl(timerButton, systemImageName: "timer.circle")

        var playConfiguration = UIButton.Configuration.filled()
        playConfiguration.baseBackgroundColor = UIColor(red: 0.22, green: 0.18, blue: 0.15, alpha: 0.86)
        playConfiguration.baseForegroundColor = .white
        playConfiguration.contentInsets = .zero
        playConfiguration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        playPauseButton.configuration = playConfiguration
        playPauseButton.layer.cornerRadius = 52
        playPauseButton.layer.cornerCurve = .continuous
        playPauseButton.layer.borderWidth = 2
        playPauseButton.layer.borderColor = UIColor.white.withAlphaComponent(0.28).cgColor
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
            playPauseButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -64),
            playPauseButton.widthAnchor.constraint(equalToConstant: 104),
            playPauseButton.heightAnchor.constraint(equalToConstant: 104),

            listButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            listButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            listButton.widthAnchor.constraint(equalToConstant: 48),
            listButton.heightAnchor.constraint(equalToConstant: 48),

            timerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            timerButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            timerButton.widthAnchor.constraint(equalToConstant: 56),
            timerButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func configureSecondaryControl(_ button: UIButton, systemImageName: String) {
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = UIColor.white.withAlphaComponent(0.80)
        configuration.contentInsets = .zero
        configuration.image = UIImage(systemName: systemImageName)
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 25, weight: .regular)
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
            homeIndicatorView.widthAnchor.constraint(equalToConstant: 118),
            homeIndicatorView.heightAnchor.constraint(equalToConstant: 4)
        ])
    }

    private func configureListOverlay() {
        listOverlayView.layer.cornerRadius = 22
        listOverlayView.layer.cornerCurve = .continuous
        listOverlayView.layer.borderWidth = 1
        listOverlayView.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        listOverlayView.clipsToBounds = true

        listGridView.axis = .vertical
        listGridView.spacing = 14

        view.addSubview(listOverlayView)
        listOverlayView.contentView.addSubview(listGridView)
        listOverlayView.translatesAutoresizingMaskIntoConstraints = false
        listGridView.translatesAutoresizingMaskIntoConstraints = false

        renderListCards()

        NSLayoutConstraint.activate([
            listOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            listOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            listOverlayView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -38),
            listOverlayView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.52),

            listGridView.topAnchor.constraint(equalTo: listOverlayView.contentView.topAnchor, constant: 16),
            listGridView.leadingAnchor.constraint(equalTo: listOverlayView.contentView.leadingAnchor, constant: 16),
            listGridView.trailingAnchor.constraint(equalTo: listOverlayView.contentView.trailingAnchor, constant: -16),
            listGridView.bottomAnchor.constraint(lessThanOrEqualTo: listOverlayView.contentView.bottomAnchor, constant: -16)
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
            rowView.spacing = 14
            rowView.heightAnchor.constraint(equalToConstant: 152).isActive = true

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

    private func configureTimerPanel() {
        timerPanelView.layer.cornerRadius = 24
        timerPanelView.layer.cornerCurve = .continuous
        timerPanelView.layer.borderWidth = 1
        timerPanelView.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        timerPanelView.clipsToBounds = true

        timerTitleLabel.text = "定时"
        timerTitleLabel.font = .systemFont(ofSize: 20, weight: .heavy)
        timerTitleLabel.textColor = .white
        timerTitleLabel.textAlignment = .center

        timerValueLabel.text = "\(selectedTimerMinutes) 分钟"
        timerValueLabel.font = .systemFont(ofSize: 32, weight: .heavy)
        timerValueLabel.textColor = .white
        timerValueLabel.textAlignment = .center

        timerPickerView.dataSource = self
        timerPickerView.delegate = self
        timerPickerView.selectRow(timerOptions.firstIndex(of: selectedTimerMinutes) ?? 0, inComponent: 0, animated: false)

        var closeConfiguration = UIButton.Configuration.plain()
        closeConfiguration.image = UIImage(systemName: "xmark.circle")
        closeConfiguration.baseForegroundColor = UIColor.white.withAlphaComponent(0.92)
        closeConfiguration.contentInsets = .zero
        closeConfiguration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
        timerCloseButton.configuration = closeConfiguration
        timerCloseButton.addTarget(self, action: #selector(handleTimerClose), for: .touchUpInside)

        var confirmConfiguration = UIButton.Configuration.filled()
        confirmConfiguration.title = "确认"
        confirmConfiguration.baseBackgroundColor = UIColor(red: 0.38, green: 0.72, blue: 1.00, alpha: 1)
        confirmConfiguration.baseForegroundColor = .white
        confirmConfiguration.cornerStyle = .capsule
        confirmConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 17, weight: .heavy)
            return outgoing
        }
        timerConfirmButton.configuration = confirmConfiguration
        timerConfirmButton.addTarget(self, action: #selector(handleTimerConfirm), for: .touchUpInside)

        view.addSubview(timerPanelView)
        [timerTitleLabel, timerValueLabel, timerPickerView, timerCloseButton, timerConfirmButton].forEach {
            timerPanelView.contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        timerPanelView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            timerPanelView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            timerPanelView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            timerPanelView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            timerPanelView.heightAnchor.constraint(equalToConstant: 286),

            timerTitleLabel.topAnchor.constraint(equalTo: timerPanelView.contentView.topAnchor, constant: 24),
            timerTitleLabel.centerXAnchor.constraint(equalTo: timerPanelView.contentView.centerXAnchor),

            timerCloseButton.centerYAnchor.constraint(equalTo: timerTitleLabel.centerYAnchor),
            timerCloseButton.trailingAnchor.constraint(equalTo: timerPanelView.contentView.trailingAnchor, constant: -22),
            timerCloseButton.widthAnchor.constraint(equalToConstant: 38),
            timerCloseButton.heightAnchor.constraint(equalToConstant: 38),

            timerValueLabel.topAnchor.constraint(equalTo: timerTitleLabel.bottomAnchor, constant: 24),
            timerValueLabel.centerXAnchor.constraint(equalTo: timerPanelView.contentView.centerXAnchor),

            timerPickerView.topAnchor.constraint(equalTo: timerValueLabel.bottomAnchor, constant: 4),
            timerPickerView.centerXAnchor.constraint(equalTo: timerPanelView.contentView.centerXAnchor),
            timerPickerView.widthAnchor.constraint(equalToConstant: 190),
            timerPickerView.heightAnchor.constraint(equalToConstant: 66),

            timerConfirmButton.leadingAnchor.constraint(equalTo: timerPanelView.contentView.leadingAnchor, constant: 24),
            timerConfirmButton.trailingAnchor.constraint(equalTo: timerPanelView.contentView.trailingAnchor, constant: -24),
            timerConfirmButton.bottomAnchor.constraint(equalTo: timerPanelView.contentView.bottomAnchor, constant: -22),
            timerConfirmButton.heightAnchor.constraint(equalToConstant: 54)
        ])
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

    private func updateTimerButtonAppearance() {
        if countdownRemainingSeconds > 0 {
            timerButton.configuration?.image = UIImage(systemName: "timer.circle.fill")
            timerButton.configuration?.title = formattedCountdown()
            timerButton.configuration?.imagePlacement = .top
            timerButton.configuration?.imagePadding = 2
            timerButton.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .monospacedDigitSystemFont(ofSize: 10, weight: .bold)
                return outgoing
            }
        } else {
            timerButton.configuration?.image = UIImage(systemName: "timer.circle")
            timerButton.configuration?.title = nil
            timerButton.configuration?.imagePlacement = .top
        }
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

    private func updateTimerPanelVisibility(animated: Bool) {
        let changes = {
            self.timerPanelView.alpha = self.isTimerPanelVisible ? 1 : 0
            self.timerPanelView.transform = self.isTimerPanelVisible
                ? .identity
                : CGAffineTransform(translationX: 0, y: 28).scaledBy(x: 0.96, y: 0.96)
            self.dimView.backgroundColor = UIColor.black.withAlphaComponent(self.isTimerPanelVisible ? 0.55 : (self.isListVisible ? 0.48 : 0.12))
        }

        timerPanelView.isUserInteractionEnabled = isTimerPanelVisible

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

    private func startCountdown(minutes: Int) {
        countdownTimer?.invalidate()
        countdownRemainingSeconds = minutes * 60
        updateTimerButtonAppearance()

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }

            self.countdownRemainingSeconds -= 1
            self.updateTimerButtonAppearance()

            if self.countdownRemainingSeconds <= 0 {
                timer.invalidate()
                self.countdownTimer = nil
                self.pauseForCountdownCompletion()
            }
        }

        if let countdownTimer {
            RunLoop.main.add(countdownTimer, forMode: .common)
        }
    }

    private func pauseForCountdownCompletion() {
        countdownRemainingSeconds = 0
        updateTimerButtonAppearance()
        isPlaying = false
        videoView.pause()
        updatePlayPauseButton()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func formattedCountdown() -> String {
        let minutes = max(0, countdownRemainingSeconds) / 60
        let seconds = max(0, countdownRemainingSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
        if isListVisible {
            isListVisible = false
            updateListVisibility(animated: true)
        }
        isTimerPanelVisible.toggle()
        updateTimerPanelVisibility(animated: true)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @objc
    private func handleScreenTap() {
        guard !isTimerPanelVisible else {
            isTimerPanelVisible = false
            updateTimerPanelVisibility(animated: true)
            return
        }

        isListVisible.toggle()
        updateListVisibility(animated: true)
    }

    @objc
    private func handleOverlayItemTap(_ sender: AudioTherapyPlayerItemTapGestureRecognizer) {
        applySelectedItem(sender.item)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    @objc
    private func handleTimerClose() {
        isTimerPanelVisible = false
        updateTimerPanelVisibility(animated: true)
    }

    @objc
    private func handleTimerConfirm() {
        startCountdown(minutes: selectedTimerMinutes)
        isTimerPanelVisible = false
        updateTimerPanelVisibility(animated: true)
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
            && touchedView.isDescendant(of: timerPanelView) == false
    }
}

extension AudioTherapyPlayerViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        timerOptions.count
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        32
    }

    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        160
    }

    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let minutes = timerOptions[row]
        return NSAttributedString(
            string: "\(minutes) 分钟",
            attributes: [
                .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.92)
            ]
        )
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedTimerMinutes = timerOptions[row]
        timerValueLabel.text = "\(selectedTimerMinutes) 分钟"
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

        imageView.layer.cornerRadius = 40
        imageView.layer.cornerCurve = .continuous
        imageView.layer.masksToBounds = true

        playBadgeView.backgroundColor = item.accentColor.withAlphaComponent(0.78)
        playBadgeView.layer.cornerRadius = 19
        playBadgeView.layer.cornerCurve = .continuous
        playBadgeView.layer.borderWidth = 4
        playBadgeView.layer.borderColor = UIColor.white.withAlphaComponent(0.42).cgColor

        let playIcon = UIImageView(image: UIImage(systemName: "play.fill"))
        playIcon.tintColor = .white
        playIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        playBadgeView.addSubview(playIcon)
        playIcon.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 16, weight: .heavy)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.78

        countLabel.font = .systemFont(ofSize: 13, weight: .medium)
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
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80),

            playBadgeView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 13),
            playBadgeView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 5),
            playBadgeView.widthAnchor.constraint(equalToConstant: 38),
            playBadgeView.heightAnchor.constraint(equalToConstant: 38),

            playIcon.centerXAnchor.constraint(equalTo: playBadgeView.centerXAnchor, constant: 2),
            playIcon.centerYAnchor.constraint(equalTo: playBadgeView.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),

            countLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
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
