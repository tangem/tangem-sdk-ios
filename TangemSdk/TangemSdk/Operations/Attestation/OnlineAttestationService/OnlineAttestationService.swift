//
//  OnlineAttestationService.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24/03/2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol OnlineAttestationService {
    func attestCard() async throws -> OnlineAttestationResponse
}
