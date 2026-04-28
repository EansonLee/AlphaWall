//
//  AudioTherapyCatalogProvider.swift
//  HeartWall
//

import UIKit

struct AudioTherapyCatalog {
    let categories: [AudioTherapyCategory]
    let items: [AudioTherapyItem]

    var defaultItem: AudioTherapyItem? {
        items.first
    }
}

struct AudioTherapyCatalogProvider {

    func makeCatalog() -> AudioTherapyCatalog {
        guard let directory = decodeResource(AudioTherapyDirectory.self, named: "voice_categories") else {
            return AudioTherapyCatalog(categories: [], items: [])
        }

        let categories = directory.categories.map {
            AudioTherapyCategory(
                id: $0.category,
                title: L10n.content($0.title),
                file: $0.file,
                count: $0.count
            )
        }

        let items = directory.categories.enumerated().flatMap { categoryIndex, category in
            let resourceName = (category.file as NSString).deletingPathExtension
            let rawItems = decodeResource([AudioTherapyRawItem].self, named: resourceName) ?? []

            return rawItems.enumerated().compactMap { itemIndex, rawItem -> AudioTherapyItem? in
                guard let videoURL = URL(string: rawItem.url) else { return nil }
                let categoryID = rawItem.category.isEmpty ? category.category : rawItem.category
                let categoryTitle = rawItem.categoryTitle.isEmpty ? category.title : L10n.content(rawItem.categoryTitle)

                return AudioTherapyItem(
                    id: rawItem.fileName,
                    title: L10n.content(rawItem.title),
                    listenerCount: listenerCount(categoryIndex: categoryIndex, itemIndex: itemIndex),
                    categoryID: categoryID,
                    categoryTitle: categoryTitle,
                    videoURL: videoURL,
                    accentColor: accentColor(for: categoryID)
                )
            }
        }

        return AudioTherapyCatalog(categories: categories, items: items)
    }

    private func decodeResource<T: Decodable>(_ type: T.Type, named resourceName: String) -> T? {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else { return nil }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            assertionFailure("Failed to load audio therapy resource \(resourceName): \(error)")
            return nil
        }
    }

    private func listenerCount(categoryIndex: Int, itemIndex: Int) -> Int {
        860 + categoryIndex * 137 + itemIndex * 83
    }

    private func accentColor(for categoryID: String) -> UIColor {
        switch categoryID {
        case "rain":
            UIColor(red: 0.31, green: 0.42, blue: 0.51, alpha: 1)
        case "water":
            UIColor(red: 0.24, green: 0.49, blue: 0.57, alpha: 1)
        case "forest":
            UIColor(red: 0.35, green: 0.47, blue: 0.33, alpha: 1)
        case "fire_night":
            UIColor(red: 0.55, green: 0.37, blue: 0.25, alpha: 1)
        case "indoor_travel":
            UIColor(red: 0.46, green: 0.42, blue: 0.54, alpha: 1)
        default:
            UIColor(red: 0.38, green: 0.47, blue: 0.55, alpha: 1)
        }
    }
}

private struct AudioTherapyDirectory: Decodable {
    let categories: [AudioTherapyRawCategory]
}

private struct AudioTherapyRawCategory: Decodable {
    let category: String
    let title: String
    let file: String
    let count: Int
}

private struct AudioTherapyRawItem: Decodable {
    let title: String
    let url: String
    let fileName: String
    let category: String
    let categoryTitle: String
}
