//
//  LibraryViewController.swift
//  HeartWall
//

import UIKit
import Combine

final class LibraryViewController: BaseViewController {

    // MARK: - Properties

    private let viewModel = LibraryViewModel()
    private var featuredPages: [HeartQuotePage] = []
    private var sections: [HeartQuoteSection] = []
    private var carouselTimer: Timer?
    private var currentCarouselIndex = 0

    private let headerHeight: CGFloat = 104
    private let contentHorizontalInset: CGFloat = 20
    private let tabBarReservedHeight: CGFloat = 128

    // MARK: - UI

    private let backgroundImageView = UIImageView()
    private let dimView = UIView()
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let topHeaderView = UIView()
    private let topBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let monthLabel = UILabel()
    private let dayLabel = UILabel()
    private let dividerView = UIView()
    private let greetingLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let appBadgeView = UIView()
    private let appBadgeTextLabel = UILabel()
    private let carouselCollectionView: UICollectionView
    private let pageControl = UIPageControl()
    private let bottomFadeView = UIView()
    private let bottomGradientLayer = CAGradientLayer()

    // MARK: - Lifecycle

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 14
        layout.minimumInteritemSpacing = 14
        carouselCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.viewDidLoad.send(())
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCarouselTimerIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCarouselTimer()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bottomGradientLayer.frame = bottomFadeView.bounds
        if let badgeGradient = appBadgeView.layer.sublayers?.first as? CAGradientLayer {
            badgeGradient.frame = appBadgeView.bounds
        }
        updateCarouselLayout()
    }

    // MARK: - Setup

    override func setupUI() {
        view.backgroundColor = UIColor(red: 0.08, green: 0.10, blue: 0.12, alpha: 1)
        configureBackground()
        configureScrollView()
        configureCarousel()
        configureHeader()
        configureBottomFade()
    }

    override func setupBindings() {
        viewModel.$featuredPages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pages in
                self?.featuredPages = pages
                self?.renderCarousel()
            }
            .store(in: &cancellables)

        viewModel.$sections
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sections in
                self?.sections = sections
                self?.renderSections(sections)
            }
            .store(in: &cancellables)
    }

    // MARK: - Configuration

    private func configureBackground() {
        backgroundImageView.image = UIImage(named: "HeartQuotePagePrimary")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.alpha = 0.30
        view.addSubview(backgroundImageView)
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false

        dimView.backgroundColor = UIColor(red: 0.05, green: 0.07, blue: 0.09, alpha: 0.64)
        view.addSubview(dimView)
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

    private func configureScrollView() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = self
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        stackView.axis = .vertical
        stackView.spacing = 22
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: headerHeight),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -tabBarReservedHeight),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    private func configureCarousel() {
        carouselCollectionView.backgroundColor = .clear
        carouselCollectionView.showsHorizontalScrollIndicator = false
        carouselCollectionView.isPagingEnabled = false
        carouselCollectionView.decelerationRate = .fast
        carouselCollectionView.contentInsetAdjustmentBehavior = .never
        carouselCollectionView.dataSource = self
        carouselCollectionView.delegate = self
        carouselCollectionView.register(HeartQuoteHeroCell.self, forCellWithReuseIdentifier: HeartQuoteHeroCell.reuseIdentifier)

        pageControl.currentPageIndicatorTintColor = .white
        pageControl.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.28)
        pageControl.isUserInteractionEnabled = false

        let container = UIView()
        container.addSubview(carouselCollectionView)
        container.addSubview(pageControl)
        carouselCollectionView.translatesAutoresizingMaskIntoConstraints = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            carouselCollectionView.topAnchor.constraint(equalTo: container.topAnchor),
            carouselCollectionView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            carouselCollectionView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            carouselCollectionView.heightAnchor.constraint(equalToConstant: 378),

            pageControl.topAnchor.constraint(equalTo: carouselCollectionView.bottomAnchor, constant: 4),
            pageControl.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        stackView.addArrangedSubview(container)
    }

    private func configureHeader() {
        topHeaderView.layer.shadowColor = UIColor.black.cgColor
        topHeaderView.layer.shadowOpacity = 0.16
        topHeaderView.layer.shadowRadius = 18
        topHeaderView.layer.shadowOffset = CGSize(width: 0, height: 12)
        view.addSubview(topHeaderView)
        topHeaderView.translatesAutoresizingMaskIntoConstraints = false

        topBlurView.layer.cornerRadius = 30
        topBlurView.layer.cornerCurve = .continuous
        topBlurView.clipsToBounds = true
        topBlurView.layer.borderWidth = 1
        topBlurView.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor
        topHeaderView.addSubview(topBlurView)
        topBlurView.translatesAutoresizingMaskIntoConstraints = false

        monthLabel.text = currentMonthText()
        monthLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        monthLabel.textColor = UIColor.white.withAlphaComponent(0.78)

        dayLabel.text = currentDayText()
        dayLabel.font = UIFont.systemFont(ofSize: 44, weight: .black)
        dayLabel.textColor = .white

        dividerView.backgroundColor = UIColor.white.withAlphaComponent(0.35)

        greetingLabel.text = currentGreetingText()
        greetingLabel.font = UIFont.systemFont(ofSize: 34, weight: .heavy)
        greetingLabel.textColor = .white

        subtitleLabel.text = "今日心语"
        subtitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.82)

        appBadgeView.layer.cornerRadius = 15
        appBadgeView.layer.cornerCurve = .continuous
        appBadgeView.layer.masksToBounds = true
        let badgeGradient = CAGradientLayer()
        badgeGradient.colors = [
            UIColor(red: 1.0, green: 0.88, blue: 0.60, alpha: 1).cgColor,
            UIColor(red: 0.98, green: 0.64, blue: 0.37, alpha: 1).cgColor
        ]
        badgeGradient.startPoint = CGPoint(x: 0, y: 0)
        badgeGradient.endPoint = CGPoint(x: 1, y: 1)
        appBadgeView.layer.insertSublayer(badgeGradient, at: 0)

        appBadgeTextLabel.text = "V"
        appBadgeTextLabel.font = UIFont.systemFont(ofSize: 26, weight: .black)
        appBadgeTextLabel.textColor = UIColor(red: 0.70, green: 0.42, blue: 0.27, alpha: 1)

        let dateStack = UIStackView(arrangedSubviews: [monthLabel, dayLabel])
        dateStack.axis = .vertical
        dateStack.alignment = .leading
        dateStack.spacing = -4

        let greetingStack = UIStackView(arrangedSubviews: [greetingLabel, subtitleLabel])
        greetingStack.axis = .vertical
        greetingStack.alignment = .leading
        greetingStack.spacing = 0

        topBlurView.contentView.addSubview(dateStack)
        topBlurView.contentView.addSubview(dividerView)
        topBlurView.contentView.addSubview(greetingStack)
        topBlurView.contentView.addSubview(appBadgeView)
        appBadgeView.addSubview(appBadgeTextLabel)

        dateStack.translatesAutoresizingMaskIntoConstraints = false
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        greetingStack.translatesAutoresizingMaskIntoConstraints = false
        appBadgeView.translatesAutoresizingMaskIntoConstraints = false
        appBadgeTextLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topHeaderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            topHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: contentHorizontalInset),
            topHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -contentHorizontalInset),
            topHeaderView.heightAnchor.constraint(equalToConstant: 92),

            topBlurView.topAnchor.constraint(equalTo: topHeaderView.topAnchor),
            topBlurView.leadingAnchor.constraint(equalTo: topHeaderView.leadingAnchor),
            topBlurView.trailingAnchor.constraint(equalTo: topHeaderView.trailingAnchor),
            topBlurView.bottomAnchor.constraint(equalTo: topHeaderView.bottomAnchor),

            dateStack.leadingAnchor.constraint(equalTo: topBlurView.contentView.leadingAnchor, constant: 18),
            dateStack.centerYAnchor.constraint(equalTo: topBlurView.contentView.centerYAnchor, constant: 2),

            dividerView.leadingAnchor.constraint(equalTo: dateStack.trailingAnchor, constant: 14),
            dividerView.centerYAnchor.constraint(equalTo: dateStack.centerYAnchor),
            dividerView.widthAnchor.constraint(equalToConstant: 1),
            dividerView.heightAnchor.constraint(equalToConstant: 56),

            greetingStack.leadingAnchor.constraint(equalTo: dividerView.trailingAnchor, constant: 16),
            greetingStack.centerYAnchor.constraint(equalTo: dateStack.centerYAnchor, constant: 1),
            greetingStack.trailingAnchor.constraint(lessThanOrEqualTo: appBadgeView.leadingAnchor, constant: -12),

            appBadgeView.trailingAnchor.constraint(equalTo: topBlurView.contentView.trailingAnchor, constant: -18),
            appBadgeView.centerYAnchor.constraint(equalTo: topBlurView.contentView.centerYAnchor),
            appBadgeView.widthAnchor.constraint(equalToConstant: 42),
            appBadgeView.heightAnchor.constraint(equalToConstant: 42),

            appBadgeTextLabel.centerXAnchor.constraint(equalTo: appBadgeView.centerXAnchor),
            appBadgeTextLabel.centerYAnchor.constraint(equalTo: appBadgeView.centerYAnchor)
        ])
    }

    private func configureBottomFade() {
        bottomGradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor(red: 0.05, green: 0.07, blue: 0.09, alpha: 0.70).cgColor
        ]
        bottomGradientLayer.locations = [0, 1]
        bottomFadeView.isUserInteractionEnabled = false
        bottomFadeView.layer.addSublayer(bottomGradientLayer)
        view.addSubview(bottomFadeView)
        bottomFadeView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            bottomFadeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomFadeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomFadeView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomFadeView.heightAnchor.constraint(equalToConstant: 150)
        ])
    }

    // MARK: - Rendering

    private func renderCarousel() {
        currentCarouselIndex = 0
        pageControl.numberOfPages = featuredPages.count
        pageControl.currentPage = 0
        carouselCollectionView.reloadData()
        carouselCollectionView.setContentOffset(.zero, animated: false)
        startCarouselTimerIfNeeded()
    }

    private func renderSections(_ sections: [HeartQuoteSection]) {
        stackView.arrangedSubviews.dropFirst().forEach { arrangedView in
            stackView.removeArrangedSubview(arrangedView)
            arrangedView.removeFromSuperview()
        }

        sections.forEach { section in
            stackView.addArrangedSubview(HeartQuoteSectionView(section: section, target: self, action: #selector(handleCardTap(_:))))
        }
    }

    private func updateCarouselLayout() {
        guard let layout = carouselCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let width = max(0, view.bounds.width - (contentHorizontalInset * 2))
        let newSize = CGSize(width: width, height: 378)
        if layout.itemSize != newSize {
            layout.itemSize = newSize
            layout.invalidateLayout()
        }
        carouselCollectionView.contentInset = UIEdgeInsets(top: 0, left: contentHorizontalInset, bottom: 0, right: contentHorizontalInset)
    }

    // MARK: - Carousel

    private func startCarouselTimerIfNeeded() {
        guard carouselTimer == nil, featuredPages.count > 1, isViewLoaded, view.window != nil else { return }
        let timer = Timer(timeInterval: 3.6, repeats: true) { [weak self] _ in
            self?.advanceCarousel()
        }
        carouselTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopCarouselTimer() {
        carouselTimer?.invalidate()
        carouselTimer = nil
    }

    private func advanceCarousel() {
        guard featuredPages.count > 1 else { return }
        let nextIndex = (currentCarouselIndex + 1) % featuredPages.count
        scrollCarousel(to: nextIndex, animated: true)
    }

    private func scrollCarousel(to index: Int, animated: Bool) {
        guard featuredPages.indices.contains(index) else { return }
        currentCarouselIndex = index
        pageControl.currentPage = index
        let indexPath = IndexPath(item: index, section: 0)
        carouselCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    }

    // MARK: - Actions

    @objc
    private func handleCardTap(_ sender: HeartQuoteCardTapGestureRecognizer) {
        showDetail(title: sender.page.title)
    }

    private func showDetail(title: String) {
        let detailViewController = HeartQuoteDetailViewController(titleText: title)
        detailViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailViewController, animated: true)
    }

    private func currentMonthText() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM"
        return formatter.string(from: Date()).uppercased()
    }

    private func currentDayText() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "d"
        return formatter.string(from: Date())
    }

    private func currentGreetingText() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "早上好"
        case 12..<18:
            return "下午好"
        default:
            return "晚上好"
        }
    }
}

// MARK: - UICollectionViewDataSource

extension LibraryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        featuredPages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HeartQuoteHeroCell.reuseIdentifier, for: indexPath) as? HeartQuoteHeroCell else {
            return UICollectionViewCell()
        }
        cell.configure(page: featuredPages[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension LibraryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showDetail(title: featuredPages[indexPath.item].title)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView === carouselCollectionView {
            stopCarouselTimer()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView === carouselCollectionView {
            updateCarouselIndexFromScrollPosition()
            startCarouselTimerIfNeeded()
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if scrollView === carouselCollectionView {
            updateCarouselIndexFromScrollPosition()
        }
    }
}

// MARK: - Scroll Handling

extension LibraryViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === self.scrollView {
            let y = max(scrollView.contentOffset.y, 0)
            backgroundImageView.alpha = max(0.16, 0.30 - (y / 1100))
        }
    }

    private func updateCarouselIndexFromScrollPosition() {
        let visibleCenterX = carouselCollectionView.contentOffset.x + (carouselCollectionView.bounds.width / 2)
        guard let indexPath = carouselCollectionView.indexPathForItem(at: CGPoint(x: visibleCenterX, y: carouselCollectionView.bounds.midY)) else { return }
        currentCarouselIndex = indexPath.item
        pageControl.currentPage = indexPath.item
    }
}

// MARK: - Views

private final class HeartQuoteHeroCell: UICollectionViewCell {

    static let reuseIdentifier = "HeartQuoteHeroCell"

    private let imageView = CroppedAssetImageView()
    private let gradientView = UIView()
    private let gradientLayer = CAGradientLayer()
    private let badgeLabel = InsetLabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let tagStackView = UIStackView()

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

    override func prepareForReuse() {
        super.prepareForReuse()
        tagStackView.arrangedSubviews.forEach { view in
            tagStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    func configure(page: HeartQuotePage) {
        imageView.configure(assetName: page.assetName, cropRect: page.cropRect)
        titleLabel.text = page.title
        subtitleLabel.text = page.subtitle
        badgeLabel.text = page.badgeText
        badgeLabel.isHidden = page.badgeText == nil

        page.tags.forEach { tag in
            let label = InsetLabel(top: 6, left: 10, bottom: 6, right: 10)
            label.text = tag
            label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            label.textColor = UIColor.white.withAlphaComponent(0.86)
            label.backgroundColor = UIColor.white.withAlphaComponent(0.12)
            label.layer.cornerRadius = 10
            label.layer.cornerCurve = .continuous
            label.clipsToBounds = true
            tagStackView.addArrangedSubview(label)
        }
    }

    private func configure() {
        contentView.layer.cornerRadius = 34
        contentView.layer.cornerCurve = .continuous
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = UIColor.white.withAlphaComponent(0.08)

        imageView.contentMode = .scaleAspectFill
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0.05).cgColor,
            UIColor.black.withAlphaComponent(0.28).cgColor,
            UIColor.black.withAlphaComponent(0.76).cgColor
        ]
        gradientLayer.locations = [0, 0.42, 1]
        gradientView.layer.addSublayer(gradientLayer)
        contentView.addSubview(gradientView)
        gradientView.translatesAutoresizingMaskIntoConstraints = false

        badgeLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        badgeLabel.textColor = .white
        badgeLabel.backgroundColor = UIColor.black.withAlphaComponent(0.34)
        badgeLabel.layer.cornerRadius = 14
        badgeLabel.layer.cornerCurve = .continuous
        badgeLabel.clipsToBounds = true

        titleLabel.font = UIFont.systemFont(ofSize: 30, weight: .heavy)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2

        subtitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.82)
        subtitleLabel.numberOfLines = 2

        tagStackView.axis = .horizontal
        tagStackView.spacing = 8
        tagStackView.alignment = .leading
        tagStackView.distribution = .fillProportionally

        let textStack = UIStackView(arrangedSubviews: [badgeLabel, titleLabel, subtitleLabel, tagStackView])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 10
        contentView.addSubview(textStack)
        textStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            gradientView.topAnchor.constraint(equalTo: contentView.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 22),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -22),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }
}

private final class HeartQuoteSectionView: UIView {

    private let section: HeartQuoteSection
    private weak var target: AnyObject?
    private let action: Selector

    init(section: HeartQuoteSection, target: AnyObject, action: Selector) {
        self.section = section
        self.target = target
        self.action = action
        super.init(frame: .zero)
        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        let titleLabel = UILabel()
        titleLabel.text = section.title
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .heavy)
        titleLabel.textColor = .white

        let countLabel = UILabel()
        countLabel.text = section.countText + "  >"
        countLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        countLabel.textColor = UIColor.white.withAlphaComponent(0.78)

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, UIView(), countLabel])
        headerStack.axis = .horizontal
        headerStack.alignment = .center

        let cardStack = UIStackView()
        cardStack.axis = .horizontal
        cardStack.spacing = 12
        cardStack.distribution = .fillEqually

        section.items.forEach { page in
            let cardView = HeartQuoteSmallCardView(page: page)
            cardView.addGestureRecognizer(HeartQuoteCardTapGestureRecognizer(page: page, target: target, action: action))
            cardStack.addArrangedSubview(cardView)
        }

        let contentStack = UIStackView(arrangedSubviews: [headerStack, cardStack])
        contentStack.axis = .vertical
        contentStack.spacing = 14
        addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),

            cardStack.heightAnchor.constraint(equalToConstant: 188)
        ])
    }
}

private final class HeartQuoteSmallCardView: UIView {

    private let imageView = CroppedAssetImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let gradientView = UIView()
    private let gradientLayer = CAGradientLayer()

    init(page: HeartQuotePage) {
        super.init(frame: .zero)
        configure()
        apply(page: page)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = gradientView.bounds
    }

    private func apply(page: HeartQuotePage) {
        imageView.configure(assetName: page.assetName, cropRect: page.cropRect)
        titleLabel.text = page.title
        subtitleLabel.text = page.subtitle
        accessibilityLabel = page.title
    }

    private func configure() {
        layer.cornerRadius = 22
        layer.cornerCurve = .continuous
        clipsToBounds = true
        backgroundColor = UIColor.white.withAlphaComponent(0.08)
        isUserInteractionEnabled = true

        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.72).cgColor
        ]
        gradientLayer.locations = [0, 1]
        gradientView.layer.addSublayer(gradientLayer)
        addSubview(gradientView)
        gradientView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .heavy)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 1

        subtitleLabel.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.76)
        subtitleLabel.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 3
        addSubview(textStack)
        textStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            gradientView.topAnchor.constraint(equalTo: topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: bottomAnchor),

            textStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }
}

private final class CroppedAssetImageView: UIImageView {

    private var assetName: String?
    private var cropRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)

    func configure(assetName: String, cropRect: CGRect) {
        self.assetName = assetName
        self.cropRect = cropRect
        image = UIImage(named: assetName)?.cropped(toNormalizedRect: cropRect)
        contentMode = .scaleAspectFill
        clipsToBounds = true
    }
}

private final class HeartQuoteCardTapGestureRecognizer: UITapGestureRecognizer {
    let page: HeartQuotePage

    init(page: HeartQuotePage, target: AnyObject?, action: Selector?) {
        self.page = page
        super.init(target: target, action: action)
    }
}

private final class InsetLabel: UILabel {

    private let insets: UIEdgeInsets

    init(top: CGFloat = 5, left: CGFloat = 10, bottom: CGFloat = 5, right: CGFloat = 10) {
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
