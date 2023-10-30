//
//  JSONStringConvertible.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// The basic protocol for command response
@available(iOS 13.0, *)
public protocol JSONStringConvertible: Encodable {
    var json: String {get}
}

@available(iOS 13.0, *)
public extension JSONStringConvertible {
    var json: String {
        let data = (try? JSONEncoder.tangemSdkEncoder.encode(self)) ?? Data()
        return String(data: data, encoding: .utf8)!
    }

    var testJson: String {
        let data = (try? JSONEncoder.tangemSdkTestEncoder.encode(self)) ?? Data()
        return String(data: data, encoding: .utf8)!
    }

    func eraseToAnyResponse() -> AnyJSONRPCResponse {
        AnyJSONRPCResponse(self)
    }
}
