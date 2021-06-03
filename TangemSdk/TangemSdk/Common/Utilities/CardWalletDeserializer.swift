//
//  CardWalletDeserializer.swift
//  TangemSdk
//
//  Created by Andrew Son on 16/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class CardWalletDeserializer {
    private static func deserialize(from decoder: TlvDecoder) throws -> CardWallet {
        CardWallet(index: try decoder.decode(.walletIndex),
                   curve: try decoder.decode(.curveId),
                   settingsMask: try decoder.decode(.settingsMask),
                   publicKey: try decoder.decode(.walletPublicKey),
                   totalSignedHashes: try decoder.decode(.walletSignedHashes))
    }
    
    static func deserializeWallet(from decoder: TlvDecoder) throws -> CardWallet {
        let status: WalletStatus = try decoder.decode(.status)
        guard status == .loaded else { //We need only loaded wallets
            throw TangemSdkError.walletIsNotCreated
        }
        
        return try CardWalletDeserializer.deserialize(from: decoder)
    }
    
    static func deserializeWallets(from decoder: TlvDecoder) throws -> [CardWallet] {
        let cardWalletsData: [Data] = try decoder.decodeArray(.cardWallet)
        
        guard cardWalletsData.count > 0 else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let walletDecoders: [TlvDecoder] = cardWalletsData.compactMap {
            guard let infoTlvs = Tlv.deserialize($0) else { return nil }
            
            return TlvDecoder(tlv: infoTlvs)
        }
        
        let wallets: [CardWallet] = try walletDecoders.compactMap {
            do {
                return try CardWalletDeserializer.deserialize(from: $0)
            } catch TangemSdkError.walletIsNotCreated {
                return nil
            }
        }
        
        return wallets
    }
}

