//
//  ResetCodesViewState.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02.11.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

enum ResetCodesViewState {
    case empty
    case requestCode(UserCodeRequest)
    case resetCodes(ResetCodesRequest)
}
