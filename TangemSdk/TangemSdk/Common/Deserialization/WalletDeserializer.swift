//
//  CardWalletDeserializer.swift
//  TangemSdk
//
//  Created by Andrew Son on 16/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
/// Deserialize v4 walelts only
class WalletDeserializer {
    private let isDefaultPermanentWallet: Bool
    private let secp256k1KeyFormat: Secp256k1KeyFormat
    /// Default initializer
    /// - Parameter isDefaultPermanentWallet: Newest v4 cards don't have their own wallet settings, so we should take them from the card's settings
    /// - Parameter secp256k1KeyFormat: Format of the wallet's key
    internal init(isDefaultPermanentWallet: Bool, secp256k1KeyFormat: Secp256k1KeyFormat) {
        self.isDefaultPermanentWallet = isDefaultPermanentWallet
        self.secp256k1KeyFormat = secp256k1KeyFormat
    }
    
    func deserializeWallets(from decoder: TlvDecoder) throws -> (wallets: [Card.Wallet], totalReceived: Int) {
        let cardWalletsData: [Data] = try decoder.decodeArray(.cardWallet)
        
        guard !cardWalletsData.isEmpty else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let walletDecoders: [TlvDecoder] = cardWalletsData.compactMap {
            guard let infoTlvs = Tlv.deserialize($0) else { return nil }
            
            return TlvDecoder(tlv: infoTlvs)
        }
        
        let wallets: [Card.Wallet] = try walletDecoders.compactMap {
            do {
                return try deserializeWallet(from: $0)
            } catch TangemSdkError.walletNotFound {
                return nil
            }
        }
        
        return (wallets, cardWalletsData.count)
    }
    
    func deserializeWallet(from decoder: TlvDecoder) throws -> Card.Wallet {
        let status: Card.Wallet.Status = try decoder.decode(.status)
        guard status == .loaded || status == .backuped else { //We need only loaded wallets
            throw TangemSdkError.walletNotFound
        }
        
        return try deserialize(from: decoder, status: status)
    }
    
    private func deserialize(from decoder: TlvDecoder, status: Card.Wallet.Status) throws -> Card.Wallet {
        let mask: WalletSettingsMask? = try decoder.decode(.settingsMask)
        let settings: Card.Wallet.Settings = mask.map {.init(mask: $0)}
            ?? .init(isPermanent: isDefaultPermanentWallet) //Newest v4 cards don't have their own wallet settings, so we should take them from the card's settings
        let walletPublicKey: Data = try decoder.decode(.walletPublicKey)
        let curve: EllipticCurve = try decoder.decode(.curveId)
        let key = curve == .secp256k1 ? try secp256k1KeyFormat.format(walletPublicKey) : walletPublicKey
        
        return Card.Wallet(publicKey: key,
                           chainCode: try decoder.decode(.walletHDChain),
                           curve: curve,
                           settings: settings,
                           totalSignedHashes: try decoder.decode(.walletSignedHashes),
                           remainingSignatures: nil,
                           index: try decoder.decode(.walletIndex),
                           hasBackup: status == .backuped)
    }
}
