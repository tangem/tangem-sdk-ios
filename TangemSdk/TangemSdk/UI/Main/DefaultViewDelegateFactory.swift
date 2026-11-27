//
//  DefaultViewDelegateFactory.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct DefaultViewDelegateFactory: ViewDelegateFactory {
    let style: TangemSdkStyle

    func makeSessionViewDelegate(reader: CardReader) -> SessionViewDelegate {
        DefaultSessionViewDelegate(reader: reader, style: style)
    }

    func makeResetCodesViewDelegate() -> ResetCodesViewDelegate {
        DefaultResetCodesViewDelegate(style: style)
    }
}
