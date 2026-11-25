//
//  AttestCardFirmwareCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct AttestCardFirmwareResponse: JSONStringConvertible {
    public let cardId: String
    public let hashName: String?
    public let codeHash: Data
    public let challenge: Data

    var isValid: Bool {
        let hashName = hashName?.lowercased() ?? Constants.hashName
        return hashName == Constants.hashName && codeHash.count == Constants.codeHashSize
    }
}

public class AttestCardFirmwareCommand: Command {
    public var preflightReadMode: PreflightReadMode { .readCardOnly }
    var cardSessionEncryption: CardSessionEncryption { .publicSecureChannel }

    private let codePageAddress: Int
    private let codePageCount: Int
    private var challenge: Data?

    public init(
        codePageAddress: Int,
        codePageCount: Int,
        challenge: Data?
    ) {
        self.codePageAddress = codePageAddress
        self.codePageCount = codePageCount
        self.challenge = challenge
    }

    deinit {
        Log.debug("AttestCardFirmwareCommand deinit")
    }

    func performPreCheck(_ card: Card) -> TangemSdkError? {
        guard UInt32(exactly: codePageAddress) != nil, UInt16(exactly: codePageCount) != nil else {
            return TangemSdkError.invalidParams
        }

        if codePageCount == 0, codePageAddress != 0 {
            return TangemSdkError.invalidParams
        }

        return nil
    }

    public func run(in session: CardSession, completion: @escaping CompletionResult<AttestCardFirmwareResponse>) {
        if challenge == nil {
            do {
                challenge = try CryptoUtils.generateRandomBytes(count: Constants.challengeSize)
            } catch {
                completion(.failure(error.toTangemSdkError()))
                return
            }
        }

        transceive(in: session) { result in
            switch result {
            case .success(let response):
                guard response.isValid else {
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
        guard let card = environment.card else {
            throw TangemSdkError.missingPreflightRead
        }

        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.codePageAddress, value: codePageAddress)
            .append(.codePageCount, value: codePageCount)
            .append(.challenge, value: challenge)

        if shouldAddPin(environment.accessCode, firmwareVersion: card.firmwareVersion) {
            try tlvBuilder.append(.pin, value: environment.accessCode.value)
        }

        if card.firmwareVersion < .v8 {
            try tlvBuilder.append(.cardId, value: card.cardId)
            try tlvBuilder.append(.hashName, value: Constants.hashName)
        }

        return CommandApdu(.attestCardFirmware, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> AttestCardFirmwareResponse {
        guard let challenge else {
            throw TangemSdkError.unknownError
        }

        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)

        return AttestCardFirmwareResponse(
            cardId: try decoder.decode(.cardId),
            hashName: try decoder.decode(.hashName),
            codeHash: try decoder.decode(.hash),
            challenge: challenge
        )
    }
}

private enum Constants {
    static let hashName = "sha-256"
    static let codeHashSize = 32
    static let challengeSize = 16
}
