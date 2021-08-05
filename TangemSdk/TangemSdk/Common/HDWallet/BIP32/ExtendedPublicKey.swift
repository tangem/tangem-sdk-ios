//
//  ExtendedPublicKey.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 30.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

@available(iOS 13.0, *)
/// BIP32 extended public key
public struct ExtendedPublicKey: Equatable {
    public let compressedPublicKey: Data
    public let chainCode: Data
    
    public init(compressedPublicKey: Data, chainCode: Data) {
        self.compressedPublicKey = compressedPublicKey
        self.chainCode = chainCode
    }
    
    /// This function performs CKDpub((Kpar, cpar), i) → (Ki, ci) to compute a child extended public key from the parent extended public key.
    ///  It is only defined for non-hardened child keys.
    public func derivePublicKey(index: UInt32) throws -> ExtendedPublicKey {
        //We can derive only non-hardened keys
        guard index >= 0 && index < BIP32.Constants.hardenedOffset else {
            throw HDWalletError.hardenedNotSupported
        }
        
        //let I = HMAC-SHA512(Key = cpar, Data = serP(Kpar) || ser32(i)).
        let data = compressedPublicKey + index.bytes4
        let hmac = HMAC<SHA512>.authenticationCode(for: data, using: SymmetricKey(data: chainCode))
        let digest = Data(hmac)
        
        guard let ki = Secp256k1Utils.createPublicKey(privateKey: digest[0..<32], compressed: true) else {
            throw HDWalletError.derivationFailed
        }
        
        guard let derivedPublicKey = Secp256k1Utils.sum(compressedPubKey1: ki, compressedPubKey2: compressedPublicKey) else {
            throw HDWalletError.derivationFailed
        }
        
        let derivedChainCode = digest[32..<64]
        return ExtendedPublicKey(compressedPublicKey: derivedPublicKey, chainCode: derivedChainCode)
    }
    
    /// This function performs CKDpub((Kpar, cpar), i) → (Ki, ci) to compute a child extended public key from the parent extended public key.
    ///  It is only defined for non-hardened child keys.
    public func derivePublicKey(node: DerivationNode) throws -> ExtendedPublicKey {
        try derivePublicKey(index: node.index)
    }
    
    /// This function performs CKDpub((Kpar, cpar), i) → (Ki, ci) to compute a child extended public key from the parent extended public key.
    ///  It is only defined for non-hardened child keys.
    public func derivePublicKey(path derivationPath: DerivationPath) throws -> ExtendedPublicKey {
        var key: ExtendedPublicKey = self
        
        for node in derivationPath.nodes {
            key = try key.derivePublicKey(node: node)
        }
        
        return key
    }
}
