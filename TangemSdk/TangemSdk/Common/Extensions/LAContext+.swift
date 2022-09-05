//
//  LAContext+.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import LocalAuthentication

extension LAContext {
    static var `default`: LAContext {
        let context = LAContext()
        context.touchIDAuthenticationAllowableReuseDuration = 0
        return context
    }
}
