//
//  VideoItem.swift
//  HeartWall
//

import Foundation

struct VideoItem: Identifiable {
    let id: UUID
    var title: String
    var url: URL
    var duration: TimeInterval
    var createdAt: Date
    var thumbnailPath: String?

    init(id: UUID = UUID(), title: String, url: URL, duration: TimeInterval = 0, createdAt: Date = Date(), thumbnailPath: String? = nil) {
        self.id = id
        self.title = title
        self.url = url
        self.duration = duration
        self.createdAt = createdAt
        self.thumbnailPath = thumbnailPath
    }
}
