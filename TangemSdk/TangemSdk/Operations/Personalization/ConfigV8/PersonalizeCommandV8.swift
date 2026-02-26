//
//  PersonalizeCommandV8.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 10/02/2026.
//

import Foundation

/// Command available on SDK cards only
/// Personalization is an initialization procedure, required before starting using a card.
/// During this procedure a card setting is set up.
/// During this procedure all data exchange is encrypted.
/// - Warning: Command available only for cards with COS v8 and higher.
public class PersonalizeCommandV8: Command {
    public var preflightReadMode: PreflightReadMode { .none }

    var requiresPasscode: Bool { false }

    var usesEncryption: Bool { false }

    private let config: CardConfigV8
    private let issuer: Issuer
    private let manufacturer: Manufacturer

    private lazy var devPersonalizationKey: Data = {
        return "1234".getSHA256().prefix(32)
    }()

    /// Default initializer
    /// - Parameters:
    ///   - config:  is a configuration file with all the card settings that are written on the card during personalization.
    ///   - issuer: Issuer is a third-party team or company wishing to use Tangem cards.
    ///   - manufacturer: Tangem Card Manufacturer.
    ///   (non-EMV) POS terminal infrastructure and transaction processing back-end.
    public init(config: CardConfigV8, issuer: Issuer, manufacturer: Manufacturer) {
        self.config = config
        self.issuer = issuer
        self.manufacturer = manufacturer
    }

    public func run(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        let read = PreflightReadTask(readMode: .readCardOnly, filter: nil) //We have to run preflight read ourselves to catch the notPersonalized error
        read.run(in: session) { readResult in
            switch readResult {
            case .success:
                completion(.failure(.alreadyPersonalized))
            case .failure(let error):
                if case .notPersonalized(let firmware) = error {
                    if firmware < .v8 {
                        completion(.failure(TangemSdkError.notSupportedFirmwareVersion))
                        return
                    }

                    self.transceive(in: session, completion: completion)
                } else {
                    completion(.failure(error))
                }
            }
        }
    }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let cApdu = try CommandApdu(.personalize, tlv: serializePersonalizationData(environment: environment, config: config))
        return try encryptApdu(cApdu: cApdu)
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> Card {
        let decryptedApdu = try decryptApdu(rApdu: apdu)
        let decoder = try CardDeserializer.getDecoder(with: environment, from: decryptedApdu)
        let cardDataDecoder = try CardDeserializer.getCardDataDecoder(with: environment, from: decoder.tlv)

        let isAccessCodeSet = config.pin != UserCodeType.accessCode.defaultValue
        return try CardDeserializer(allowNotPersonalized: true)
            .deserialize(isAccessCodeSetLegacy: isAccessCodeSet,
                         decoder: decoder,
                         cardDataDecoder: cardDataDecoder)
    }

//    private func runPersonalize(in session: CardSession, completion: @escaping CompletionResult<Card>) {
//        let encryptionKey = session.environment.encryptionKey
//
//        // override encryption for personalization
//        session.environment.encryptionMode = nil
//        session.environment.encryptionKey = nil
//        transceive(in: session) { result in
//            session.environment.encryptionKey = encryptionKey
//            completion(result)
//        }
//    }

    private func encryptApdu(cApdu: CommandApdu) throws -> CommandApdu {
        let p1: Byte = 0x00
        let nonce =  Data([0x7E] + (0..<ConstantsV8.nonceLength-1).map { UInt8($0) })
        let associatedData = Data([cApdu.cla, cApdu.ins, p1, cApdu.p2])

        let encryptedPayload = try cApdu.data.encryptAESCCM(
            with: devPersonalizationKey,
            iv: nonce,
            additionalAuthenticatedData: associatedData
        )

        let encryptedData = nonce + encryptedPayload

        Log.debug("C-APDU encrypted with CCM")

        return CommandApdu(
            cla: cApdu.cla,
            ins: cApdu.ins,
            p1: p1,
            p2: cApdu.p2,
            le: cApdu.le,
            tlv: encryptedData
        )
    }

    private func decryptApdu(rApdu: ResponseApdu) throws -> ResponseApdu {
        let data = rApdu.data

        // nothing to decrypt
        if data.isEmpty {
            return rApdu
        }

        guard data.count >= ConstantsV8.nonceLength else {
            throw TangemSdkError.invalidResponseApdu
        }

        let nonce = Data(data.prefix(ConstantsV8.nonceLength))
        let payload = Data(data.dropFirst(ConstantsV8.nonceLength))
        let authData = rApdu.swBytes
        let decryptedPayload = try payload.decryptAESCCM(
            with: devPersonalizationKey,
            iv: nonce,
            additionalAuthenticatedData: authData
        )

        let decryptedData = decryptedPayload + authData
        return ResponseApdu(decryptedData, rApdu.sw1, rApdu.sw2)
    }

    private func serializePersonalizationData(environment: SessionEnvironment, config: CardConfigV8) throws -> Data {
        guard let cardId = CardIdBuilder.createCardId(config: config) else {
            throw TangemSdkError.serializeCommandError
        }

        let cardData = config.cardData.createPersonalizationCardData()
        let createWallet: Bool = config.createWallet != 0

        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: cardId)
            .append(.settingsMask, value: CardSettingsMaskBuilderV8.createSettingsMask(config: config))
            .append(.pauseBeforePin2, value: config.securityDelay / 10)
            .append(.createWalletAtPersonalize, value: createWallet)
            .append(.newPin, value: config.pin.getSHA256())
            .append(.issuerPublicKey, value: issuer.dataKeyPair.publicKey)
            .append(.issuerTransactionPublicKey, value: issuer.transactionKeyPair.publicKey)
            .append(.cardData, value: try serializeCardData(cardData: cardData))

        if createWallet {
            try tlvBuilder.append(.curveId, value: config.curveID)
            try tlvBuilder.append(.signingMethod, value: config.signingMethod)
        }

        if let walletsCount = config.walletsCount {
            try tlvBuilder.append(.walletsCount, value: walletsCount)
        }

        if config.useNDEF {
            try tlvBuilder.append(.ndefData, value: serializeNdef(config))
        }

        return tlvBuilder.serialize()
    }

    private func serializeNdef(_ config: CardConfigV8) throws -> Data {
        guard !config.ndefRecords.isEmpty else {
            return Data()
        }

        return try NdefEncoder(
            ndefRecords: config.ndefRecords,
            useDynamicNdef: false
        ).encode()
    }

    private func serializeCardData(cardData: CardData) throws -> Data {
        let tlvBuilder = try TlvBuilder()
            .append(.batchId, value: cardData.batchId)
            .append(.manufactureDateTime, value: cardData.manufactureDateTime)
            .append(.issuerName, value: issuer.id)

        return tlvBuilder.serialize()
    }
}
