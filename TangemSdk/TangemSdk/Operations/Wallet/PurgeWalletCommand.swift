//
//  CreateWalletCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// This command deletes all wallet data and its private and public keys
public final class PurgeWalletCommand: Command {
    var requiresPasscode: Bool { true }

    private let walletIndex: Int

    /// Default initializer
    /// - Parameter walletIndex: Index of the wallet to delete
    public init(walletIndex: Int) {
        self.walletIndex = walletIndex
    }

    deinit {
        Log.debug("PurgeWalletCommand deinit")
    }

    func performPreCheck(_ card: Card) -> TangemSdkError? {
        guard let wallet = card.wallets.first(where: { $0.index == walletIndex }) else {
            return .walletNotFound
        }

        if wallet.settings.isPermanent {
            return .purgeWalletProhibited
        }

        return nil
    }

    public func run(in session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        transceive(in: session) { [walletIndex] result in
            switch result {
            case .success(let response):
                session.environment.card?.wallets.removeAll(where: { $0.index == walletIndex })
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        guard let card = environment.card else {
            throw TangemSdkError.missingPreflightRead
        }

        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.walletIndex, value: walletIndex)

        if shouldAddPin(environment.accessCode, firmwareVersion: card.firmwareVersion) {
            try tlvBuilder.append(.pin, value: environment.accessCode.value)
        }

        if shouldAddPin(environment.passcode, firmwareVersion: card.firmwareVersion) {
            try tlvBuilder.append(.pin2, value: environment.passcode.value)
        }

        if card.firmwareVersion < .v8 {
            try tlvBuilder.append(.cardId, value: environment.card?.cardId)
        }

        return CommandApdu(.purgeWallet, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> SuccessResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        return SuccessResponse(cardId: try decoder.decode(.cardId))
    }
}
