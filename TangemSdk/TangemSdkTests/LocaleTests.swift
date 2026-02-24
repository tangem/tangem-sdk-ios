//
//  LocaleTests.swift
//  TangemSdkTests
//
//  Created by GuitarKitty on 20.02.2026.
//

import Foundation
import Testing
@testable import TangemSdk

@Suite("LocaleTests")
struct LocaleTests {
    private static let supportedCodes: Set<String> = ["en", "es", "pt", "de", "ja", "fr", "tr", "ko", "zh-Hans"]

    static let resolveLanguageCodeArguments: [([String], String, String)] = [
        // Alpha-2 exact match
        (["de"], "en", "de"),
        (["fr", "de"], "en", "fr"),
        (["es"], "en", "es"),
        (["ko"], "en", "ko"),
        (["tr"], "en", "tr"),

        // Fallback to second identifier when first is unsupported
        (["ru", "es"], "en", "es"),
        (["uk", "ja"], "en", "ja"),

        // Script subtag matching
        (["zh-Hans"], "en", "zh-Hans"),
        (["zh-Hans-CN"], "en", "zh-Hans"),

        // Script subtag not in supported set — fallback
        (["zh-Hant"], "en", "en"),

        // Full locale identifiers — extracts alpha-2
        (["ja-JP"], "en", "ja"),
        (["pt-BR"], "en", "pt"),
        (["de-AT"], "en", "de"),
        (["fr-CA"], "en", "fr"),
        (["es-MX"], "en", "es"),

        // Fallback scenarios
        (["ru", "uk"], "en", "en"),
        (["ru"], "de", "de"),
        ([], "en", "en"),
    ]

    @Test("Resolves language code from identifiers", arguments: resolveLanguageCodeArguments)
    func resolveLanguageCode(identifiers: [String], fallback: String, expected: String) {
        let result = Locale.resolveLanguageCode(
            identifiers: identifiers,
            supportedCodes: Self.supportedCodes,
            fallback: fallback
        )
        #expect(result == expected)
    }
}
