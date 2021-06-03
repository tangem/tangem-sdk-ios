//
//  CardWalletDeserializer.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class CardWalletDeserializer {
    static func deserialize(from decoder: TlvDecoder) throws -> CardWallet {
        CardWallet(index: try decoder.decode(.walletIndex),
                   curve: try decoder.decode(.curveId),
                   settingsMask: try decoder.decode(.settingsMask),
                   publicKey: try decoder.decode(.walletPublicKey),
                   totalSignedHashes: try decoder.decode(.walletSignedHashes))
    }
}
