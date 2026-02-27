//
//  OpenSessionWithAccessTokenCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 20/02/2026.
//

import Foundation

struct OpenSessionWithAccessTokenResponse {
    let accessLevel: AccessLevel
    let signAttestSession: Data

    func verify(accessKey: Data, salt: Data, cardPublicKey: Data) throws -> Bool {
        // Derive session key
        let sessionKey = try accessKey.pbkdf2sha256(
            salt: salt,
            rounds: 10
        )

        let message = Data("SESSION.KEY".utf8) + sessionKey

        // Verify session attestation
        let isValid = try CryptoUtils.verify(
            curve: .secp256k1,
            publicKey: cardPublicKey,
            message: message,
            signature: signAttestSession
        )

       return isValid
    }
}

/// Second step of the access token secure channel establishment.
/// Opens an encrypted session using challenge-response with access tokens.
class OpenSessionWithAccessTokenCommand: Command {
    typealias CommandResponse = OpenSessionWithAccessTokenResponse

    var preflightReadMode: PreflightReadMode { .none }
    var usesEncryption: Bool { false }
    var accessLevel: AccessLevel { .publicAccess }
    
    private let challengeB: Data
    private let hmacAttestB: Data
    private let accessKey: Data
    private let salt: Data

    init(
        challengeB: Data,
        hmacAttestB: Data,
        accessKey: Data,
        salt: Data
    ) {
        self.challengeB = challengeB
        self.hmacAttestB = hmacAttestB
        self.accessKey = accessKey
        self.salt = salt
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<OpenSessionWithAccessTokenResponse>) {
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                do {
                    guard let card = session.environment.card else {
                        throw TangemSdkError.missingPreflightRead
                    }

                    if try response.verify(accessKey: self.accessKey, salt: self.salt, cardPublicKey: card.cardPublicKey) {
                        completion(.success(response))
                    } else {
                        throw TangemSdkError.verificationFailed
                    }
                } catch {
                    completion(.failure(error.toTangemSdkError()))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.challenge, value: challengeB)
            .append(.hmac, value: hmacAttestB)

        return CommandApdu(
            ins: Instruction.openSession.rawValue,
            p2: EncryptionMode.ccmWithAccessToken.byteValue,
            tlv: tlvBuilder.serialize()
        )
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> OpenSessionWithAccessTokenResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        return OpenSessionWithAccessTokenResponse(
            accessLevel: try decoder.decode(.accessLevel),
            signAttestSession: try decoder.decode(.cardSignature)
        )
    }
}
