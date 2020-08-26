//
//  CardValues.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct CardValues: Codable {
    let isPin1Default: Bool
    let isPin2Default: Bool
    let cardVerification: VerificationState?
    let cardValidation: VerificationState?
    let codeVerification: VerificationState?
}
