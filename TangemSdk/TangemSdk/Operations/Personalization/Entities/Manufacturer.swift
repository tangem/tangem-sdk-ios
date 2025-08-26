//
//  Manufacturer.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct Manufacturer: Codable, JSONStringConvertible {
    let keyPair: KeyPair
    let name: String?
}
