//
//  TangemEndpoint.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 07.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public enum TangemEndpoint: NetworkEndpoint {
    case verifyAndGetInfo(request: CardVerifyAndGetInfoRequest)
    case artwork(cid: String, cardPublicKey: Data, artworkId: String)
    case cardData(cardId: String, cardPublicKey: Data)
    case artworks(cardId: String, cardPublicKey: Data)

    public var baseUrl: String {
        switch self {
        case .cardData, .artworks:
            return Config.useDevApi ? "https://api.tests-d.com/" : "https://api.tangem.org/"
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
        case .artworks:
            return "card/artworks"
        }
    }
    
    public var method: String {
        switch self {
        case .verifyAndGetInfo:
            return "POST"
        case .artwork, .cardData, .artworks:
            return "GET"
        }
    }
    
    public var queryItems: [URLQueryItem]? {
        switch self {
        case .verifyAndGetInfo, .cardData, .artworks:
            return nil
        case .artwork(let cid, let cardPublicKey, let artworkId):
            return [.init(name: "CID", value: cid),
                    .init(name: "publicKey", value: cardPublicKey.hexString),
                    .init(name: "artworkId", value: artworkId)]
        }
    }
    
    public var body: Data? {
        switch self {
        case .verifyAndGetInfo(let request):
            return try? JSONEncoder().encode(request)
        case .artwork, .cardData, .artworks:
            return nil
        }
    }
    
    public var headers: [String : String] {
        var headers = ["Content-Type" : "application/json"]
        
        switch self {
        case .cardData(let cardId, let cardPublicKey),
                .artworks(let cardId, let cardPublicKey):
            headers["card_id"] = cardId
            headers["card_public_key"] = cardPublicKey.hexString
        default:
            break
        }
        
        return headers
    }
}

