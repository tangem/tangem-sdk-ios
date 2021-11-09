//
//  LinkOriginCardCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

// Response from the Tangem card after `LinkOriginCardCommand`.
@available(iOS 13.0, *)
struct LinkOriginCardResponse {
    /// Unique Tangem card ID number
    let cardId: String
    let backupStatus: Card.BackupRawStatus
}

@available(iOS 13.0, *)
final class LinkOriginCardCommand: Command {
    var requiresPasscode: Bool { return true }
    
    private let originCard: LinkableOriginCard
    private let backupCards: [BackupCard]
    private let attestSignature: Data
    private let accessCode: Data
    private let passcode: Data
    
    init(originCard: LinkableOriginCard, backupCards: [BackupCard], attestSignature: Data, accessCode: Data, passcode: Data) {
        self.originCard = originCard
        self.backupCards = backupCards
        self.attestSignature = attestSignature
        self.accessCode = accessCode
        self.passcode = passcode
    }
    
    deinit {
        Log.debug("LinkOriginCardCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .backupAvailable {
            return .notSupportedFirmwareVersion
        }
        
        if !card.settings.isBackupAllowed {
            return .backupCannotBeCreated
        }
        
        if !card.wallets.isEmpty {
            return .backupCannotBeCreatedNotEmptyWallets
        }
        
        return nil
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<LinkOriginCardResponse>) {
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                session.environment.accessCode = UserCode(.accessCode, value: self.accessCode) 
                session.environment.passcode = UserCode(.passcode, value: self.passcode)  
                
                self.complete(response: response, session: session, completion: completion)
            case .failure(let error):
                switch error {
                case .accessCodeRequired, .passcodeRequired:
                    if let cardId = session.environment.card?.cardId {
                        self.complete(response: LinkOriginCardResponse(cardId: cardId,
                                                                       backupStatus: .cardLinked),
                                      session: session,
                                      completion: completion)
                        return
                    }
                    completion(.failure(error))
                default:
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func complete(response: LinkOriginCardResponse, session: CardSession, completion: @escaping CompletionResult<LinkOriginCardResponse>) {
        session.environment.card?.backupStatus = try? Card.BackupStatus(from: response.backupStatus, cardsCount: self.backupCards.count)
        session.environment.card?.settings.isSettingAccessCodeAllowed = true
        session.environment.card?.settings.isSettingPasscodeAllowed = true
        session.environment.card?.settings.isResettingUserCodesAllowed = false
        completion(.success(response))
    }
    
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.pin, value: environment.accessCode.value)
            .append(.pin2, value: environment.passcode.value)
            .append(.originCardLinkingKey, value: originCard.linkingKey)
            .append(.certificate, value: originCard.certificate)
            .append(.backupAttestSignature, value: attestSignature)
            .append(.newPin, value: accessCode)
            .append(.newPin2, value: passcode)
        
        for (index, card) in backupCards.enumerated() {
            let builder = try TlvBuilder()
                .append(.fileIndex, value: index)
                .append(.backupCardLinkingKey, value: card.linkingKey)
            
            try tlvBuilder.append(.backupCardLink, value: builder.serialize())
        }
        
        return CommandApdu(.linkOriginCard, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> LinkOriginCardResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
      
        let decoder = TlvDecoder(tlv: tlv)

       return LinkOriginCardResponse(cardId: try decoder.decode(.cardId),
                                     backupStatus: try decoder.decode(.backupStatus))
    }
}
