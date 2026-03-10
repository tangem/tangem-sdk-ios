//
//  Locale+.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

extension Locale {
    static let appLanguageCode = Bundle.main.preferredLocalizations.first ?? enLanguageCode

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
    static let ruLanguageCode = "ru"
    static let byLanguageCode = "by"
}

extension Locale {
    /// Returns supported language code with priority: appLanguage → deviceLanguage → fallback.
    /// Supports codes with script subtags (e.g. `zh-Hans`).
    static func languageCode(supportedCodes: Set<String>, fallback: String = enLanguageCode) -> String {
        resolveLanguageCode(
            identifiers: [appLanguageCode, deviceLanguageCode()],
            supportedCodes: supportedCodes,
            fallback: fallback
        )
    }

    /// Pure function for resolving language code from a list of identifiers.
    /// Testable without depending on system state.
    static func resolveLanguageCode(
        identifiers: [String],
        supportedCodes: Set<String>,
        fallback: String = enLanguageCode
    ) -> String {
        for identifier in identifiers {
            let language = Locale.Language(identifier: identifier)
            guard let alpha2 = language.languageCode?.identifier(.alpha2) else { continue }

            // Check code with script (e.g. "zh-Hans")
            if let script = language.script {
                let withScript = "\(alpha2)-\(script.identifier.capitalized)"
                if supportedCodes.contains(withScript) {
                    return withScript
                }
            }

            // Check alpha-2 only (e.g. "en")
            if supportedCodes.contains(alpha2) {
                return alpha2
            }
        }

        return fallback
    }
}
