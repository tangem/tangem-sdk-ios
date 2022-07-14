//
//  BiometricsUtil.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 01.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import LocalAuthentication

public final class BiometricsUtil {
    public static var isAvailable: Bool {
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

