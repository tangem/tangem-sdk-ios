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

        guard CryptoUtils.secureCompare(hmacCalculated, hmacAttestA) else {
            Log.error("Card attest HMAC (hmacAttestA) is invalid!")
            return false
        }

        return true
    }
}

struct AuthorizeWithAccessTokenResponseDTO {
    let challengeWithXor: Data
    let hmacAttestA: Data
}

/// First step of the access token secure channel establishment.
/// Sends an authorize command with `.accessToken` interaction mode.
/// Returns a challenge and HMAC attestation from the card.
class AuthorizeWithAccessTokensCommand: Command {
    typealias Response = AuthorizeWithAccessTokenResponse
    typealias CommandResponse = AuthorizeWithAccessTokenResponseDTO

    var preflightReadMode: PreflightReadMode { .none }
    var cardSessionEncryption: CardSessionEncryption { .none }

    deinit {
        Log.debug("AuthorizeWithAccessTokensCommand deinit")
    }

    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .v8 {
            return TangemSdkError.notSupportedFirmwareVersion
        }

        if card.settings.isBackupRequired, card.backupStatus?.isActive == false {
            return TangemSdkError.walletUnavailableBackupRequired
        }

        return nil
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<AuthorizeWithAccessTokenResponse>) {
        transceive(in: session) { result in
            switch result {
            case .success(let authorizeResponseDTO):
                do {
                    guard let accessTokens = session.environment.cardAccessTokens else {
                        throw TangemSdkError.missingAccessTokens
                    }

                    let challengeA = try authorizeResponseDTO.challengeWithXor.xor(with: accessTokens.identifyToken)
                    let authorizeResponse = AuthorizeWithAccessTokenResponse(
                        challengeA: challengeA,
                        hmacAttestA: authorizeResponseDTO.hmacAttestA
                    )
                    if try authorizeResponse.verify(identifyToken: accessTokens.identifyToken) {
                        completion(.success(authorizeResponse))
                    } else {
                        session.resetAccessTokens()
                        session.secureChannelSession?.reset()
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

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> AuthorizeWithAccessTokenResponseDTO {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        return AuthorizeWithAccessTokenResponseDTO(
            challengeWithXor: try decoder.decode(.challenge),
            hmacAttestA: try decoder.decode(.hmac)
        )
    }
}
