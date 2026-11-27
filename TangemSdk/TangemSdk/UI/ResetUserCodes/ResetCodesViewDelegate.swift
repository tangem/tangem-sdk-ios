//
//  ResetCodesViewDelegate.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol ResetCodesViewDelegate: AnyObject {
    func setState(_ state: ResetCodesViewState)

    func showError(_ error: TangemSdkError)

    func showAlert(_ title: String, message: String, onContinue: @escaping () -> Void)

    func hide(completion: (() -> Void)?)
}
