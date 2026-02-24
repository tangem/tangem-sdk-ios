//
//  Locale+.swift
//  TangemSdk
//
//  Created by GuitarKitty on 20.02.2026.
//

import Foundation

extension Locale {
    static let appLanguageCode = Bundle.main.preferredLocalizations.first ?? enLanguageCode

    static let deviceLanguageCode: String = {
        let languages = CFPreferencesCopyAppValue("AppleLanguages" as CFString, kCFPreferencesAnyApplication) as? [String]
        return languages?.first ?? enLanguageCode
    }()
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
            identifiers: [appLanguageCode, deviceLanguageCode],
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
