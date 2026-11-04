//
//  OnlineAttestationService.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol OnlineAttestationService {
    func attestCard() async throws -> OnlineAttestationResponse
}
