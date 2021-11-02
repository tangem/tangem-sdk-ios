//
//  ResetCodesViewState.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02.11.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
enum ResetCodesViewState {
    case empty
    case requestCode(_ type: UserCodeType, cardId: String?, completion: ((_ code: String?) -> Void))
    case resetCodes(_ type: UserCodeType, state: ResetPinService.State, cardId: String?, completion: ((_ shouldContinue: Bool) -> Void))
}
