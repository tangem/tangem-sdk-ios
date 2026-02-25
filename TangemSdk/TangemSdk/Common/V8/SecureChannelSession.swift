//
//  SecureChannelSession.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 20/02/2026.
//

import Foundation

/// Encapsulates all CCM encryption state for v8+ secure channel protocol.
class SecureChannelSession {
    private(set) var accessLevel: AccessLevel = .publicAccess
    private(set) var isPinChecked: Bool = false
    private(set) var packetCounter: Int = 0
    var cardTokens: CardTokens?

    /// Constructs a 12-byte nonce for AES-CCM encryption.
    /// Format: [prefix(1)] + [cardId bytes(8)] + [packetCounter big-endian(3)] = 12 bytes
    func makeNonce(forSend: Bool, cardId: String) -> Data {
        let prefix: UInt8 = forSend ? 0x7E : 0xCA
        let cardIdBytes = Data(hexString: cardId)
        let counterBytes = packetCounter.toBytes(count: 3)
        return Data([prefix]) + cardIdBytes + counterBytes
    }

    func incrementPacketCounter() {
        packetCounter += 1
    }

    func didEstablishChannel(accessLevel: AccessLevel) {
        self.accessLevel = accessLevel
        self.packetCounter = 1
    }

    func didAuthorizePin(accessLevel: AccessLevel) {
        self.accessLevel = accessLevel
        self.isPinChecked = true
    }

    func reset() {
        accessLevel = .publicAccess
        isPinChecked = false
        packetCounter = 0
    }
}
