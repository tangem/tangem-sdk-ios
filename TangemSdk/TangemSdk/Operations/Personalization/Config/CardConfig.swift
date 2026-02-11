//
//  CardConfig.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 22.06.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/**
 * It is a configuration file with all the card settings that are written on the card
 * during [PersonalizeCommand].
 */
public struct CardConfig: Decodable {
    let releaseVersion: Bool
    let issuerName: String
    let series: String?
    let startNumber: Int64
    let count: Int
    let numberFormat: String
    let pin: String
    let pin2: String
    let pin3: String?
    let hexCrExKey: Data?
    let cvc: String
    let pauseBeforePin2: Int
    let smartSecurityDelay: Bool
    let curveID: EllipticCurve
    let signingMethod: SigningMethod
    let maxSignatures: Int?
    let allowSetPIN1: Bool
    let allowSetPIN2: Bool
    let useActivation: Bool
    let useCvc: Bool
    let useNDEF: Bool
    let useDynamicNDEF: Bool?
    let useOneCommandAtTime: Bool?
    let useBlock: Bool
    let allowSelectBlockchain: Bool
    let prohibitPurgeWallet: Bool
    let allowUnencrypted: Bool
    let allowFastEncryption: Bool
    let protectIssuerDataAgainstReplay: Bool?
    let prohibitDefaultPIN1: Bool
    let disablePrecomputedNDEF: Bool?
    let skipSecurityDelayIfValidatedByIssuer: Bool
    let skipCheckPIN2CVCIfValidatedByIssuer: Bool
    let skipSecurityDelayIfValidatedByLinkedTerminal: Bool
    let restrictOverwriteIssuerExtraData: Bool?
    let disableIssuerData: Bool?
    let disableUserData: Bool?
    let disableFiles: Bool?
    let allowHDWallets: Bool? //TODO: add precheck to specific commands
    let allowBackup: Bool?
    let allowKeysImport: Bool?
    let createWallet: Int
    let cardData: CardConfigData
    let ndefRecords: [NdefRecord]
    /// Number of wallets supported by card, by default - 1
    let walletsCount: Byte?
    let isReusable: Bool?

    enum CodingKeys: String, CodingKey {
        case releaseVersion
        case issuerName
        case series
        case startNumber
        case count
        case numberFormat
        case pin = "PIN"
        case pin2 = "PIN2"
        case pin3 = "PIN3"
        case hexCrExKey
        case cvc = "CVC"
        case pauseBeforePin2 = "pauseBeforePIN2"
        case smartSecurityDelay
        case curveID
        case signingMethod = "SigningMethod"
        case maxSignatures
        case allowSetPIN1 = "allowSwapPIN"
        case allowSetPIN2 = "allowSwapPIN2"
        case useActivation
        case useCvc = "useCVC"
        case useNDEF
        case useDynamicNDEF
        case useOneCommandAtTime
        case useBlock
        case allowSelectBlockchain
        case prohibitPurgeWallet = "forbidPurgeWallet"
        case allowUnencrypted = "protocolAllowUnencrypted"
        case allowFastEncryption = "protocolAllowStaticEncryption"
        case protectIssuerDataAgainstReplay
        case prohibitDefaultPIN1 = "forbidDefaultPIN"
        case disablePrecomputedNDEF
        case skipSecurityDelayIfValidatedByIssuer
        case skipCheckPIN2CVCIfValidatedByIssuer = "skipCheckPIN2andCVCIfValidatedByIssuer"
        case skipSecurityDelayIfValidatedByLinkedTerminal
        case restrictOverwriteIssuerExtraData = "restrictOverwriteIssuerDataEx"
        case disableIssuerData
        case disableUserData
        case disableFiles
        case allowHDWallets
        case allowBackup
        case allowKeysImport
        case createWallet
        case cardData
        case ndefRecords = "NDEF"
        case walletsCount
        case isReusable
    }
}
