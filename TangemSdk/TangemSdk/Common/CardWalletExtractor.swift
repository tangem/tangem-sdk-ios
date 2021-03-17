//
//  CardWalletExtractor.swift
//  TangemSdk
//
//  Created by Andrew Son on 17/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class CardWalletExtractor {
    static func extract(from card: Card, at index: WalletIndex?) throws -> CardWallet {
        if card.firmwareVersion < FirmwareConstraints.AvailabilityVersions.walletData {
            guard let wallet = card.wallets[0] else {
                throw TangemSdkError.walletNotFound
            }
            
            if case let.publicKey(pubkey) = index, wallet.publicKey != pubkey {
                throw TangemSdkError.walletNotFound
            }
            
            return wallet
        }
        
        guard
            let index = index,
            let wallet = card.wallet(at: index)
            else {
            throw TangemSdkError.walletIndexNotCorrect
        }
        
        return wallet
    }
}
