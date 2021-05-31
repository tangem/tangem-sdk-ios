//
//  WalletStatus.swift
//  TangemSdk
//
//  Created by Andrew Son on 24/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// Status of the wallet
public enum WalletStatus: Int, Codable, StatusType, JSONStringConvertible {
    /// Wallet not created
    case empty = 1
    /// Wallet created and can be used for signing
    case loaded = 2
    /// Wallet was purged and can't be recreated or used for signing
    case purged = 3

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("\(self)".capitalized)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.singleValueContainer()
        let stringValue = try values.decode(String.self).lowercasingFirst()
        switch stringValue {
        case "empty":
            self = .empty
        case "loaded":
            self = .loaded
        case "purged":
            self = .purged
        default:
            throw TangemSdkError.decodingFailed("Failed to decode WalletStatus")
        }
    }
    
    public init(from cardStatus: CardStatus) {
        switch cardStatus {
        case .empty, .notPersonalized:
            self = .empty
        case .loaded:
            self = .loaded
        case .purged:
            self = .purged
        }
    }
}
