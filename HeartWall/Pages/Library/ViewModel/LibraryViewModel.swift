//
//  LibraryViewModel.swift
//  HeartWall
//

import Combine
import Foundation

final class LibraryViewModel: BaseViewModel {

    // MARK: - Inputs

    let viewDidLoad = PassthroughSubject<Void, Never>()

    // MARK: - Outputs

    @Published private(set) var featuredPages: [HeartQuotePage] = []
    @Published private(set) var sections: [HeartQuoteSection] = []
    @Published private(set) var allPages: [HeartQuotePage] = []

    private let loader = ThemeCatalogLoader()

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
        do {
            let catalog = try loader.loadAllThemes()

            featuredPages = catalog[.banner] ?? []
            allPages = HeartQuoteTheme.allCases.flatMap { catalog[$0] ?? [] }

            sections = [
                makeSection(theme: .city, pages: catalog[.city] ?? []),
                makeSection(theme: .creative, pages: catalog[.creative] ?? []),
                makeSection(theme: .nature, pages: catalog[.nature] ?? []),
                makeSection(theme: .anime, pages: catalog[.anime] ?? [])
            ]
        } catch {
            featuredPages = []
            sections = []
            allPages = []
            setError(error.localizedDescription)
        }
    }

    private func makeSection(theme: HeartQuoteTheme, pages: [HeartQuotePage]) -> HeartQuoteSection {
        HeartQuoteSection(
            title: theme.displayTitle,
            countText: L10n.text("library.section.count", pages.count),
            items: Array(pages.prefix(3))
        )
    }
}
