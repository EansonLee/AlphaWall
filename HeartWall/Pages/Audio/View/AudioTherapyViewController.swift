//
//  AudioTherapyViewController.swift
//  HeartWall
//

import UIKit

final class AudioTherapyViewController: BaseViewController {

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override func setupUI() {
        view.backgroundColor = UIColor(red: 0.07, green: 0.11, blue: 0.14, alpha: 1)

        titleLabel.text = "音疗专区"
        titleLabel.font = .systemFont(ofSize: 34, weight: .heavy)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center

        subtitleLabel.text = "音疗内容占位"
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.68)
        subtitleLabel.textAlignment = .center

        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 10

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
    }
}
