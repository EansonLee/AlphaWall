//
//  VideoCacheService.swift
//  HeartWall
//

import CryptoKit
import Foundation

final class VideoCacheService {

    static let shared = VideoCacheService()

    private let fileManager = FileManager.default
    private let cacheDirectoryURL: URL
    private let ioQueue = DispatchQueue(label: "HeartWall.VideoCacheService.IO")
    private let stateQueue = DispatchQueue(label: "HeartWall.VideoCacheService.State")
    private let maxCacheSizeInBytes: Int64 = 600 * 1024 * 1024

    private var inflightTasks: [URL: Task<URL, Error>] = [:]
    private var visitedDetailURLs: [URL] = []

    private init() {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        cacheDirectoryURL = cachesDirectory.appendingPathComponent("HeartWallVideoCache", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDirectoryURL, withIntermediateDirectories: true)
    }

    func playbackURL(for remoteURL: URL) -> URL {
        guard !remoteURL.isFileURL else { return remoteURL }

        if let cachedURL = cachedFileURLIfExists(for: remoteURL) {
            touchFileIfNeeded(at: cachedURL)
            return cachedURL
        }

        return remoteURL
    }

    func recordVisitedDetailURL(_ url: URL) {
        guard !url.isFileURL else { return }

        stateQueue.sync {
            guard !visitedDetailURLs.contains(url) else { return }
            visitedDetailURLs.append(url)
        }
    }

    func cacheVisitedDetailVideosIfNeeded() async {
        let urls = stateQueue.sync { visitedDetailURLs }

        for url in urls {
            guard !Task.isCancelled else { return }
            _ = try? await cacheRemoteVideoIfNeeded(for: url)
        }
    }

    func localVideoURL(for remoteURL: URL) async throws -> URL {
        guard !remoteURL.isFileURL else { return remoteURL }
        return try await cacheRemoteVideoIfNeeded(for: remoteURL)
    }

    private func cacheRemoteVideoIfNeeded(for remoteURL: URL) async throws -> URL {
        if let cachedURL = cachedFileURLIfExists(for: remoteURL) {
            touchFileIfNeeded(at: cachedURL)
            return cachedURL
        }

        if let inflightTask = inflightTask(for: remoteURL) {
            return try await inflightTask.value
        }

        let task = makeDownloadTask(for: remoteURL)
        storeInflightTask(task, for: remoteURL)
        return try await task.value
    }

    private func cachedFileURLIfExists(for remoteURL: URL) -> URL? {
        let fileURL = cacheDirectoryURL.appendingPathComponent(cacheFileName(for: remoteURL))
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        return fileURL
    }

    private func makeDownloadTask(for remoteURL: URL) -> Task<URL, Error> {
        Task<URL, Error> { [weak self] in
            guard let self else { throw CancellationError() }
            defer { self.removeInflightTask(for: remoteURL) }
            return try await self.downloadAndStore(remoteURL: remoteURL)
        }
    }

    private func downloadAndStore(remoteURL: URL) async throws -> URL {
        let (temporaryURL, response) = try await URLSession.shared.download(from: remoteURL)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let targetURL = cacheDirectoryURL.appendingPathComponent(cacheFileName(for: remoteURL))

        try await withCheckedThrowingContinuation { continuation in
            ioQueue.async {
                do {
                    try? self.fileManager.removeItem(at: targetURL)
                    try self.fileManager.moveItem(at: temporaryURL, to: targetURL)
                    self.touchFileIfNeeded(at: targetURL)
                    self.trimCacheIfNeeded()
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }

        return targetURL
    }

    private func cacheFileName(for remoteURL: URL) -> String {
        let digest = SHA256.hash(data: Data(remoteURL.absoluteString.utf8))
        let fileName = digest.compactMap { String(format: "%02x", $0) }.joined()
        let pathExtension = remoteURL.pathExtension.isEmpty ? "mp4" : remoteURL.pathExtension
        return "\(fileName).\(pathExtension)"
    }

    private func touchFileIfNeeded(at url: URL) {
        try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: url.path)
    }

    private func trimCacheIfNeeded() {
        guard let fileURLs = try? fileManager.contentsOfDirectory(
            at: cacheDirectoryURL,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        let items: [(url: URL, modifiedAt: Date, size: Int64)] = fileURLs.compactMap { url in
            guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]) else {
                return nil
            }
            return (url, values.contentModificationDate ?? .distantPast, Int64(values.fileSize ?? 0))
        }

        var totalSize = items.reduce(Int64(0)) { $0 + $1.size }
        guard totalSize > maxCacheSizeInBytes else { return }

        for item in items.sorted(by: { $0.modifiedAt < $1.modifiedAt }) {
            try? fileManager.removeItem(at: item.url)
            totalSize -= item.size
            if totalSize <= maxCacheSizeInBytes {
                break
            }
        }
    }

    private func inflightTask(for remoteURL: URL) -> Task<URL, Error>? {
        stateQueue.sync {
            inflightTasks[remoteURL]
        }
    }

    private func storeInflightTask(_ task: Task<URL, Error>, for remoteURL: URL) {
        stateQueue.sync {
            inflightTasks[remoteURL] = task
        }
    }

    private func removeInflightTask(for remoteURL: URL) {
        stateQueue.sync {
            inflightTasks.removeValue(forKey: remoteURL)
        }
    }
}
