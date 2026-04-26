//
//  VideoThumbnailLoader.swift
//  HeartWall
//

import AVFoundation
import UIKit

final class VideoThumbnailLoader {

    static let shared = VideoThumbnailLoader()

    private let cache = NSCache<NSURL, UIImage>()

    private init() {
        cache.countLimit = 160
    }

    func loadThumbnail(for url: URL) async -> UIImage? {
        if let cachedImage = cache.object(forKey: url as NSURL) {
            return cachedImage
        }

        let resolvedURL = url.isFileURL ? url : await VideoCacheService.shared.resolvedURL(for: url)
        let asset = AVURLAsset(url: resolvedURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 720, height: 1280)
        generator.requestedTimeToleranceAfter = .zero
        generator.requestedTimeToleranceBefore = .zero

        let requestedTime = CMTime(seconds: 0, preferredTimescale: 600)

        do {
            let cgImage = try await generator.image(at: requestedTime).image
            let image = UIImage(cgImage: cgImage)
            cache.setObject(image, forKey: url as NSURL)
            return image
        } catch {
            return nil
        }
    }
}
