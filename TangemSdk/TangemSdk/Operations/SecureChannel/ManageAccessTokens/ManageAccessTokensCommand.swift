//
//  ManageAccessTokensCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

struct ManageAccessTokensResponse {
    let accessToken: Data
    let identifyToken: Data

    var isZeroResponse: Bool {
        accessToken.allSatisfy { $0 == 0 } || identifyToken.allSatisfy { $0 == 0 }
    }
}

enum ManageAccessTokensMode: Byte, InteractionMode {
    case get = 0x00
    case renew = 0x01
    case reset = 0x02
}

/// Manages access tokens on the card: get, renew, or reset.
/// Requires PIN verification (user-level access).
class ManageAccessTokensCommand: Command {
    typealias CommandResponse = ManageAccessTokensResponse

    var cardSessionEncryption: CardSessionEncryption { .secureChannelWithPIN }

    private let mode: ManageAccessTokensMode

    init(mode: ManageAccessTokensMode) {
        self.mode = mode
    }

    deinit {
        Log.debug("ManageAccessTokensCommand deinit")
    }

    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .v8 {
            return TangemSdkError.notSupportedFirmwareVersion
        }

        if card.settings.isBackupRequired, card.backupStatus?.isActive == false {
            return TangemSdkError.noActiveBackup
        }

        return nil
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<ManageAccessTokensResponse>) {
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                self.saveTokens(response, session: session)
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.interactionMode, value: mode)

        return CommandApdu(.manageAccessTokens, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ManageAccessTokensResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        return ManageAccessTokensResponse(
            accessToken: try decoder.decode(.accessToken),
            identifyToken: try decoder.decode(.identifyToken)
        )
    }

    private func saveTokens(_ response: ManageAccessTokensResponse, session: CardSession) {
        if response.isZeroResponse {
            session.resetAccessTokens()
            Log.debug("Access tokens reset successfully")
        } else {
            session.environment.cardAccessTokens = CardAccessTokens(response)
            session.saveAccessTokensIfNeeded()
            Log.debug("Access tokens updated successfully")
        }
    }
}
