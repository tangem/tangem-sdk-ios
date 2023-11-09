//
//  PreflightReadFilterFactory.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
protocol PreflightReadFilterFactory {
    func makePreflightReadFilter(for card: Card) -> PreflightReadFilter
}

@available(iOS 13.0, *)
struct CommonPreflightReadFilterFactory: PreflightReadFilterFactory {
    private let sessionFilter: SessionFilter

    init(with sessionFilter: SessionFilter) {
        self.sessionFilter = sessionFilter
    }

    func makePreflightReadFilter(for card: Card) -> PreflightReadFilter {
        switch sessionFilter {
        case .cardId(let cardId):
            return CardIdPreflightReadFilter(cardId: cardId)
        case .cardKitId(let data):
            return PublicKeyPreflightReadFilter(publicKeyId: data)
        }
    }
}
