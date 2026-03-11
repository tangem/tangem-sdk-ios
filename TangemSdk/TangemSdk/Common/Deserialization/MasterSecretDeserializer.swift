//
//  MasterSecretDeserializer.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 06/03/26.
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialize master secrets
struct MasterSecretDeserializer {
    func deserializeMasterSecret(from decoder: TlvDecoder) -> Card.MasterSecret? {
        guard let status: Card.Wallet.Status = try? decoder.decode(.status),
              status.isAvailable else {
            return nil
        }

        return deserialize(from: decoder, status: status)
    }

    private func deserialize(from decoder: TlvDecoder, status: Card.Wallet.Status) -> Card.MasterSecret {
        return Card.MasterSecret(
            publicKey: try? decoder.decode(.walletPublicKey),
            chainCode: try? decoder.decode(.walletHDChain),
            curve: .secp256k1,
            isImported: status.isImported,
            hasBackup: status.isBackedUp,
            status: status
        )
    }
}
