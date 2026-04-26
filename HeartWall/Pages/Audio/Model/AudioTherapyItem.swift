//
//  AudioTherapyItem.swift
//  HeartWall
//

import Foundation
import UIKit

struct AudioTherapyItem: Identifiable {
    let id: String
    let title: String
    let listenerCount: Int
    let categoryID: String
    let categoryTitle: String
    let videoURL: URL
    let accentColor: UIColor
}

struct AudioTherapyCategory: Identifiable, Equatable {
    let id: String
    let title: String
    let file: String
    let count: Int
}
