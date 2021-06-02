//
//  CheckPinCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.09.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct CheckPinResponse: JSONStringConvertible {
    public let isPin1Default: Bool
    public let isPin2Default: Bool
}

//todo: use set pin command? or another response from setpin
public struct CheckPinResponseInt: JSONStringConvertible {}

public final class CheckPinCommand: Command {
    public typealias Response = CheckPinResponse
    public var requiresPin2: Bool { true }
    
    public init() {}
    
    deinit {
        Log.debug("CheckPinCommand deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<CheckPinResponse>) {
        transieve(in: session) { result in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                if case .invalidParams = error {
                    completion(.success(CheckPinResponse(isPin1Default: session.environment.pin1.isDefault, isPin2Default: false)))
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

        return CheckPinResponse(isPin1Default: environment.pin1.isDefault, isPin2Default: environment.pin2.isDefault)
    }
}
