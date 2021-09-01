//
//  LinkBackupCardsCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

// Response from the Tangem card after `LinkBackupCardsCommand`.
@available(iOS 13.0, *)
struct LinkBackupCardsResponse {
    /// Unique Tangem card ID number
    let cardId: String
    let attestSignature: Data
}

@available(iOS 13.0, *)
final class LinkBackupCardsCommand: Command {
    var requiresPasscode: Bool { return true }
    
    private let backupCards: [LinkableBackupCard]
    private let accessCode: Data
    private let passcode: Data
    private let originCardLinkingKey: Data //only for verification
    
    init(backupCards: [LinkableBackupCard], accessCode: Data, passcode: Data, originCardLinkingKey: Data) {
        self.backupCards = backupCards
        self.accessCode = accessCode
        self.passcode = passcode
        self.originCardLinkingKey = originCardLinkingKey
    }
    
    deinit {
        Log.debug("LinkBackupCardsCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .backupAvailable {
            return .notSupportedFirmwareVersion
        }
        
        if !card.settings.isBackupAllowed {
            return .backupCannotBeCreated
        }
        
        if card.wallets.isEmpty {
            return .backupCannotBeCreatedEmptyWallets
        }
        
        return nil
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<LinkBackupCardsResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                do {
                    let prefix = "BACKUP".data(using: .utf8)!
                    var dataAttest = prefix + self.backupCards.count.byte
                    dataAttest += self.originCardLinkingKey
                    dataAttest += self.backupCards.map { $0.linkingKey }.joined()
                    dataAttest += self.accessCode
                    dataAttest += self.passcode
                    
                    let verified = try CryptoUtils.verify(curve: .secp256k1,
                                                          publicKey: card.cardPublicKey,
                                                          message: dataAttest,
                                                          signature: response.attestSignature)
                    
                    if !verified {
                        throw TangemSdkError.invalidLinkingSignature
                    }
                    
                    session.environment.card?.backupStatus = .cardLinked(cardsCount: self.backupCards.count)
                    completion(.success(response))
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
            .append(.pin, value: environment.accessCode.value)
            .append(.pin2, value: environment.passcode.value)
            .append(.backupCount, value: backupCards.count)
            .append(.newPin, value: accessCode)
            .append(.newPin2, value: passcode)
        
        for (index, card) in backupCards.enumerated() {
            let builder = try TlvBuilder()
                .append(.fileIndex, value: index)
                .append(.backupCardLinkingKey, value: card.linkingKey)
                .append(.certificate, value: card.certificate)
                .append(.cardSignature, value: card.attestSignature)
            
            try tlvBuilder.append(.backupCardLink, value: builder.serialize())
        }
        
        return CommandApdu(.linkBackupCards, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> LinkBackupCardsResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        
        return LinkBackupCardsResponse(cardId: try decoder.decode(.cardId),
                                       attestSignature: try decoder.decode(.backupAttestSignature))
    }
}
