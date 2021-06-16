//
//  AttestCardKeyCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 07.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

//todo: verify -> attestation
public enum VerifyCardState: String, Codable, JSONStringConvertible {
    case offline
    case online
}

public struct VerifyResponse {
    public let cardId: String
    public let salt: Data
    public let cardSignature: Data
    public let challenge: Data
    public let cardPublicKey: Data
    public let verificationState: VerifyCardState
    public let artworkInfo: ArtworkInfo?
}

extension VerifyResponse {
    internal init(verifyCardResponse: AttestCardKeyResponse, verificationState: VerifyCardState, artworkInfo: ArtworkInfo?) {
        self.cardId = verifyCardResponse.cardId
        self.salt = verifyCardResponse.salt
        self.cardSignature = verifyCardResponse.cardSignature
        self.challenge = verifyCardResponse.challenge
        self.cardPublicKey = verifyCardResponse.cardPublicKey
        self.verificationState = verificationState
        self.artworkInfo = artworkInfo
    }
}

/// Deserialized response from the Tangem card after `AttestCardKeyCommand`.
public struct AttestCardKeyResponse: JSONStringConvertible {
    public let cardId: String
    public let salt: Data
    public let cardSignature: Data
    public let challenge: Data
    public let cardPublicKey: Data //We need it for later online verification
    
    public func verify() -> Bool? {
        return CryptoUtils.verify(curve: .secp256k1,
                                  publicKey: cardPublicKey,
                                  message: challenge + salt,
                                  signature: cardSignature)
        
    }
}

public class AttestCardKeyCommand: Command {
    public typealias Response = AttestCardKeyResponse
    
    private var challenge: Data?

    /// Default initializer
    /// - Parameters:
    ///   - challenge: Optional challenge. If nil, it will be created automatically and returned in command response
    public init(challenge: Data? = nil) {
        self.challenge = challenge
    }
    
    deinit {
        Log.debug("AttestCardKeyCommand deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<AttestCardKeyResponse>) {
        if challenge == nil {
            do {
                challenge = try CryptoUtils.generateRandomBytes(count: 16)
            } catch {
                completion(.failure(error.toTangemSdkError()))
            }
        }
        
        transieve(in: session) { result in
            switch result {
            case .success(let response):
                guard let verified = response.verify() else {
                    completion(.failure(.cryptoUtilsError))
                    return
                }
                
                if !verified {
                    completion(.failure(.cardVerificationFailed))
                    return
                }
                
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1.value)
            .append(.cardId, value: environment.card?.cardId)
            .append(.challenge, value: challenge)
        
        return CommandApdu(.attestCardKey, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> AttestCardKeyResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        guard let cardPublicKey = environment.card?.cardPublicKey else {
            throw TangemSdkError.cardError
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        return AttestCardKeyResponse(
            cardId: try decoder.decode(.cardId),
            salt: try decoder.decode(.salt),
            cardSignature: try decoder.decode(.cardSignature),
            challenge: self.challenge!,
            cardPublicKey: cardPublicKey)
    }
}
