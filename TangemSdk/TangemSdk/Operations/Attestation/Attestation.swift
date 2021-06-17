//
//  VerificationState.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 11.07.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct Attestation: Codable, JSONStringConvertible {
    public internal(set) var cardKeyAttestation: Status
    public internal(set) var walletKeysAttestation: Status
    public internal(set) var firmwareAttestation: Status
    public internal(set) var cardUniquenessAttestation: Status
}

public extension Attestation {
    enum Status: String, Codable {
        case verified, verifiedOffline, failed, skipped
    }
}

public extension Attestation {
    static var skipped: Attestation {
        .init(cardKeyAttestation: .skipped,
              walletKeysAttestation: .skipped,
              firmwareAttestation: .skipped,
              cardUniquenessAttestation: .skipped)
    }
}
