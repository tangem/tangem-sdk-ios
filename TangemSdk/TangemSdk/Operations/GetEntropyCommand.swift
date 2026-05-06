//
//  GetEntropyCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 27.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response from the Tangem card after `GetEntropyCommand`.
public struct GetEntropyResponse: JSONStringConvertible {
    /// Unique Tangem card ID number.
    public let cardId: String
    /// Random bytes
    public let data: Data
}

/// Get entropy from the card
public class GetEntropyCommand: Command {
    public var preflightReadMode: PreflightReadMode { .readCardOnly }
    var cardSessionEncryption: CardSessionEncryption { .publicSecureChannel }

    private let mode: GetEntropyMode

    public init(mode: GetEntropyMode = .random) {
        self.mode = mode
    }

    deinit {
        Log.debug("GetEntropyCommand deinit")
    }

    func performPreCheck(_ card: Card) -> TangemSdkError? {
        guard card.firmwareVersion >= .keysImportAvailable else {
            return TangemSdkError.notSupportedFirmwareVersion
        }

        switch mode {
        case .random:
            break
        case .deterministic(let derivationPath):
            if card.firmwareVersion < .v8 {
                return TangemSdkError.notSupportedFirmwareVersion
            }

            if card.settings.isBackupRequired, card.backupStatus?.isActive == false {
                return TangemSdkError.noActiveBackup
            }

            if derivationPath.nodes.contains(where: { !$0.isHardened }) {
                return TangemSdkError.nonHardenedDerivationNotSupported
            }
        }

        return nil
    }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        guard let card = environment.card else {
            throw TangemSdkError.missingPreflightRead
        }

        let tlvBuilder = createTlvBuilder(legacyMode: environment.legacyMode)

        if shouldAddPin(environment.accessCode, firmwareVersion: card.firmwareVersion) {
            try tlvBuilder.append(.pin, value: environment.accessCode.value)
        }

        if card.firmwareVersion < .v8 {
            try tlvBuilder.append(.cardId, value: card.cardId)
        } else {
            try tlvBuilder.append(.interactionMode, value: mode)
            if case .deterministic(let derivationPath) = mode {
                try tlvBuilder.append(.walletHDPath, value: derivationPath)
            }
        }

        return CommandApdu(.getEntropy, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> GetEntropyResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        return GetEntropyResponse(
            cardId: try decoder.decode(.cardId),
            data: try decoder.decode(.data)
        )
    }
}

// MARK: - GetEntropyMode

public enum GetEntropyMode: InteractionMode {
    case random
    case deterministic(derivationPath: DerivationPath)

    public var rawValue: Byte {
        switch self {
        case .random: return 0x00
        case .deterministic: return 0x01
        }
    }
}
