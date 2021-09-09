//
//  StartBackupCardLinkingCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation


@available(iOS 13.0, *)
final class StartBackupCardLinkingCommand: Command {
    var requiresPasscode: Bool { return false }
    
    private let originCardLinkingKey: Data
    
    init(originCardLinkingKey: Data) {
        self.originCardLinkingKey = originCardLinkingKey
    }
    
    deinit {
        Log.debug("StartBackupCardLinkingCommand deinit")
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
    
    func run(in session: CardSession, completion: @escaping CompletionResult<BackupCard>) {
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                do {
                    let prefix = "BACKUP_SLAVE".data(using: .utf8)!
                    let dataAttest = prefix + self.originCardLinkingKey + response.linkingKey
                    let verified = try CryptoUtils.verify(curve: .secp256k1,
                                                          publicKey: response.cardPublicKey,
                                                          message: dataAttest,
                                                          signature: response.attestSignature)
                    if !verified {
                        throw TangemSdkError.invalidLinkingSignature
                    }
                    
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
            .append(.pin, value: environment.accessCode.value)
            .append(.cardId, value: environment.card?.cardId)
            .append(.originCardLinkingKey, value: originCardLinkingKey)
        
        return CommandApdu(.startBackupCardLinking, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> BackupCard {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        guard let cardKey = environment.card?.cardPublicKey else {
            throw TangemSdkError.unknownError
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        
        return BackupCard(cardId: try decoder.decode(.cardId),
                          cardPublicKey: cardKey,
                          linkingKey: try decoder.decode(.backupCardLinkingKey),
                          attestSignature: try decoder.decode(.cardSignature))
    }
}
