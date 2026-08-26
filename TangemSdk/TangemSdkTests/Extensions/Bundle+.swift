//
//  Bundle+.swift
//  TangemSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension Bundle {
    enum Folder: String {
        case bip39 = "BIP39"
        case files = "Files"
        case personalize = "Personalize"
        case root = ""
    }

    static func readFileAsString(name: String, in folder: Folder) throws -> String {
        let filePath = try filePath(name: name, in: folder)

        return try String(contentsOfFile: filePath)
    }

    static func readFileAsData(name: String, in folder: Folder) throws -> Data {
        let filePath = try filePath(name: name, in: folder)

        return try Data(contentsOf: URL(fileURLWithPath: filePath))
    }

    /// SPM preserves folder structure for resources, unlike Cocoapods.
    /// Therefore, a full file path with all intermediate directories must be constructed.
    private static func filePath(name: String, in folder: Folder) throws -> String {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        let resource = [
            "Jsons",
            folder.rawValue,
            name,
        ].joined(separator: "/")
        #else
        let bundle = Bundle(for: Dummy.self)
        let resource = name
        #endif // SWIFT_PACKAGE

        guard let path = bundle.path(forResource: resource, ofType: "json") else {
            throw NSError(domain: "BundleTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Resource not found: \(resource).json"])
        }
        return path
    }
}

#if !SWIFT_PACKAGE
private final class Dummy {}
#endif // SWIFT_PACKAGE
