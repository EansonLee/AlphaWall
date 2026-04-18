//
//  BaseViewController.swift
//  HeartWall
//

import UIKit
import Combine

class BaseViewController: UIViewController {

    // MARK: - Properties

    var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupBindings()
    }

    // MARK: - Override Points

    func setupUI() {}
    func setupBindings() {}

    // MARK: - Loading

    func showLoading() {
        // TODO: 接入 LoadingView
    }

    func hideLoading() {
        // TODO: 接入 LoadingView
    }

    func showError(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
