//
//  CreateWalletCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.01.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// This command deletes all wallet data and its private and public keys
public final class PurgeWalletCommand: Command {
    var requiresPasscode: Bool { return true }
    
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
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .appendPinIfNeeded(.pin, value: environment.accessCode, card: environment.card)
            .appendPinIfNeeded(.pin2, value: environment.passcode, card: environment.card)
            .append(.cardId, value: environment.card?.cardId)
            .append(.walletIndex, value: walletIndex)
        
        return CommandApdu(.purgeWallet, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> SuccessResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        return SuccessResponse(cardId: try decoder.decode(.cardId))
    }
}
