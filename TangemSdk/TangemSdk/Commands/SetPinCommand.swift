//
//  SetPinCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 10.06.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation


/// Deserialized response from the Tangem card after `SetPintCommand`.
public struct SetPinResponse: ResponseCodable {
    /// Unique Tangem card ID number
    public let cardId: String
    public let status: SetPinStatus
}

public class SetPinCommand: Command {
    public typealias CommandResponse = SetPinResponse
    
    private let newPin1: Data
    private let newPin2: Data
    private let newPin3: Data?
    
    public init(newPin1: Data, newPin2: Data, newPin3: Data? = nil) {
        self.newPin1 = newPin1
        self.newPin2 = newPin2
        self.newPin3 = newPin3
    }
    
    public convenience init() {
        self.init(newPin1: SessionEnvironment.defaultPin1.sha256(),
                  newPin2: SessionEnvironment.defaultPin2.sha256(),
                  newPin3: nil)
    }
    
    deinit {
        print ("SetPinCommand deinit")
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1)
            .append(.pin2, value: environment.pin2)
            .append(.cardId, value: environment.card?.cardId)
            .append(.newPin, value: newPin1)
            .append(.newPin2, value: newPin2)
        
        if let newPin3 = self.newPin3 {
            try tlvBuilder.append(.newPin3, value: newPin3)
        }
        
        if let cvc = environment.cvc {
            try tlvBuilder.append(.cvc, value: cvc)
        }
        
        return CommandApdu(.setPin, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> SetPinResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        guard let status = SetPinStatus.fromStatusWord(apdu.statusWord) else {
            throw TangemSdkError.decodingFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        return SetPinResponse(
            cardId: try decoder.decode(.cardId),
            status: status)
    }
}

public enum SetPinStatus: String, ResponseCodable {
    case pinsNotChanged
    case pin1Changed
    case pin2Changed
    case pin3Changed
    case pins12Changed
    case pins13Changed
    case pins23Changed
    case pins123Changed
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("\(self)".capitalized)
    }
    
    static func fromStatusWord(_ sw: StatusWord) -> SetPinStatus? {
        switch sw {
        case .pin1Changed: return .pin1Changed
        case .pin2Changed: return .pin2Changed
        case .pin3Changed: return .pin3Changed
        case .pins123Changed: return .pins123Changed
        case .pins12Changed: return .pins12Changed
        case .pins13Changed: return .pins13Changed
        case .pins23Changed: return .pins23Changed
        case .processCompleted: return .pinsNotChanged
        default: return nil
        }
    }
}
