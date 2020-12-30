//
//  CheckPinCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.09.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation


struct CheckPinResponse:  ResponseCodable {
    let isPin2Default: Bool
}

@available(iOS 13.0, *)
class CheckPinCommand: Command {
    var requiresPin2: Bool { true }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<CheckPinResponse>) {
        transieve(in: session) { result in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                if case .invalidParams = error {
                    completion(.success(CheckPinResponse(isPin2Default: false)))
                } else {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1.value)
            .append(.pin2, value: environment.pin2.value)
            .append(.cardId, value: environment.card?.cardId)
            .append(.newPin, value: environment.pin1.value )
            .append(.newPin2, value: environment.pin2.value)
        
        if let cvc = environment.cvc {
            try tlvBuilder.append(.cvc, value: cvc)
        }
        
        return CommandApdu(.setPin, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> CheckPinResponse {
        guard let _ = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }

        return CheckPinResponse(isPin2Default: environment.pin2.isDefault)
    }
}
