//
//  ThemeCatalogLoader.swift
//  HeartWall
//

import Foundation

struct ThemeCatalogLoader {

    enum LoaderError: LocalizedError {
        case resourceNotFound(String)
        case invalidData(String)

        var errorDescription: String? {
            switch self {
            case .resourceNotFound(let name):
                return L10n.text("error.resource_not_found", name)
            case .invalidData(let name):
                return L10n.text("error.resource_invalid", name)
            }
        }
    }

    func loadAllThemes() throws -> [HeartQuoteTheme: [HeartQuotePage]] {
        var catalog: [HeartQuoteTheme: [HeartQuotePage]] = [:]

        for theme in HeartQuoteTheme.allCases {
            catalog[theme] = try loadThemePages(theme)
        }

        return catalog
    }

    private func loadThemePages(_ theme: HeartQuoteTheme) throws -> [HeartQuotePage] {
        guard let url = Bundle.main.url(forResource: theme.resourceName, withExtension: "json") else {
            throw LoaderError.resourceNotFound(theme.resourceName)
        }

        guard let data = try? Data(contentsOf: url) else {
            throw LoaderError.invalidData(theme.resourceName)
        }

        let decoder = JSONDecoder()
        guard let resources = try? decoder.decode([ThemeVideoResource].self, from: data) else {
            throw LoaderError.invalidData(theme.resourceName)
        }

        return resources.enumerated().compactMap { index, resource in
            guard let videoURL = Self.makeURL(from: resource.urlString) else {
                return nil
            }

            return HeartQuotePage(
                theme: theme,
                rawTitle: resource.title,
                title: Self.makeDisplayTitle(from: resource.title, index: index),
                videoURL: videoURL,
                subtitle: Self.makeSubtitle(from: resource.title),
                badgeText: index == 0 ? L10n.text("library.featured.badge") : nil,
                tags: Self.makeTags(from: resource.title)
            )
        }
    }

    private static func makeDisplayTitle(from rawTitle: String, index: Int) -> String {
        let segments = normalizedSegments(from: rawTitle)
        let filtered = segments.filter { !$0.isEmpty && !isGenericSceneryTag($0) }
        let selected = Array(filtered.prefix(2))

        if !selected.isEmpty {
            return selected.joined(separator: " · ")
        }

        return L10n.text("library.fallback.theme", index + 1)
    }

    private static func makeSubtitle(from rawTitle: String) -> String {
        let segments = normalizedSegments(from: rawTitle)
        let filtered = segments.filter { !$0.isEmpty }
        if filtered.isEmpty {
            return L10n.text("library.fallback.subtitle")
        }
        return filtered.prefix(4).joined(separator: " · ")
    }

    private static func makeTags(from rawTitle: String) -> [String] {
        let segments = normalizedSegments(from: rawTitle)
        let filtered = segments.filter { !$0.isEmpty && !isGenericSceneryTag($0) }
        return Array(filtered.prefix(4))
    }

    private static func normalizedSegments(from rawTitle: String) -> [String] {
        rawTitle
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: ",", with: "_")
            .split(separator: "_")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map(L10n.content)
    }

    private static func isGenericSceneryTag(_ value: String) -> Bool {
        let rawSceneryTag = "\u{98CE}\u{666F}"
        return value == L10n.content(rawSceneryTag) || value.lowercased() == "scenery"
    }

    private static func makeURL(from rawValue: String) -> URL? {
        if let url = URL(string: rawValue), url.scheme != nil {
            return url
        }

        let allowed = CharacterSet.urlQueryAllowed.union(.urlPathAllowed)
        guard let encoded = rawValue.addingPercentEncoding(withAllowedCharacters: allowed) else {
            return nil
        }

        return URL(string: encoded)
    }
}
