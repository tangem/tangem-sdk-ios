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
public struct ExtendedPublicKey {
    public let compressedPublicKey: Data
    public let chainCode: Data
    
    public init(compressedPublicKey: Data, chainCode: Data) {
        self.compressedPublicKey = compressedPublicKey
        self.chainCode = chainCode
    }
    
    /// This function performs CKDpub((Kpar, cpar), i) → (Ki, ci) to compute a child extended public key from the parent extended public key.
    ///  It is only defined for non-hardened child keys.
    public func derivePublicKey(with index: Int) -> ExtendedPublicKey? {
        //We can derive only non-hardened keys
        guard index >= 0 && index <= Constants.maxNonHardenedIndex else {
            return nil
        }
        
        //let I = HMAC-SHA512(Key = cpar, Data = serP(Kpar) || ser32(i)).
        let data = compressedPublicKey + index.bytes4
        let hmac = HMAC<SHA512>.authenticationCode(for: data, using: SymmetricKey(data: chainCode))
        let digest = Data(hmac)
        
        guard let ki = Secp256k1Utils.createPublicKey(privateKey: digest[0..<32], compressed: true) else { return nil }
        guard let derivedPublicKey = Secp256k1Utils.sum(compressedPubKey1: ki, compressedPubKey2: compressedPublicKey) else { return nil }
        
        let derivedChainCode = digest[32..<64]
        return ExtendedPublicKey(compressedPublicKey: derivedPublicKey, chainCode: derivedChainCode)
    }
}

@available(iOS 13.0, *)
extension ExtendedPublicKey {
    enum Constants {
        static let maxNonHardenedIndex: Int = 2147483647 // 2^31-1. Index must be less then or equal this value
    }
}