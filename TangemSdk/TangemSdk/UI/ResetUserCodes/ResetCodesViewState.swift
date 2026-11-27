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
    case intro(ResetCodesIntroRequest)
    case requestCode(UserCodeRequest)
    case resetCodes(ResetCodesRequest)
    case success(ResetCodesRequest)
}
