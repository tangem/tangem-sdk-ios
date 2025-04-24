//
//  OnlineAttestationService.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24/03/2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

protocol OnlineAttestationService {
    func attestCard() -> AnyPublisher<OnlineAttestationResponse, Error>
}
