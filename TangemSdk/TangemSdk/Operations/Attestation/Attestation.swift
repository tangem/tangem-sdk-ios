//
//  VerificationState.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 11.07.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct Attestation: Codable, JSONStringConvertible, Equatable {
    public internal(set) var cardKeyAttestation: Status
    public internal(set) var walletKeysAttestation: Status
    public internal(set) var firmwareAttestation: Status
    public internal(set) var cardUniquenessAttestation: Status
    
    /// Date of attestation
    public internal(set) var date: Date
    
    public var status: Status {
        if !statuses.contains(where: { $0 != .skipped} ) {
            return .skipped
        }
        
        if statuses.contains(.failed) {
            return .failed
        }
        
        if statuses.contains(.warning) {
            return .warning
        }
        
        if statuses.contains(.verifiedOffline) {
            return .verifiedOffline
        }
        
        return .verified
    }
    
    var mode: AttestationTask.Mode {
        if walletKeysAttestation == .skipped {
            return .normal
        }
        
        return .full
    }
    
    private var statuses: [Status] {
        return [cardKeyAttestation, walletKeysAttestation, firmwareAttestation, cardUniquenessAttestation]
    }
}

public extension Attestation {
    enum Status: String, Codable {
        case failed, warning, skipped, verifiedOffline, verified
    }
}

public extension Attestation {
    static var empty: Attestation {
        .init(cardKeyAttestation: .skipped,
              walletKeysAttestation: .skipped,
              firmwareAttestation: .skipped,
              cardUniquenessAttestation: .skipped,
              date: Date())
    }
}
