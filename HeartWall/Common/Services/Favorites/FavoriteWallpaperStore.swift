//
//  FavoriteWallpaperStore.swift
//  HeartWall
//

import Foundation

final class FavoriteWallpaperStore {

    static let shared = FavoriteWallpaperStore()
    static let favoritesDidChangeNotification = Notification.Name("HeartWall.FavoriteWallpaperStore.FavoritesDidChange")

    private let storageKey = "HeartWall.FavoriteWallpaperStore.videoURLs"
    private let userDefaults: UserDefaults

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func isFavorite(_ page: HeartQuotePage) -> Bool {
        favoriteURLStrings().contains(identifier(for: page))
    }

    @discardableResult
    func toggleFavorite(_ page: HeartQuotePage) -> Bool {
        let identifier = identifier(for: page)
        var favorites = favoriteURLStrings()
        let isFavorite: Bool

        if favorites.contains(identifier) {
            favorites.remove(identifier)
            isFavorite = false
        } else {
            favorites.insert(identifier)
            isFavorite = true
        }

        persist(favorites)
        return isFavorite
    }

    func favoritePages(from pages: [HeartQuotePage]) -> [HeartQuotePage] {
        let favorites = favoriteURLStrings()
        return pages.filter { favorites.contains(identifier(for: $0)) }
    }

    private func favoriteURLStrings() -> Set<String> {
        Set(userDefaults.stringArray(forKey: storageKey) ?? [])
    }

    private func persist(_ favorites: Set<String>) {
        userDefaults.set(Array(favorites).sorted(), forKey: storageKey)
        NotificationCenter.default.post(name: Self.favoritesDidChangeNotification, object: nil)
    }

    private func identifier(for page: HeartQuotePage) -> String {
        page.videoURL.absoluteString
    }
}
