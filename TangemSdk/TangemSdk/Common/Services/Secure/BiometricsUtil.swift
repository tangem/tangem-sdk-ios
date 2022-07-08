//
//  BiometricsUtil.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import LocalAuthentication

final class BiometricsUtil {
    static var isAvailable: Bool {
        var error: NSError?
        
        let context = LAContext()
        let result = context.canEvaluatePolicy(authenticationPolicy, error: &error)
        
        if let error = error {
            Log.error(error)
        }
        
        return result
    }
    
    private static let authenticationPolicy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics
}

