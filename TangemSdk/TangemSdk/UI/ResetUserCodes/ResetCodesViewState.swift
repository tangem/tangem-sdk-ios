//
//  ResetCodesViewState.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

enum ResetCodesViewState {
    case empty
    case requestCode(_ type: UserCodeType, cardId: String?, completion: CompletionResult<String>)
    case resetCodes(_ type: UserCodeType, state: ResetPinService.State, cardId: String?, completion: CompletionResult<Bool>)
}
