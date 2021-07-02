//
//  LinkedTermianalStatus.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public extension Card {
    /// Card's linked terminal status
    enum LinkedTerminalStatus: String, Codable {
        case current
        case other
        case none
    }
}
