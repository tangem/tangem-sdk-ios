//
//  PersonalizeCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.06.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Command available on SDK cards only
/// Personalization is an initialization procedure, required before starting using a card.
/// During this procedure a card setting is set up.
/// During this procedure all data exchange is encrypted.
public class PersonalizeCommand: Command {
    public typealias Response = Card
    
    private let config: CardConfig
    private let issuer: Issuer
    private let manufacturer: Manufacturer
    private let acquirer: Acquirer?
    
    private lazy var devPersonalizationKey: Data = {
        return "1234".sha256().prefix(32)
    }()
    
    /// Default initializer
    /// - Parameters:
    ///   - config:  is a configuration file with all the card settings that are written on the card during personalization.
    ///   - issuer: Issuer is a third-party team or company wishing to use Tangem cards.
    ///   - manufacturer: Tangem Card Manufacturer.
    ///   - acquirer: Acquirer is a trusted third-party company that operates proprietary
    ///   (non-EMV) POS terminal infrastructure and transaction processing back-end.
    public init(config: CardConfig, issuer: Issuer, manufacturer: Manufacturer, acquirer: Acquirer? = nil) {
        self.config = config
        self.issuer = issuer
        self.manufacturer = manufacturer
        self.acquirer = acquirer
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if let status = card.status, status != .notPersonalized {
            return .alreadyPersonalized
        }
        
        return nil
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        let encryptionMode = session.environment.encryptionMode
        let encryptionKey = session.environment.encryptionKey
        session.environment.encryptionMode = .none
        session.environment.encryptionKey = devPersonalizationKey
        transieve(in: session) { result in
            session.environment.encryptionMode = encryptionMode
            session.environment.encryptionKey = encryptionKey
            completion(result)
        }
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        return try CommandApdu(.personalize, tlv: serializePersonalizationData(environment: environment, config: config))
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> Card {
        return try CardDeserializer.deserialize(with: environment, from: apdu)
    }
    
    private func serializePersonalizationData(environment: SessionEnvironment, config: CardConfig) throws -> Data {
        guard let cardId = config.createCardId() else {
            throw TangemSdkError.serializeCommandError
        }
        
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: cardId)
            .append(.curveId, value: config.curveID)
            .append(.maxSignatures, value: config.maxSignatures)
            .append(.signingMethod, value: config.signingMethods)
            .append(.settingsMask, value: config.createSettingsMask())
            .append(.pauseBeforePin2, value: config.pauseBeforePin2 / 10)
            .append(.cvc, value: config.cvc.data(using: .utf8))
            .append(.createWalletAtPersonalize, value: config.createWallet)
            .append(.newPin, value: config.pin)
            .append(.newPin2, value: config.pin2)
            .append(.newPin3, value: config.pin3)
            .append(.crExKey, value: config.hexCrExKey)
            .append(.issuerPublicKey, value: issuer.dataKeyPair.publicKey)
            .append(.issuerTransactionPublicKey, value: issuer.transactionKeyPair.publicKey)
            .append(.cardData, value: serializeCardData(environment: environment, cardId: cardId, cardData: config.cardData))
			
        if let walletsCount = config.walletsCount {
            try tlvBuilder.append(.walletsCount, value: walletsCount)
        }
        
        if !config.ndefRecords.isEmpty {
            try tlvBuilder.append(.ndefData, value: serializeNdef(config))
        }
        
        if let acquirer = acquirer {
            try tlvBuilder.append(.acquirerPublicKey, value: acquirer.keyPair.publicKey)
        }

        return tlvBuilder.serialize()
    }
    
    private func serializeNdef(_ config: CardConfig) throws -> Data {
        return try NdefEncoder(ndefRecords: config.ndefRecords,
                               useDynamicNdef: config.useDynamicNDEF)
            .encode()
    }
    
    private func serializeCardData(environment: SessionEnvironment, cardId: String, cardData: CardData) throws -> Data {
        let tlvBuilder = try TlvBuilder()
            .append(.batchId, value: cardData.batchId)
            .append(.productMask, value: cardData.productMask)
            .append(.manufactureDateTime, value: cardData.manufactureDateTime)
            .append(.issuerName, value: issuer.id)
            .append(.blockchainName, value: cardData.blockchainName)
        
        if cardData.tokenSymbol != nil {
            try tlvBuilder
                .append(.tokenSymbol, value: cardData.tokenSymbol)
                .append(.tokenContractAddress, value: cardData.tokenContractAddress)
                .append(.tokenDecimal, value: cardData.tokenDecimal)
        }
        
        if let signature = Secp256k1Utils.sign(Data(hexString: cardId), with: manufacturer.keyPair.privateKey) {
            try tlvBuilder.append(.cardIDManufacturerSignature, value: signature)
        } else {
            throw TangemSdkError.serializeCommandError
        }

        return tlvBuilder.serialize()
    }
}
