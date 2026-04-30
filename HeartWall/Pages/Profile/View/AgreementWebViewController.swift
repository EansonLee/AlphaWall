//
//  AgreementWebViewController.swift
//  HeartWall
//

import UIKit
import WebKit

final class AgreementWebViewController: BaseViewController {

    private let pageTitle: String
    private let pageURL: URL

    private let headerView = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .bar)
    private let webView: WKWebView

    private var progressObservation: NSKeyValueObservation?

    init(title: String, url: URL) {
        pageTitle = title
        pageURL = url

        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        webView = WKWebView(frame: .zero, configuration: configuration)

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.load(URLRequest(url: pageURL))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = .systemBackground
        configureHeader()
        configureWebView()
        observeLoadingProgress()
    }

    private func configureHeader() {
        headerView.backgroundColor = .systemBackground

        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .label
        backButton.backgroundColor = UIColor.secondarySystemBackground
        backButton.layer.cornerRadius = 16
        backButton.layer.cornerCurve = .continuous
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)

        titleLabel.text = pageTitle
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.82

        progressView.progressTintColor = UIColor(red: 0.42, green: 0.82, blue: 0.76, alpha: 1)
        progressView.trackTintColor = .clear
        progressView.alpha = 0

        view.addSubview(headerView)
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        view.addSubview(progressView)

        headerView.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 52),

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 18),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 12),
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: headerView.trailingAnchor, constant: -62),

            progressView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2)
        ])
    }

    private func configureWebView() {
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.backgroundColor = .systemBackground
        webView.scrollView.backgroundColor = .systemBackground

        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func observeLoadingProgress() {
        progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            self?.updateProgress(webView.estimatedProgress)
        }
    }

    private func updateProgress(_ progress: Double) {
        progressView.alpha = progress >= 1 ? 0 : 1
        progressView.setProgress(Float(progress), animated: true)

        if progress >= 1 {
            progressView.setProgress(0, animated: false)
        }
    }

    @objc
    private func handleBack() {
        navigationController?.popViewController(animated: true)
    }
}

extension AgreementWebViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        showError(error.localizedDescription)
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        showError(error.localizedDescription)
    }
}

extension AgreementWebViewController: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard navigationAction.targetFrame == nil, let url = navigationAction.request.url else {
            return nil
        }

        webView.load(URLRequest(url: url))
        return nil
    }
}
