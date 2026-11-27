//
//  ViewDelegateFactory.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol ViewDelegateFactory {
    func makeSessionViewDelegate(reader: CardReader) -> SessionViewDelegate

    func makeResetCodesViewDelegate() -> ResetCodesViewDelegate
}
