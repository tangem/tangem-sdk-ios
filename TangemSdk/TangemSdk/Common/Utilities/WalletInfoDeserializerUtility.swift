//
//  WalletInfoDeserializerUtility.swift
//  TangemSdk
//
//  Created by Andrew Son on 16/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class WalletInfoDeserializerUtility {
    static func deserializeWalletInfo(from decoder: DefaultTlvDecoder) throws -> WalletInfo {
        WalletInfo(index: try decoder.decode(.walletIndex),
                   status: try decoder.decode(.status),
                   curve: try decoder.decodeOptional(.curveId),
                   settingsMask: try decoder.decodeOptional(.settingsMask),
                   publicKey: try decoder.decodeOptional(.walletPublicKey),
                   signedHashes: try decoder.decodeOptional(.walletSignedHashes),
                   userCounter: try decoder.decodeOptional(.userCounter),
                   userProtectedCounter: try decoder.decodeOptional(.userProtectedCounter))
    }
}
