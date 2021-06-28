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
    
    /// Index for storage
    var index: Int = 0
    
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
    enum Status: Int, Codable {
        case failed, warning, skipped, verifiedOffline, verified
    }
}

public extension Attestation {
    static var empty: Attestation {
        .init(cardKeyAttestation: .skipped,
              walletKeysAttestation: .skipped,
              firmwareAttestation: .skipped,
              cardUniquenessAttestation: .skipped)
    }
}

extension Attestation {
    var rawRepresentaion: String {
        return "\(index),\(cardKeyAttestation.rawValue),\(walletKeysAttestation.rawValue),\(firmwareAttestation.rawValue),\(cardUniquenessAttestation.rawValue)"
    }
    
    init?(rawRepresentaion: String) {
        let values: [Int] = rawRepresentaion.split(separator: ",").compactMap { Int($0) }
        
        guard values.count == 5,
              let cardKeyAttestation = Status(rawValue: values[1]),
              let walletKeysAttestation = Status(rawValue: values[2]),
              let firmwareAttestation = Status(rawValue: values[3]),
              let cardUniquenessAttestation = Status(rawValue: values[4]) else {
            return nil
        }
        
        self.index = values[0]
        self.cardKeyAttestation = cardKeyAttestation
        self.walletKeysAttestation = walletKeysAttestation
        self.firmwareAttestation = firmwareAttestation
        self.cardUniquenessAttestation = cardUniquenessAttestation
    }
}
