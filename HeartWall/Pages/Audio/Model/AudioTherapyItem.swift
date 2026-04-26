//
//  AudioTherapyItem.swift
//  HeartWall
//

import Foundation
import UIKit

struct AudioTherapyItem: Identifiable {
    let id = UUID()
    let title: String
    let listenerCount: Int
    let category: AudioTherapyCategory
    let videoURL: URL
    let accentColor: UIColor
}

enum AudioTherapyCategory: String, CaseIterable {
    case recommended = "推荐"
    case sleep = "睡眠"
    case focus = "专注"
    case relief = "减压"
    case meditation = "冥想"
    case rain = "风雨"
    case scene = "场景"
}
