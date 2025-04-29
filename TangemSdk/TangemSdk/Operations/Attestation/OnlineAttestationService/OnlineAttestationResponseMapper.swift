//
//  OnlineAttestationResponseMapper.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 25/03/2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct OnlineAttestationResponseMapper {
    let card: Card

    func mapError(_ error: Error) -> Attestation.Status {
        if let networkError = error as? NetworkServiceError {
            switch networkError {
            case .urlSessionError:
                return Attestation.Status.verifiedOffline
            default:
                break
            }
        }

        return Attestation.Status.failed
    }

    func mapValue(_ value: OnlineAttestationResponse) -> Attestation.Status {
        // Dev card cannot be attested online
        if card.firmwareVersion.type == .sdk {
            return Attestation.Status.failed
        }

        return Attestation.Status.verified
    }
}
