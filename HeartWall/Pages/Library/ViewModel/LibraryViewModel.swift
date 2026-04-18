//
//  LibraryViewModel.swift
//  HeartWall
//

import Foundation
import Combine

final class LibraryViewModel: BaseViewModel {

    // MARK: - Inputs

    let viewDidLoad = PassthroughSubject<Void, Never>()

    // MARK: - Outputs

    @Published private(set) var pages: [HeartQuotePage] = []

    // MARK: - Lifecycle

    override init() {
        super.init()
        bindInputs()
    }

    // MARK: - Binding

    private func bindInputs() {
        viewDidLoad
            .sink { [weak self] in
                self?.loadPages()
            }
            .store(in: &cancellables)
    }

    private func loadPages() {
        pages = [
            HeartQuotePage(title: "罗盘指引着方向", assetName: "HeartQuotePagePrimary"),
            HeartQuotePage(title: "见者好运", assetName: "HeartQuotePageSecondary"),
            HeartQuotePage(title: "每日心语", assetName: "HeartQuotePageTertiary")
        ]
    }
}
