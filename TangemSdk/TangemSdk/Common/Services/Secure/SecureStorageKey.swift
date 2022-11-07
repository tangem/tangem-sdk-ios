//
//  SecureStorageKey.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 06.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum SecureStorageKey: String {
    //attestation
    case attestedCards
    case signatureOfAttestedCards
    
    //access codes repo
    case cardsWithSavedCodes
    
    //secure enclave service
    case secureEnclaveP256Key
    
    //terminal keys service
    case terminalPrivateKey //link card to terminal
    case terminalPublicKey
    
    //backup service
    case backupData
}

extension SecureStorageKey {
    // Access codes repo
    static func accessCode(for cardId: String) -> String {
        "accessCode_\(cardId)"
    }
}
