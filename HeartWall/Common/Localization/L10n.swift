//
//  L10n.swift
//  HeartWall
//

import Foundation

enum L10n {
    static func text(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    static func text(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: Locale.current, arguments: arguments)
    }

    static func content(_ rawValue: String) -> String {
        let key = "content.\(rawValue)"
        let localized = text(key)
        if localized != key {
            return localized
        }

        guard prefersTraditionalChinese else {
            return rawValue
        }

        return rawValue.applyingTransform(StringTransform(rawValue: "Hans-Hant"), reverse: false) ?? rawValue
    }

    static func dateFormatter(dateFormatKey: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = text(dateFormatKey)
        return formatter
    }

    private static var prefersTraditionalChinese: Bool {
        let preferredLocalization = Bundle.main.preferredLocalizations.first ?? ""
        let preferredLanguage = Locale.preferredLanguages.first ?? ""
        return preferredLocalization == "zh-Hant"
            || preferredLanguage.hasPrefix("zh-Hant")
            || preferredLanguage.hasPrefix("zh-HK")
            || preferredLanguage.hasPrefix("zh-TW")
            || preferredLanguage.hasPrefix("zh-MO")
    }
}
