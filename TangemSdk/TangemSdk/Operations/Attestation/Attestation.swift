//
//  VerificationState.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 11.07.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct Attestation: Codable, JSONStringConvertible {
    public let walletKeysAttestation: Status
    public let cardKeyAttestation: Status
    public let firmwareAttestation: Status
    public let cardUniquenessAttestation: Status
}

public extension Attestation {
    enum Status: String, Codable {
        case verified, failed, skipped
    }
}

public extension Attestation {
    static var normalSuccess: Attestation {
        .init(walletKeysAttestation: .skipped,
              cardKeyAttestation: .verified,
              firmwareAttestation: .skipped,
              cardUniquenessAttestation: .skipped)
    }
    
    static var fullSuccess: Attestation {
        .init(walletKeysAttestation: .verified,
              cardKeyAttestation: .verified,
              firmwareAttestation: .skipped,
              cardUniquenessAttestation: .skipped)
    }
    
    static var skipped: Attestation {
        .init(walletKeysAttestation: .skipped,
              cardKeyAttestation: .skipped,
              firmwareAttestation: .skipped,
              cardUniquenessAttestation: .skipped)
    }
}
