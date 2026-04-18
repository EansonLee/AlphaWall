//
//  LibraryViewController.swift
//  HeartWall
//

import UIKit
import Combine

final class LibraryViewController: BaseViewController {

    // MARK: - Properties

    private let viewModel = LibraryViewModel()
    private let topAreaHeight: CGFloat = 181
    private let bottomAreaHeight: CGFloat = 122
    private let designScreenHeight: CGFloat = 1662
    private let referenceAspectRatio: CGFloat = 1170.0 / 1662.0

    // MARK: - UI

    private let backgroundImageView = UIImageView()
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let bottomFadeView = UIView()
    private let topHeaderView = UIView()
    private let monthLabel = UILabel()
    private let dayLabel = UILabel()
    private let dividerView = UIView()
    private let greetingLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let appBadgeView = UIView()
    private let appBadgeTextLabel = UILabel()
    private let topShadeView = UIView()
    private let topGradientLayer = CAGradientLayer()
    private let bottomGradientLayer = CAGradientLayer()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.viewDidLoad.send(())
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        topGradientLayer.frame = topShadeView.bounds
        bottomGradientLayer.frame = bottomFadeView.bounds
        if let badgeGradient = appBadgeView.layer.sublayers?.first as? CAGradientLayer {
            badgeGradient.frame = appBadgeView.bounds
        }
    }

    // MARK: - Setup

    override func setupUI() {
        view.backgroundColor = .black
        configureBackground()
        configureScrollView()
        configureOverlay()
    }

    override func setupBindings() {
        viewModel.$pages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pages in
                self?.renderPages(pages)
            }
            .store(in: &cancellables)
    }

    private func configureBackground() {
        backgroundImageView.image = UIImage(named: "HeartQuotePagePrimary")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.alpha = 0.38
        view.addSubview(backgroundImageView)
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
        stackView.spacing = 0
        view.addSubview(bottomFadeView)
        bottomFadeView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            bottomFadeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomFadeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomFadeView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomFadeView.heightAnchor.constraint(equalToConstant: 188)
        ])
    }

    private func configureOverlay() {
        topGradientLayer.colors = [
            UIColor.black.withAlphaComponent(0.56).cgColor,
            UIColor.black.withAlphaComponent(0.20).cgColor,
            UIColor.clear.cgColor
        ]
        topGradientLayer.locations = [0, 0.58, 1]
        topShadeView.isUserInteractionEnabled = false
        topShadeView.layer.addSublayer(topGradientLayer)
        view.addSubview(topShadeView)
        topShadeView.translatesAutoresizingMaskIntoConstraints = false

        bottomGradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.10).cgColor,
            UIColor.black.withAlphaComponent(0.34).cgColor
        ]
        bottomGradientLayer.locations = [0, 0.38, 1]
        bottomFadeView.layer.addSublayer(bottomGradientLayer)

        configureHeader()

        NSLayoutConstraint.activate([
            topShadeView.topAnchor.constraint(equalTo: view.topAnchor),
            topShadeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topShadeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topShadeView.heightAnchor.constraint(equalToConstant: 240)
        ])
    }

    private func configureHeader() {
        view.addSubview(topHeaderView)
        topHeaderView.translatesAutoresizingMaskIntoConstraints = false

        monthLabel.text = "APR"
        monthLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        monthLabel.textColor = .white

        dayLabel.text = "18"
        dayLabel.font = UIFont.systemFont(ofSize: 58, weight: .bold)
        dayLabel.textColor = .white

        dividerView.backgroundColor = UIColor.white.withAlphaComponent(0.55)

        greetingLabel.text = "下午好"
        greetingLabel.font = UIFont.systemFont(ofSize: 44, weight: .bold)
        greetingLabel.textColor = .white

        subtitleLabel.text = "今日心语"
        subtitleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        subtitleLabel.textColor = .white

        appBadgeView.layer.cornerRadius = 15
        appBadgeView.layer.cornerCurve = .continuous
        appBadgeView.layer.masksToBounds = true
        let badgeGradient = CAGradientLayer()
        badgeGradient.colors = [
            UIColor(red: 1.0, green: 0.91, blue: 0.68, alpha: 1).cgColor,
            UIColor(red: 0.97, green: 0.73, blue: 0.46, alpha: 1).cgColor
        ]
        badgeGradient.startPoint = CGPoint(x: 0, y: 0)
        badgeGradient.endPoint = CGPoint(x: 1, y: 1)
        appBadgeView.layer.insertSublayer(badgeGradient, at: 0)

        appBadgeTextLabel.text = "V"
        appBadgeTextLabel.font = UIFont.systemFont(ofSize: 30, weight: .black)
        appBadgeTextLabel.textColor = UIColor(red: 0.78, green: 0.48, blue: 0.31, alpha: 1)

        let dateStack = UIStackView(arrangedSubviews: [monthLabel, dayLabel])
        dateStack.axis = .vertical
        dateStack.alignment = .leading
        dateStack.spacing = -2

        let greetingStack = UIStackView(arrangedSubviews: [greetingLabel, subtitleLabel])
        greetingStack.axis = .vertical
        greetingStack.alignment = .leading
        greetingStack.spacing = -2

        topHeaderView.addSubview(dateStack)
        topHeaderView.addSubview(dividerView)
        topHeaderView.addSubview(greetingStack)
        topHeaderView.addSubview(appBadgeView)
        appBadgeView.addSubview(appBadgeTextLabel)

        dateStack.translatesAutoresizingMaskIntoConstraints = false
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        greetingStack.translatesAutoresizingMaskIntoConstraints = false
        appBadgeView.translatesAutoresizingMaskIntoConstraints = false
        appBadgeTextLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topHeaderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 34),
            topHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            topHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            topHeaderView.heightAnchor.constraint(equalToConstant: 122),

            dateStack.leadingAnchor.constraint(equalTo: topHeaderView.leadingAnchor),
            dateStack.bottomAnchor.constraint(equalTo: topHeaderView.bottomAnchor),

            dividerView.leadingAnchor.constraint(equalTo: dateStack.trailingAnchor, constant: 18),
            dividerView.centerYAnchor.constraint(equalTo: dateStack.centerYAnchor),
            dividerView.widthAnchor.constraint(equalToConstant: 1.5),
            dividerView.heightAnchor.constraint(equalToConstant: 88),

            greetingStack.leadingAnchor.constraint(equalTo: dividerView.trailingAnchor, constant: 22),
            greetingStack.bottomAnchor.constraint(equalTo: dateStack.bottomAnchor, constant: -2),

            appBadgeView.trailingAnchor.constraint(equalTo: topHeaderView.trailingAnchor),
            appBadgeView.centerYAnchor.constraint(equalTo: dividerView.centerYAnchor, constant: 6),
            appBadgeView.widthAnchor.constraint(equalToConstant: 44),
            appBadgeView.heightAnchor.constraint(equalToConstant: 44),

            appBadgeTextLabel.centerXAnchor.constraint(equalTo: appBadgeView.centerXAnchor),
            appBadgeTextLabel.centerYAnchor.constraint(equalTo: appBadgeView.centerYAnchor)
        ])

        DispatchQueue.main.async {
            badgeGradient.frame = self.appBadgeView.bounds
        }
    }

    private func renderPages(_ pages: [HeartQuotePage]) {
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let availableHeight = UIScreen.main.bounds.height - topAreaHeight - bottomAreaHeight
        let imageHeight = max(availableHeight, 400)

        pages.forEach { page in
            let container = UIView()
            container.backgroundColor = .clear

            let imageView = UIImageView(image: UIImage(named: page.assetName))
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.isUserInteractionEnabled = true
            container.addSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false

            let tap = UITapGestureRecognizer(target: self, action: #selector(handlePageTap(_:)))
            imageView.addGestureRecognizer(tap)
            imageView.accessibilityLabel = page.title

            let renderedHeight = UIScreen.main.bounds.width / referenceAspectRatio

            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: container.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                imageView.heightAnchor.constraint(equalToConstant: renderedHeight),
                container.heightAnchor.constraint(equalToConstant: imageHeight)
            ])

            stackView.addArrangedSubview(container)
        }
    }

    @objc
    private func handlePageTap(_ gesture: UITapGestureRecognizer) {
        guard let title = (gesture.view as? UIImageView)?.accessibilityLabel else { return }
        let detailViewController = HeartQuoteDetailViewController(titleText: title)
        detailViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}

extension LibraryViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y = max(scrollView.contentOffset.y, 0)
        let alpha = max(0.22, 0.38 - (y / 1200))
        backgroundImageView.alpha = alpha
    }
}
