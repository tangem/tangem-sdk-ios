//
//  AuthorizeWithAccessTokensCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 20/02/2026.
//

import Foundation

struct AuthorizeWithAccessTokenResponse {
    let challengeA: Data
    let hmacAttestA: Data

    func verify(identifyToken: Data) throws -> Bool {
        let key = try identifyToken.xor(with: challengeA)
        let input = Data("SESSION.CARD".utf8) + challengeA
        let hmacCalculated = key.hmacSHA256(input: input)

        guard hmacCalculated == hmacAttestA else {
            Log.error("Card attest HMAC (hmacAttestA) is invalid!")
            return false
        }

        return true
    }
}

/// First step of the access token secure channel establishment.
/// Sends an authorize command with `.accessToken` interaction mode.
/// Returns a challenge and HMAC attestation from the card.
class AuthorizeWithAccessTokensCommand: Command {
    typealias CommandResponse = AuthorizeWithAccessTokenResponse

    var preflightReadMode: PreflightReadMode { .none }
    var usesEncryption: Bool { false }
    var accessLevel: AccessLevel { .publicAccess }

    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.settings.isBackupRequired, card.backupStatus?.isActive == false {
            return TangemSdkError.walletUnavailableBackupRequired
        }

        return nil
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<AuthorizeWithAccessTokenResponse>) {
        transceive(in: session) { result in
            switch result {
            case .success(let authorizeResponse):
                do {
                    guard let card = session.environment.card else {
                        throw TangemSdkError.missingPreflightRead
                    }

                    guard let accessTokens = session.environment.cardAccessTokens else {
                        throw TangemSdkError.missingAccessTokens
                    }

                    if try authorizeResponse.verify(identifyToken: accessTokens.identifyToken)  {
                        completion(.success(authorizeResponse))
                    } else {
                        try? session.cardAccessTokensRepository?.deleteTokens(for: [card.cardId])
                        throw TangemSdkError.invalidAccessTokens
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
            .append(.cardId, value: environment.card?.cardId )
            .append(.interactionMode, value: AuthorizeMode.accessToken)

        return CommandApdu(.authorize, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> AuthorizeWithAccessTokenResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        return AuthorizeWithAccessTokenResponse(
            challengeA: try decoder.decode(.challenge),
            hmacAttestA: try decoder.decode(.hmac)
        )
    }
}
