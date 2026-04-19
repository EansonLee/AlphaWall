//
//  HeartQuotePage.swift
//  HeartWall
//

import CoreGraphics
import Foundation

struct HeartQuotePage: Identifiable {
    let id = UUID()
    let title: String
    let assetName: String
    let cropRect: CGRect
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
