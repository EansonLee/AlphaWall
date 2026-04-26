//
//  FavoriteWallpapersViewController.swift
//  HeartWall
//

import UIKit
import Combine

final class FavoriteWallpapersViewController: BaseViewController {

    private let loader = ThemeCatalogLoader()
    private var allPages: [HeartQuotePage] = []
    private var favoritePages: [HeartQuotePage] = []

    private let backgroundView = AuroraBackgroundView()
    private let dimView = UIView()
    private let headerView = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    private let collectionView: UICollectionView
    private let emptyStateView = UIView()
    private let emptyIconView = UIImageView()
    private let emptyTitleLabel = UILabel()
    private let emptySubtitleLabel = UILabel()

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadWallpapers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        backgroundView.startAnimatingIfNeeded()
        refreshFavorites()
    }

    override func setupUI() {
        view.backgroundColor = UIColor(red: 0.06, green: 0.10, blue: 0.14, alpha: 1)
        configureBackground()
        configureHeader()
        configureCollectionView()
        configureEmptyState()
    }

    override func setupBindings() {
        NotificationCenter.default.publisher(for: FavoriteWallpaperStore.favoritesDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshFavorites()
            }
            .store(in: &cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func configureBackground() {
        view.addSubview(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.26)
        view.addSubview(dimView)
        dimView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureHeader() {
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = UIColor.white.withAlphaComponent(0.92)
        backButton.backgroundColor = UIColor.white.withAlphaComponent(0.14)
        backButton.layer.cornerRadius = 16
        backButton.layer.cornerCurve = .continuous
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)

        titleLabel.text = "喜欢的壁纸"
        titleLabel.font = .systemFont(ofSize: 24, weight: .heavy)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.96)

        countLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        countLabel.textColor = UIColor.white.withAlphaComponent(0.56)

        view.addSubview(headerView)
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        headerView.addSubview(countLabel)

        headerView.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            headerView.heightAnchor.constraint(equalToConstant: 44),

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 14),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            countLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 12),
            countLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            countLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
    }

    private func configureCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 34, right: 0)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(FavoriteWallpaperCell.self, forCellWithReuseIdentifier: FavoriteWallpaperCell.reuseIdentifier)

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 14),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureEmptyState() {
        emptyStateView.isHidden = true
        emptyStateView.isUserInteractionEnabled = false

        emptyIconView.image = UIImage(systemName: "heart.slash")
        emptyIconView.tintColor = UIColor(red: 1.00, green: 0.86, blue: 0.62, alpha: 0.86)
        emptyIconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 30, weight: .semibold)

        emptyTitleLabel.text = "还没有喜欢的壁纸"
        emptyTitleLabel.font = .systemFont(ofSize: 18, weight: .heavy)
        emptyTitleLabel.textColor = UIColor.white.withAlphaComponent(0.92)
        emptyTitleLabel.textAlignment = .center

        emptySubtitleLabel.text = "在壁纸详情页点亮喜欢后会出现在这里"
        emptySubtitleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        emptySubtitleLabel.textColor = UIColor.white.withAlphaComponent(0.56)
        emptySubtitleLabel.textAlignment = .center
        emptySubtitleLabel.numberOfLines = 2

        let stackView = UIStackView(arrangedSubviews: [emptyIconView, emptyTitleLabel, emptySubtitleLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 10

        view.addSubview(emptyStateView)
        emptyStateView.addSubview(stackView)
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 34),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -34),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -16),

            stackView.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor)
        ])
    }

    private func loadWallpapers() {
        do {
            let catalog = try loader.loadAllThemes()
            allPages = HeartQuoteTheme.allCases.flatMap { catalog[$0] ?? [] }
            refreshFavorites()
        } catch {
            allPages = []
            refreshFavorites()
            showError(error.localizedDescription)
        }
    }

    private func refreshFavorites() {
        favoritePages = FavoriteWallpaperStore.shared.favoritePages(from: allPages)
        countLabel.text = "\(favoritePages.count) 张"
        emptyStateView.isHidden = !favoritePages.isEmpty
        collectionView.isHidden = favoritePages.isEmpty
        collectionView.reloadData()
    }

    @objc
    private func handleBack() {
        navigationController?.popViewController(animated: true)
    }
}

extension FavoriteWallpapersViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        favoritePages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FavoriteWallpaperCell.reuseIdentifier, for: indexPath) as? FavoriteWallpaperCell else {
            return UICollectionViewCell()
        }

        cell.configure(page: favoritePages[indexPath.item])
        return cell
    }
}

extension FavoriteWallpapersViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard favoritePages.indices.contains(indexPath.item) else { return }
        let viewController = HeartQuoteDetailViewController(pages: favoritePages, initialIndex: indexPath.item)
        viewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(viewController, animated: true)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let availableWidth = collectionView.bounds.width
        let columnSpacing: CGFloat = 12
        let itemWidth = floor((availableWidth - columnSpacing) / 2)
        return CGSize(width: itemWidth, height: itemWidth * 1.42)
    }
}

private final class FavoriteWallpaperCell: UICollectionViewCell {

    static let reuseIdentifier = "FavoriteWallpaperCell"

    private let imageView = FavoriteWallpaperThumbnailView()
    private let gradientView = UIView()
    private let gradientLayer = CAGradientLayer()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let favoriteBadgeView = UIView()
    private let favoriteBadgeIconView = UIImageView()

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
        imageView.configure(videoURL: page.videoURL)
        titleLabel.text = page.title
        subtitleLabel.text = page.subtitle
        accessibilityLabel = page.title
    }

    private func configure() {
        contentView.layer.cornerRadius = 18
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true
        contentView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.white.withAlphaComponent(0.17).cgColor

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.18
        layer.shadowRadius = 14
        layer.shadowOffset = CGSize(width: 0, height: 8)

        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.16).cgColor,
            UIColor.black.withAlphaComponent(0.76).cgColor
        ]
        gradientLayer.locations = [0, 0.48, 1]
        gradientView.layer.addSublayer(gradientLayer)

        titleLabel.font = .systemFont(ofSize: 14, weight: .heavy)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.96)
        titleLabel.numberOfLines = 2

        subtitleLabel.font = .systemFont(ofSize: 10, weight: .semibold)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.62)
        subtitleLabel.numberOfLines = 2

        favoriteBadgeView.backgroundColor = UIColor.black.withAlphaComponent(0.34)
        favoriteBadgeView.layer.cornerRadius = 12
        favoriteBadgeView.layer.cornerCurve = .continuous
        favoriteBadgeView.layer.borderWidth = 1
        favoriteBadgeView.layer.borderColor = UIColor.white.withAlphaComponent(0.14).cgColor

        favoriteBadgeIconView.image = UIImage(systemName: "heart.fill")
        favoriteBadgeIconView.tintColor = UIColor(red: 1.00, green: 0.82, blue: 0.55, alpha: 1)
        favoriteBadgeIconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 3

        contentView.addSubview(imageView)
        contentView.addSubview(gradientView)
        contentView.addSubview(textStack)
        contentView.addSubview(favoriteBadgeView)
        favoriteBadgeView.addSubview(favoriteBadgeIconView)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        textStack.translatesAutoresizingMaskIntoConstraints = false
        favoriteBadgeView.translatesAutoresizingMaskIntoConstraints = false
        favoriteBadgeIconView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            gradientView.topAnchor.constraint(equalTo: contentView.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            favoriteBadgeView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            favoriteBadgeView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            favoriteBadgeView.widthAnchor.constraint(equalToConstant: 24),
            favoriteBadgeView.heightAnchor.constraint(equalToConstant: 24),

            favoriteBadgeIconView.centerXAnchor.constraint(equalTo: favoriteBadgeView.centerXAnchor),
            favoriteBadgeIconView.centerYAnchor.constraint(equalTo: favoriteBadgeView.centerYAnchor)
        ])
    }
}

private final class FavoriteWallpaperThumbnailView: UIImageView {

    private var videoURL: URL?
    private var thumbnailTask: Task<Void, Never>?

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .scaleAspectFill
        clipsToBounds = true
        backgroundColor = UIColor.white.withAlphaComponent(0.06)
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
            guard let self else { return }
            let thumbnail = await VideoThumbnailLoader.shared.loadThumbnail(for: videoURL)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard self.videoURL == videoURL else { return }
                self.image = thumbnail
            }
        }
    }

    deinit {
        thumbnailTask?.cancel()
    }
}
