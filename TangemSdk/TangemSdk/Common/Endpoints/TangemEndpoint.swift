//
//  TangemEndpoint.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 07.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

enum TangemEndpoint: NetworkEndpoint {
    case verifyAndGetInfo(request: CardVerifyAndGetInfoRequest)
    
    private var baseURL: String {
        return "https://verify.tangem.com/"
    }
    
    var url: URL {
        switch self {
        case .verifyAndGetInfo:
            return URL(string: baseURL + "card/verify-and-get-info")!
        }
    }
    
    var method: String {
        return "POST"
    }
    
    var body: Data? {
        switch self {
        case .verifyAndGetInfo(let request):
            return try? JSONEncoder().encode(request)
        }
    }
    
    var headers: [String : String] {
        return [:]
    }
}
