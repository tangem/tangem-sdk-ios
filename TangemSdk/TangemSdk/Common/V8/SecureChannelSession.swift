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
    private(set) var isAuthorizedWithAccessCode: Bool = false
    private(set) var packetCounter: Int = 0
    private let cardIdBytes: Data

    init(cardId: String) {
        cardIdBytes = Data(hexString: cardId)
    }

    /// Constructs a 12-byte nonce for AES-CCM encryption.
    /// Format: [prefix(1)] + [cardId bytes(8)] + [packetCounter big-endian(3)] = 12 bytes
    func makeCommandAPDUNonce() -> Data {
        let prefix: UInt8 = 0x7E
        let counterBytes = packetCounter.toBytes(count: 3)
        return Data([prefix]) + cardIdBytes + counterBytes
    }

    /// Constructs a 12-byte nonce for AES-CCM encryption.
    /// Format: [prefix(1)] + [cardId bytes(8)] + [packetCounter big-endian(3)] = 12 bytes
    func makeResponseAPDUNonce() -> Data {
        let prefix: UInt8 = 0xCA
        let counterBytes = packetCounter.toBytes(count: 3)
        return Data([prefix]) + cardIdBytes + counterBytes
    }

    func incrementPacketCounter() {
        guard accessLevel != .publicAccess else {
            // Do not increment the counter until the secure channel is established
            return
        }

        packetCounter += 1
    }

    func isElevationRequired(for encryption: CardSessionEncryption) -> Bool {
        switch encryption {
        case .none:
            return false
        case .publicSecureChannel:
            return accessLevel.isPublic
        case .secureChannel:
            return accessLevel.isPublic || accessLevel.isPublicSecureChannel
        case .secureChannelWithPIN:
            return accessLevel.isPublic || accessLevel.isPublicSecureChannel || !isAuthorizedWithAccessCode
        }
    }

    func didEstablishChannel(accessLevel: AccessLevel) {
        self.accessLevel = accessLevel
        packetCounter = 1
    }

    func didAuthorizePin(accessLevel: AccessLevel) {
        self.accessLevel = accessLevel
        isAuthorizedWithAccessCode = true
    }

    func reset() {
        accessLevel = .publicAccess
        isAuthorizedWithAccessCode = false
        packetCounter = 0
    }
}
