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

        let context = LAContext.default
        let result = context.canEvaluatePolicy(authenticationPolicy, error: &error)

        if let error = error {
            Log.error(error)
        }

        return result
    }

    public static var biometryType: LABiometryType {
        let context = LAContext.default
        var error: NSError?
        let _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return context.biometryType
    }

    public static let authenticationPolicy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics

    /// Request access to biometrics
    /// - Parameters:
    ///   - localizedReason:The app-provided reason for requesting authentication, which displays in the authentication dialog presented to the user. Must be non-empty. Only for touchID.
    ///   - completion: Result<Void, TangemSdkError>
    public static func requestAccess(localizedReason: String, completion: @escaping CompletionResult<LAContext>) {
        let context = LAContext.default

        DispatchQueue.global().async {
            context.evaluatePolicy(authenticationPolicy, localizedReason: localizedReason) { isSuccess, error in
                DispatchQueue.main.async {
                    guard let error = error else {
                        completion(.success(context))
                        return
                    }

                    guard let laError = error as? LAError else {
                        completion(.failure(error.toTangemSdkError()))
                        return
                    }
                    
                    completion(.failure(mapError(error: laError)))
                }
            }
        }
    }

    /// Request access to biometrics
    /// - Parameters:
    ///   - localizedReason:The app-provided reason for requesting authentication, which displays in the authentication dialog presented to the user. Must be non-empty. Only for touchID.
    public static func requestAccess(localizedReason: String) async throws(TangemSdkError) -> LAContext {
        let context = LAContext.default

        do {
            if try await context.evaluatePolicy(authenticationPolicy, localizedReason: localizedReason) {
                return context
            }

            throw TangemSdkError.unknownError
        } catch let error as LAError {
            throw mapError(error: error)
        } catch {
            throw error.toTangemSdkError()
        }
    }

    private static func mapError(error: LAError) -> TangemSdkError {
        switch error.code {
        case .userCancel, .appCancel, .systemCancel, .notInteractive:
            return TangemSdkError.userCancelled
        case .authenticationFailed,
                .biometryDisconnected,
                .biometryNotPaired,
                .companionNotAvailable,
                .invalidContext,
                .invalidDimensions,
                .passcodeNotSet,
                .touchIDLockout,
                .touchIDNotAvailable,
                .touchIDNotEnrolled,
                .userFallback:
            return error.toTangemSdkError()
        @unknown default:
            return TangemSdkError.userCancelled
        }
    }
}
