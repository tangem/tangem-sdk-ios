//
//  CardAccessTokens.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 20/02/2026.
//

import Foundation

struct CardAccessTokens: Codable {
    let accessToken: Data
    let identifyToken: Data
}

extension CardAccessTokens {
    init(_ manageAccessTokensResponse: ManageAccessTokensResponse) {
        accessToken = manageAccessTokensResponse.accessToken
        identifyToken = manageAccessTokensResponse.identifyToken
    }
}
