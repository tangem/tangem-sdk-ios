//
//  LinkedTermianalStatus.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 15.06.2021.
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
