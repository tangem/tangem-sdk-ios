//
//  OnlineAttestationService.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

protocol OnlineAttestationService {
    func attestCard() -> AnyPublisher<OnlineAttestationResponse, Error>
}
