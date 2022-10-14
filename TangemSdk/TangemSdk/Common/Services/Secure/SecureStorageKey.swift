//
//  SecureStorageKey.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum SecureStorageKey: String {
    //attestation
    case attestedCards
    case signatureOfAttestedCards
    
    //access codes repo
    case cardsWithSavedCodes
    static func accessCode(for cardId: String) -> String {
        "accessCode_\(cardId)"
    }
    
    //secure enclave service
    case secureEnclaveP256Key
    
    //terminal keys service
    case terminalPrivateKey //link card to terminal
    case terminalPublicKey
    
    //backup service
    case backupData
}
