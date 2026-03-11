//
//  CardAccessTokens.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

struct CardAccessTokens: Codable {
    let accessToken: Data
    let identifyToken: Data
}

extension CardAccessTokens {
    init(_ manageAccessTokensResponse: ManageAccessTokensResponse) {
        self.accessToken = manageAccessTokensResponse.accessToken
        self.identifyToken = manageAccessTokensResponse.identifyToken
    }
}
