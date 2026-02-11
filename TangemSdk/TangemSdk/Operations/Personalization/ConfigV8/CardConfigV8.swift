//
//  CardConfigV8.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 10.02.2026.
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/**
 * It is a configuration file with all the card settings that are written on the card
 * during [PersonalizeCommand] for V8 cards.
 */

public struct CardConfigV8: Decodable {
    let releaseVersion: Bool
    let issuerName: String
    let series: String?
    let startNumber: Int64
    let count: Int
    let numberFormat: String
    let pin: String
    let securityDelay: Int
    let curveID: EllipticCurve?
    let signingMethod: SigningMethod?
    let allowSetPIN: Bool
    let useActivation: Bool
    let useNDEF: Bool
    let useBlock: Bool
    let prohibitPurgeWallet: Bool
    let prohibitDefaultPIN: Bool
    let disableFiles: Bool?
    let allowHDWallets: Bool?
    let allowBackup: Bool?
    let allowKeysImport: Bool?
    let requireBackup: Bool?
    let createWallet: Int
    let cardData: CardConfigData
    let ndefRecords: [NdefRecord]
    /// Number of wallets supported by card, by default - 1
    let walletsCount: Byte?

    
    enum CodingKeys: String, CodingKey {
        case releaseVersion
        case issuerName
        case series
        case startNumber
        case count
        case numberFormat
        case pin = "PIN"
        case curveID
        case signingMethod = "SigningMethod"
        case allowSetPIN = "allowSwapPIN"
        case useActivation
        case useNDEF
        case useBlock
        case prohibitPurgeWallet = "forbidPurgeWallet"
        case prohibitDefaultPIN = "forbidDefaultPIN"
        case disableFiles
        case allowHDWallets
        case allowBackup
        case allowKeysImport
        case createWallet
        case cardData
        case ndefRecords = "NDEF"
        case walletsCount
        case securityDelay
        case requireBackup
    }
}

