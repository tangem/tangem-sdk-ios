//
//  Locale+.swift
//  TangemSdk
//
//  Created by GuitarKitty on 20.02.2026.
//

import Foundation

extension Locale {
    static let appLanguageCode = Locale.current.language.languageCode?.identifier(.alpha2) ?? enLanguageCode

    static func deviceLanguageCode(
        withRegion: Bool = true,
        fallback: LanguageCode = .english
    ) -> String {
        // Get the list of device languages in the order set by the user. Format: [language]-[region]
        let languages = CFPreferencesCopyAppValue("AppleLanguages" as CFString, kCFPreferencesAnyApplication) as? [String]

        // Use fallback if no languages are found
        guard let language = languages?.first else {
            return fallback.identifier
        }

        if withRegion {
            return language
        }

        let separator = "-"
        let languageParts = language.split(separator: separator)

        // We cannot rely on `Locale.language.script` because its standard may differ from the device language identifier
        if languageParts.count > 1 {
            return languageParts.dropLast().joined(separator: separator)
        } else {
            return language
        }
    }
}

extension Locale {
    static let enLanguageCode = "en"
}
