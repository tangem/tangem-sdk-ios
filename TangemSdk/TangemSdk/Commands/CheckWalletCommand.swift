//
//  CheckWalletCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

struct CheckWalletResponse: TlvMappable {
    let cardId: String
    let salt: Data
    let walletSignature: Data
    
    init(from tlv: [Tlv]) throws {
        let mapper = TlvMapper(tlv: tlv)
        do {
            self.cardId = try mapper.map(.cardId)
            self.salt = try mapper.map(.salt)
            self.walletSignature = try mapper.map(.walletSignature)
        } catch {
            throw error
        }
    }
}

@available(iOS 13.0, *)
final class CheckWalletCommand: CommandSerializer {
    typealias CommandResponse = CheckWalletResponse
    
    let pin1: String
    let cardId: String
    let challenge: Data
    
    
    public init(pin1: String, cardId: String, challenge: Data) {
        self.pin1 = pin1
        self.cardId = cardId
        self.challenge = challenge
    }
    
    func serialize(with environment: CardEnvironment) -> CommandApdu {
        let tlvData = [Tlv(.pin, value: environment.pin1.sha256()),
                       Tlv(.cardId, value: Data(hex: cardId)),
                       Tlv(.challenge, value: challenge)]
        
        let cApdu = CommandApdu(.checkWallet, tlv: tlvData)
        return cApdu
    }
}
