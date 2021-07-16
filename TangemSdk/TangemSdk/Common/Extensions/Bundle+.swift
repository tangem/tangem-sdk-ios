//
//  Bundle+.swift
//  Pods-TangemSdkExample
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

@available(iOS 13.0, *)
extension Bundle {
    static var sdkBundle: Bundle {
        let selfBundle = Bundle(for: TangemSdk.self)
        if let path = selfBundle.path(forResource: "TangemSdk", ofType: "bundle"), //for pods
           let bundle = Bundle(path: path) {
            return bundle
        } else {
            return selfBundle
        }
    }
}
