//
//  AudioTherapyPlayerViewController.swift
//  HeartWall
//

import UIKit

final class AudioTherapyPlayerViewController: BaseViewController {

    private let items: [AudioTherapyItem]
    private var selectedItem: AudioTherapyItem

    private let backgroundImageView = UIImageView()
    private let dimView = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let countLabel = UILabel()

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
    }

    override func setupUI() {
        view.backgroundColor = UIColor(red: 0.03, green: 0.10, blue: 0.12, alpha: 1)
        configureBackground()
        configureHeader()
        configureTitle()
        loadBackground()
    }

    private func configureBackground() {
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.backgroundColor = UIColor(red: 0.08, green: 0.24, blue: 0.27, alpha: 1)
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.26)

        view.addSubview(backgroundImageView)
        view.addSubview(dimView)
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        dimView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureHeader() {
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = UIColor.white.withAlphaComponent(0.92)
        configuration.contentInsets = .zero
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        backButton.configuration = configuration
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.backgroundColor = UIColor.white.withAlphaComponent(0.18)
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

    private func configureTitle() {
        titleLabel.text = selectedItem.title
        titleLabel.font = .systemFont(ofSize: 27, weight: .heavy)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2

        countLabel.text = "\(selectedItem.listenerCount)人正在听"
        countLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        countLabel.textColor = UIColor.white.withAlphaComponent(0.82)

        let stackView = UIStackView(arrangedSubviews: [titleLabel, countLabel])
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 14

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -142)
        ])
    }

    private func loadBackground() {
        Task { [weak self] in
            guard let self else { return }
            let image = await VideoThumbnailLoader.shared.loadThumbnail(for: selectedItem.videoURL)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.backgroundImageView.image = image
            }
        }
    }

    @objc
    private func handleBack() {
        navigationController?.popViewController(animated: true)
    }
}
