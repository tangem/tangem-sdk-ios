//
//  CardValues.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 11.07.2020.
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
