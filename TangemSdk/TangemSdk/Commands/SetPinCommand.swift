//
//  SetPinCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 10.06.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation


/// Deserialized response from the Tangem card after `SetPintCommand`.
public struct SetPinResponse: JSONStringConvertible {
    /// Unique Tangem card ID number
    public let cardId: String
    public let status: SetPinStatus
}

public class SetPinCommand: Command {
    public typealias Response = SetPinResponse
    
    public var requiresPin2: Bool {
        return true
    }
    
    private let pinType: PinCode.PinType
    private var newPin1: Data?
    private var newPin2: Data?
    
    private init(newPin1: Data?, newPin2: Data?, pinType: PinCode.PinType) {
        self.newPin1 = newPin1
        self.newPin2 = newPin2
        self.pinType = pinType
    }
    
    /// Reset pin1 and pin2 to default values
    public convenience init() {
        self.init(newPin1: PinCode.defaultPin1.sha256(), newPin2: PinCode.defaultPin2.sha256(), pinType: .pin1)
    }
    
    /// Change pin
    /// - Parameters:
    ///   - pinType: Pin to change
    ///   - pin: If nil, pin will be requested automatically
    ///   - isExclusive: Reset other pin codes to the default values
    public convenience init(pinType: PinCode.PinType, pin: Data? = nil, isExclusive: Bool = false) {
        switch pinType {
        case .pin1:
            self.init(newPin1: pin,
                      newPin2: isExclusive ? PinCode.defaultPin2.sha256() : nil,
                      pinType: pinType)
        case .pin2:
            self.init(newPin1: isExclusive ? PinCode.defaultPin1.sha256() : nil,
                      newPin2: pin,
                      pinType: pinType)
        }
    }
    
    deinit {
        Log.debug("SetPinCommand deinit")
    }
    
    public func prepare(_ session: CardSession, completion: @escaping CompletionResult<Void>) {
        if newPin1 == nil && newPin2 == nil {
            self.requestNewPin(in: session, completion: completion)
        } else {
            completion(.success(()))
        }
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<SetPinResponse>) {
        if (newPin1 == nil && pinType == .pin1) || (newPin2 == nil && pinType == .pin2) {
            session.pause(error: TangemSdkError.from(pinType: self.pinType, environment: nil))
            DispatchQueue.main.async {
                self.requestNewPin(in: session) { result in
                    switch result {
                    case .success:
                        session.resume()
                        self.transieve(in: session, completion: completion )
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        } else {
            self.transieve(in: session, completion: completion )
        }
    }
    
    private func requestNewPin(in session: CardSession, completion: @escaping CompletionResult<Void>) {
        session.viewDelegate.requestPinChange(pinType: self.pinType, cardId: session.environment.card?.cardId ?? session.cardId) { result in
            switch result {
            case .success(let pinChangeResult):
                let newPinData = pinChangeResult.newPin.sha256()
                switch self.pinType {
                case .pin1:
                    self.newPin1 = newPinData
                case .pin2:
                    self.newPin2 = newPinData
                }
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1.value)
            .append(.pin2, value: environment.pin2.value)
            .append(.cardId, value: environment.card?.cardId)
            .append(.newPin, value: newPin1 ?? environment.pin1.value )
            .append(.newPin2, value: newPin2 ?? environment.pin2.value)
        
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
            throw TangemSdkError.decodingFailed("Failed to parse set pin status")
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        return SetPinResponse(
            cardId: try decoder.decode(.cardId),
            status: status)
    }
}
//todo: remove pin3
public enum SetPinStatus: String, Codable, JSONStringConvertible {
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
