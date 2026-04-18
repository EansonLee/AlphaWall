//
//  HeartQuoteDetailViewController.swift
//  HeartWall
//

import UIKit

final class HeartQuoteDetailViewController: BaseViewController {

    // MARK: - Properties

    private let titleText: String

    // MARK: - UI

    private let titleLabel = UILabel()
    private let messageLabel = UILabel()

    init(titleText: String) {
        self.titleText = titleText
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupUI() {
        view.backgroundColor = UIColor(red: 0.07, green: 0.08, blue: 0.11, alpha: 1)
        navigationItem.largeTitleDisplayMode = .never
        title = titleText

        titleLabel.text = titleText
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0

        messageLabel.text = "二级页占位，用于验证进入详情后底部悬浮栏隐藏。"
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        messageLabel.textColor = UIColor.white.withAlphaComponent(0.72)
        messageLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, messageLabel])
        stack.axis = .vertical
        stack.spacing = 16

        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
