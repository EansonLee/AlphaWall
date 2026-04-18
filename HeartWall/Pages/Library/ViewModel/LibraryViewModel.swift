//
//  LibraryViewModel.swift
//  HeartWall
//

import Foundation
import Combine

final class LibraryViewModel: BaseViewModel {

    // MARK: - Inputs

    let viewDidLoad = PassthroughSubject<Void, Never>()

    // MARK: - Outputs

    @Published private(set) var videoItems: [VideoItem] = []
}
