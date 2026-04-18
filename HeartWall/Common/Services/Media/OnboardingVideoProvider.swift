//
//  OnboardingVideoProvider.swift
//  HeartWall
//

import Foundation

enum OnboardingVideoResource: String, CaseIterable {
    case appGuide1 = "app_guide_1"
    case appGuide2 = "app_guide_2"
    case appGuide3 = "app_guide_3"

    var fileExtension: String {
        "mp4"
    }

    func bundleURL(in bundle: Bundle = .main) -> URL? {
        bundle.url(forResource: rawValue, withExtension: fileExtension)
            ?? bundle.url(forResource: rawValue, withExtension: fileExtension, subdirectory: "Videos")
            ?? bundle.url(forResource: rawValue, withExtension: fileExtension, subdirectory: "Resources/Videos")
    }
}

final class OnboardingVideoProvider {

    static let shared = OnboardingVideoProvider()

    let selectedResource: OnboardingVideoResource

    private init(selectedResource: OnboardingVideoResource = OnboardingVideoResource.allCases.randomElement() ?? .appGuide1) {
        self.selectedResource = selectedResource
    }

    var selectedURL: URL? {
        selectedResource.bundleURL()
    }
}
