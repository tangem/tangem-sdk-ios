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
    case attestedCardsEncryptionKey

    case onlineAttestationResponses
    case onlineAttestationResponsesEncryptionKey

    //access codes repo
    case cardsWithSavedCodes
    case cardsWithSavedCodesEncryptionKey

    //card access tokens repo
    case cardsWithSavedAccessTokens
    case cardsWithSavedAccessTokensEncryptionKey

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

    static func accessCodeEncryptionKey(for cardId: String) -> String {
        "accessCode_encryption_key_\(cardId)"
    }

    // Card access tokens repo
    static func cardAccessTokens(for cardId: String) -> String {
        "cardAccessTokens_\(cardId)"
    }

    static func cardAccessTokensEncryptionKey(for cardId: String) -> String {
        "cardAccessTokens_encryption_key_\(cardId)"
    }
}
