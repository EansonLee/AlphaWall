//
//  BaseViewModel.swift
//  HeartWall
//

import Foundation
import Combine

class BaseViewModel {

    // MARK: - Outputs

    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    // MARK: - Properties

    var cancellables = Set<AnyCancellable>()

    // MARK: - Helpers

    func setLoading(_ loading: Bool) {
        isLoading = loading
    }

    func setError(_ message: String?) {
        errorMessage = message
    }
}
