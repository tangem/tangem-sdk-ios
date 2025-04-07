//
//  ForcedCTServerTrust.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02/04/2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - ForcedCTURLSessionBuilder

enum ForcedCTURLSessionBuilder {
    static func makeSession(configuration: URLSessionConfiguration = .default) -> URLSession {
        let session = URLSession(configuration: configuration, delegate: ForcedCTURLSessionDelegate(), delegateQueue: nil)
        return session
    }
}

// MARK: - ForcedCTServerTrustEvaluator

enum ForcedCTServerTrustEvaluator {
    static func evaluate(trust: SecTrust) throws {
        guard Config.forcedCT else {
            return
        }

        if let dictionary = SecTrustCopyResult(trust) {
            let qualified = (dictionary as NSDictionary)[kSecTrustCertificateTransparency] as? Bool ?? false
            if !qualified {
                throw NetworkServiceError.ctDisabled
            }
        }
    }

    static func evaluate(challenge: URLAuthenticationChallenge) -> URLSession.AuthChallengeDisposition {
        let protectionSpace = challenge.protectionSpace

        if let serverTrust = protectionSpace.serverTrust, protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            do {
                try evaluate(trust: serverTrust)
            } catch {
                return .cancelAuthenticationChallenge
            }
        }

        return .performDefaultHandling
    }
}

// MARK: - ForcedCTURLSessionDelegate

class ForcedCTURLSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let result = ForcedCTServerTrustEvaluator.evaluate(challenge: challenge)
        completionHandler(result, nil)
    }
}
