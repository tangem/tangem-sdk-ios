//
//  CardStatus.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

protocol StatusType {
    var rawValue: Int { get }
}

/// Status of the card and its wallet.
enum CardStatus: Int, Codable, StatusType {
	case notPersonalized = 0
	case empty = 1
	case loaded = 2
	case purged = 3
}
