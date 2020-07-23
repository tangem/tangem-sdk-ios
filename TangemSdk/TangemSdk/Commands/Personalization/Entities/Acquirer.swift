//
//  Acquirer.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct Acquirer: Codable {
    let keyPair: KeyPair
    let name: String?
    let id: String?
}
