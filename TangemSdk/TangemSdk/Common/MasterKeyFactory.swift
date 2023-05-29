//
//  MasterKeyFactory.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 26.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
struct MasterKeyFactory {
    func makePrivateKey(from seed: Data, curve: EllipticCurve) throws -> ExtendedPrivateKey {
        switch curve {
        case .bls12381_G2, .bls12381_G2_AUG, .bls12381_G2_POP:
            let keyData = try BLSUtils().generateKey(inputKeyMaterial: seed)
            return ExtendedPrivateKey(privateKey: keyData, chainCode: Data())
        case .secp256k1, .secp256r1, .bip0340, .ed25519:
            return try BIP32().makeMasterKey(from: seed, curve: curve)
        }
    }
}
