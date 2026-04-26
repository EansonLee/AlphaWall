//
//  AudioTherapyCatalogProvider.swift
//  HeartWall
//

import UIKit

struct AudioTherapyCatalogProvider {

    func makeItems() -> [AudioTherapyItem] {
        let loader = ThemeCatalogLoader()
        let catalog = (try? loader.loadAllThemes()) ?? [:]
        let pages = [
            catalog[.nature] ?? [],
            catalog[.banner] ?? [],
            catalog[.creative] ?? [],
            catalog[.city] ?? [],
            catalog[.anime] ?? []
        ].flatMap { $0 }

        let fallbackURL = OnboardingVideoProvider.shared.selectedURL
        let seeds: [(title: String, count: Int, category: AudioTherapyCategory, color: UIColor)] = [
            ("篝火旁", 1050, .recommended, UIColor(red: 0.39, green: 0.52, blue: 0.72, alpha: 1)),
            ("林中篝火", 1171, .recommended, UIColor(red: 0.34, green: 0.37, blue: 0.39, alpha: 1)),
            ("浪花朵朵", 872, .sleep, UIColor(red: 0.50, green: 0.64, blue: 0.38, alpha: 1)),
            ("深蓝秘境", 1279, .focus, UIColor(red: 0.43, green: 0.60, blue: 0.39, alpha: 1)),
            ("白噪音,水声,轻松", 1539, .relief, UIColor(red: 0.39, green: 0.51, blue: 0.54, alpha: 1)),
            ("挪威瀑布", 1436, .meditation, UIColor(red: 0.60, green: 0.57, blue: 0.47, alpha: 1)),
            ("檐下听雨", 1196, .rain, UIColor(red: 0.42, green: 0.49, blue: 0.58, alpha: 1)),
            ("山谷清晨", 986, .scene, UIColor(red: 0.54, green: 0.62, blue: 0.35, alpha: 1))
        ]

        return seeds.enumerated().compactMap { index, seed in
            let pageURL = pages[safe: index]?.videoURL ?? fallbackURL
            guard let videoURL = pageURL else { return nil }
            return AudioTherapyItem(
                title: seed.title,
                listenerCount: seed.count,
                category: seed.category,
                videoURL: videoURL,
                accentColor: seed.color
            )
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
