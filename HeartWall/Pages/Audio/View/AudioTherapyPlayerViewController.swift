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
        configureHomeIndicator()
        updatePlayPauseButton()
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

    private func playSelectedItem() {
        videoView.configure(url: selectedItem.videoURL, isMuted: false, videoGravity: .resizeAspectFill)
        if isPlaying {
            videoView.play()
        }
    }

    private func updatePlayPauseButton() {
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        playPauseButton.configuration?.image = UIImage(systemName: imageName)
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
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @objc
    private func handleTimer() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
