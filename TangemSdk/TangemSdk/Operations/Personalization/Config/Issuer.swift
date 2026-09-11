//
//  Issuer.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct Issuer: Codable, JSONStringConvertible {
    let name: String
    let id: String
    let dataKeyPair: KeyPair
    let transactionKeyPair: KeyPair
}
