//
//  CardIdPreflightReadFilter.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public struct CardIdPreflightReadFilter: PreflightReadFilter {
    public let expectedCardId: String

    public init(cardId: String) {
        expectedCardId = cardId
    }

    public func onCardRead(_ card: Card, environment: SessionEnvironment) throws {
        guard environment.config.handleErrors,
              expectedCardId.caseInsensitiveCompare(card.cardId) != .orderedSame else {
            return
        }

        let formatter = CardIdFormatter(style: environment.config.cardIdDisplayFormat)
        let expectedCardIdFormatted = formatter.string(from: expectedCardId)
        throw TangemSdkError.wrongCardNumber(expectedCardId: expectedCardIdFormatted)
    }

    public func onFullCardRead(_ card: Card, environment: SessionEnvironment) throws {}
}
