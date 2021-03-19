//
//  CardWalletDeserializerUtility.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class CardWalletDeserializerUtility {
    static func deserialize(from decoder: DefaultTlvDecoder) throws -> CardWallet {
        CardWallet(index: try decoder.decode(.walletIndex),
                   status: try decoder.decode(.status),
                   curve: try decoder.decodeOptional(.curveId),
                   settingsMask: try decoder.decodeOptional(.settingsMask),
                   publicKey: try decoder.decodeOptional(.walletPublicKey),
                   signedHashes: try decoder.decodeOptional(.walletSignedHashes))
    }
}
