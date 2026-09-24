//
//  CardAccessTokens.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

struct CardAccessTokens: Codable {
    var accessToken: Data
    var identifyToken: Data
}

extension CardAccessTokens {
    init(_ manageAccessTokensResponse: ManageAccessTokensResponse) {
        accessToken = manageAccessTokensResponse.accessToken
        identifyToken = manageAccessTokensResponse.identifyToken
    }

    /// Best-effort wipe. Zeroes in place only if the buffers are uniquely referenced.
    mutating func zeroOut() {
        accessToken.zeroOut()
        identifyToken.zeroOut()
    }
}
