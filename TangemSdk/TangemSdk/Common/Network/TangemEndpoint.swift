//
//  TangemEndpoint.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 07.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public enum TangemEndpoint: NetworkEndpoint {
    case verifyAndGetInfo(request: CardVerifyAndGetInfoRequest)
    case artwork(cid: String, cardPublicKey: Data, artworkId: String)
    case cardData(cid: String, cardPublicKey: Data)
    
    public var baseUrl: String {
        switch self {
        case .cardData:
            return "https://api.tangem-tech.com/"
        default:
            return "https://verify.tangem.com/"
        }
    }
    
    public var path: String {
        switch self {
        case .verifyAndGetInfo:
            return "card/verify-and-get-info"
        case .artwork:
            return "card/artwork"
        case .cardData:
            return "card"
        }
    }
    
    public var method: String {
        switch self {
        case .verifyAndGetInfo:
            return "POST"
        case .artwork, .cardData:
            return "GET"
        }
    }
    
    public var queryItems: [URLQueryItem]? {
        switch self {
        case .verifyAndGetInfo:
            return nil
        case .artwork(let cid, let cardPublicKey, let artworkId):
            return [.init(name: "CID", value: cid),
                    .init(name: "publicKey", value: cardPublicKey.hexString),
                    .init(name: "artworkId", value: artworkId)]
        case .cardData(let cid, let cardPublicKey):
            return [.init(name: "card_id", value: cid),
                    .init(name: "card_public_key", value: cardPublicKey.hexString)]
        }
    }
    
    public var body: Data? {
        switch self {
        case .verifyAndGetInfo(let request):
            return try? JSONEncoder().encode(request)
        case .artwork, .cardData:
            return nil
        }
    }
    
    public var headers: [String : String] {
        return ["application/json" : "Content-Type"]
    }
    
    public var configuration: URLSessionConfiguration? {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 30
        return configuration
    }
}

