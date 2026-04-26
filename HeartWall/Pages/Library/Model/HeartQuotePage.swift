//
//  HeartQuotePage.swift
//  HeartWall
//

import Foundation

enum HeartQuoteTheme: String, CaseIterable {
    case banner
    case city
    case creative
    case nature
    case anime

    var displayTitle: String {
        switch self {
        case .banner:
            return "今日臻选"
        case .city:
            return "城市流光"
        case .creative:
            return "灵感幻境"
        case .nature:
            return "自然诗境"
        case .anime:
            return "绮梦次元"
        }
    }

    var resourceName: String {
        rawValue
    }
}

struct ThemeVideoResource: Decodable {
    let title: String
    let urlString: String

    private enum CodingKeys: String, CodingKey {
        case title
        case url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        urlString = try container.decode(String.self, forKey: .url)
    }
}

struct HeartQuotePage: Identifiable {
    let id = UUID()
    let theme: HeartQuoteTheme
    let rawTitle: String
    let title: String
    let videoURL: URL
    let subtitle: String
    let badgeText: String?
    let tags: [String]
}

struct HeartQuoteSection: Identifiable {
    let id = UUID()
    let title: String
    let countText: String
    let items: [HeartQuotePage]
}
