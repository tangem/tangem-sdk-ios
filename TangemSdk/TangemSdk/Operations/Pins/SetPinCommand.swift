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
    var requiresPin2: Bool { return true }
    
    private var codes: [PinCode.PinType: UserCode] = [:]
    
    /// Change access code only. Passcode will be remain the same
    /// - Parameters:
    ///   - accessCode: User code options
    public init(accessCode: UserCode) {
        codes[.pin1] = accessCode
    }
    
    /// Change  passcode only. Access code will be remain the same
    /// - Parameters:
    ///   - passcode: User code options
    public init(passcode: UserCode) {
        codes[.pin2] = passcode
    }
    
    /// Change  access code and passcode.
    /// - Parameters:
    ///   - accessCode: User code options
    ///   - passcode: User code options
    public init(accessCode: UserCode, passcode: UserCode) {
        codes[.pin1] = accessCode
        codes[.pin2] = passcode
    }
    
    deinit {
        Log.debug("SetPinCommand deinit")
    }
    
    public func prepare(_ session: CardSession, completion: @escaping CompletionResult<Void>) {
        requestIfNeeded(.pin1, in: session) { result  in
            switch result {
            case .success:
                self.requestIfNeeded(.pin2, in: session) { result  in
                    switch result {
                    case .success:
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<SetPinResponse>) {
        if codes.values.contains(where: { $0 == .request }) { //If prepare not called e.g. chaining
            if let error = getPauseError(environment: session.environment) {
                session.pause(error: error)
            } else {
                session.pause()
            }
            
            prepare(session) { result in
                switch result {
                case .success:
                    session.resume()
                    self.transceive(in: session, completion: completion )
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            self.transieve(in: session, completion: completion )
        }
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1.value)
            .append(.pin2, value: environment.pin2.value)
            .append(.cardId, value: environment.card?.cardId)
            .append(.newPin, value: value(for: .pin1) ?? environment.pin1.value)
            .append(.newPin2, value: value(for: .pin2) ?? environment.pin2.value)
        
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
    
    private func getPauseError(environment: SessionEnvironment) -> TangemSdkError? {
        let filtered = codes.filter { $0.value == .request }
        
        guard filtered.count == 1, let type = filtered.first?.key else {
            return nil
        }
        
        return TangemSdkError.from(pinType: type, environment: environment)
    }
    
    private func requestIfNeeded(_ pinType: PinCode.PinType, in session: CardSession, completion: @escaping CompletionResult<Void>) {
        guard codes[pinType] == .request else {
            completion(.success(()))
            return
        }
        
        session.viewDelegate.requestPinChange(pinType: pinType, cardId: session.cardId) { result in
            switch result {
            case .success(let pinChangeResult):
                self.codes[pinType] = .value(pinChangeResult.newPin)
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func value(for type: PinCode.PinType) -> Data? {
        guard let code = codes[type] else {
            return nil
        }
        
        switch code {
        case .none:
            return type.defaultValue
        case .request:
            return nil
        case .value(let stringValue):
            return stringValue.sha256()
        }
    }
}

public enum SetPinStatus: String, Codable, JSONStringConvertible {
    case pinsNotChanged
    case pin1Changed
    case pin2Changed
    case pins12Changed
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("\(self)".capitalized)
    }
    
    static func fromStatusWord(_ sw: StatusWord) -> SetPinStatus? {
        switch sw {
        case .pin1Changed: return .pin1Changed
        case .pin2Changed: return .pin2Changed
        case .pins12Changed: return .pins12Changed
        case .processCompleted: return .pinsNotChanged
        default: return nil
        }
    }
}

public extension SetPinCommand {
    /// - Note:
    /// - `.none` - reset  code
    /// - `.value(String)` -  code to set
    /// - `request` - ask user to input the code
    enum UserCode: Equatable {
        /// Reset  code
        case none
        /// Code to set
        case value(String)
        /// Ask user to input the code
        case request
    }
}
