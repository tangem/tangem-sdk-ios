//
//  Bundle+.swift
//  Pods-TangemSdkExample
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

extension Bundle {
    static var sdkBundle: Bundle {
#if SWIFT_PACKAGE
        return Bundle.module
#else
        let selfBundle = Bundle(for: TangemSdk.self)
        if let path = selfBundle.path(forResource: "TangemSdk", ofType: "bundle"), //for pods
           let bundle = Bundle(path: path) {
            return bundle
        } else {
            return selfBundle
        }
#endif  // SWIFT_PACKAGE
    }
}
