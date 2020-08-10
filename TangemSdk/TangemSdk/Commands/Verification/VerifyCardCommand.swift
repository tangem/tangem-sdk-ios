//
//  VerifyCardCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 07.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation


public enum VerifyCardState: String, Codable {
    case offline
    case online
}


/// Deserialized response from the Tangem card after `VerifyCardResponseCommand`.
public struct VerifyCardResponse: ResponseCodable {
    public let cardId: String
    public let verificationState: VerifyCardState?
    public let artworkInfo: ArtworkInfo?
    
    let salt: Data
    let cardSignature: Data
    
    internal init(cardId: String, salt: Data, cardSignature: Data, verificationState: VerifyCardState? = nil, artworkInfo: ArtworkInfo? = nil) {
        self.cardId = cardId
        self.verificationState = verificationState
        self.artworkInfo = artworkInfo
        self.salt = salt
        self.cardSignature = cardSignature
    }
    
    func verify(publicKey: Data, challenge: Data) -> Bool? {
        return CryptoUtils.vefify(curve: .secp256k1,
                                  publicKey: publicKey,
                                  message: challenge + salt,
                                  signature: cardSignature)
        
    }
}

@available(iOS 13.0, *)
public class VerifyCardCommand: Command {
    public typealias CommandResponse = VerifyCardResponse
    
    let onlineVerification: Bool
    
    private var challenge: Data? = nil
    private let networkService = NetworkService()
    
    public init(onlineVerification: Bool) {
        self.onlineVerification = onlineVerification
        self.challenge = try? CryptoUtils.generateRandomBytes(count: 16)
    }
    
    deinit {
        print("VerifyCardCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if let status = card.status, status == .notPersonalized {
            return .notPersonalized
        }
        
        if card.isActivated{
            return .notActivated
        }
        
        return nil
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<VerifyCardResponse>) {
        guard let cardPublicKey = session.environment.card?.cardPublicKey,
              let cardType = session.environment.card?.cardType else {
            completion(.failure(.cardError))
            return
        }
        
        guard let challenge = self.challenge else {
            completion(.failure(.failedToGenerateRandomSequence))
            return
        }
        
        transieve(in: session) { result in
            switch result {
            case .success(let response):
                guard let verified = response.verify(publicKey: cardPublicKey, challenge: challenge) else {
                    completion(.failure(.cryptoUtilsError))
                    return
                }
                
                if !verified {
                    completion(.failure(.verificationFailed))
                    return
                }
                
                if !self.onlineVerification || cardType != .release {
                    completion(.success(VerifyCardResponse(cardId: response.cardId,
                                                           salt: response.salt,
                                                           cardSignature: response.cardSignature,
                                                           verificationState: VerifyCardState.offline)))

                } else {
                    self.verify(response, cardPublicKey: cardPublicKey, completion: completion)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func verify(_ response: VerifyCardResponse, cardPublicKey: Data, completion: @escaping CompletionResult<VerifyCardResponse>) {
        let requestItem = CardVerifyAndGetInfoRequest.Item(cardId: response.cardId, publicKey: cardPublicKey.asHexString())
        let request = CardVerifyAndGetInfoRequest(requests: [requestItem])
        let endpoint = TangemEndpoint.verifyAndGetInfo(request: request)
        networkService.request(endpoint, responseType: CardVerifyAndGetInfoResponse.self) { result in
            switch result {
            case .success(let networkResponse):
                if let firstResult = networkResponse.results.first, firstResult.passed {
                    completion(.success(VerifyCardResponse(cardId: response.cardId,
                                                                          salt: response.salt,
                                                                          cardSignature: response.cardSignature,
                                                                          verificationState: VerifyCardState.online,
                                                                          artworkInfo: firstResult.artwork)))
                } else {
                    completion(.failure(.verificationFailed))
                }
            case .failure(let networkError):
                print(networkError.localizedDescription)
                completion(.success(VerifyCardResponse(cardId: response.cardId,
                                                       salt: response.salt,
                                                       cardSignature: response.cardSignature,
                                                       verificationState: VerifyCardState.offline)))
            }
        }
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
          let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1.value)
            .append(.cardId, value: environment.card?.cardId)
            .append(.challenge, value: challenge)
        
        return CommandApdu(.verifyCard, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> VerifyCardResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        return VerifyCardResponse(
            cardId: try decoder.decode(.cardId),
            salt: try decoder.decode(.salt),
            cardSignature: try decoder.decode(.cardSignature))
    }
}
