//
//  ChangePinTasl.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 10.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation


@available(iOS 13.0, *)
public final class ChangePinTask: CardSessionRunnable {
    public typealias CommandResponse = SetPinResponse
    
    private let pinType: PinCode.PinType
    private var pin: Data? = nil
    
    public init(pinType: PinCode.PinType, pin: Data? = nil) {
        self.pinType = pinType
        self.pin = pin
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<SetPinResponse>) {
        if let pin = self.pin {
            runSetPin(session, pin: pin, completion: completion)
        } else {
            session.pause()
            DispatchQueue.main.async {
                session.viewDelegate.requestPinChange(pinType: self.pinType, cardId: session.environment.card?.cardId) { result in
                    switch result {
                    case .success(let pinChangeResult):
                        switch self.pinType {
                        case .pin1:
                            session.environment.pin1 = PinCode(.pin1, value: pinChangeResult.currentPin.sha256())
                        case .pin2:
                            session.environment.pin2 = PinCode(.pin2, value: pinChangeResult.currentPin.sha256())
                        case .pin3:
                            break
                        }
                        self.requestPinsIfNeeded(session, pin: pinChangeResult.newPin.sha256(), completion: completion)
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    private func requestPinsIfNeeded(_ session: CardSession, pin: Data, completion: @escaping CompletionResult<SetPinResponse>) {
        session.requestPin1IfNeeded { pin1RequestResult in
            switch pin1RequestResult {
            case .success:
                session.requestPin2IfNeeded { pin2RequestResult in
                    switch pin2RequestResult {
                    case .success:
                        self.runSetPin(session, pin: pin, completion: completion)
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func runSetPin(_ session: CardSession, pin: Data, completion: @escaping CompletionResult<SetPinResponse>) {
        var newPin1, newPin2: Data
        var newPin3: Data?
        
        switch pinType {
        case .pin1:
            newPin1 = pin
            newPin2 = session.environment.pin2.value!
            newPin3 = nil
        case .pin2:
            newPin1 = session.environment.pin1.value!
            newPin2 = pin
            newPin3 = nil
        case .pin3:
            newPin1 = session.environment.pin1.value!
            newPin2 = session.environment.pin2.value!
            newPin3 = pin
        }
        session.resume()
        let command = SetPinCommand(newPin1: newPin1, newPin2: newPin2, newPin3: newPin3)
        command.run(in: session) { result in
            switch result {
            case .success(let response):
                switch self.pinType {
                case .pin1:
                    session.environment.pin1 = PinCode(.pin1, value: pin)
                case .pin2:
                    session.environment.pin2 = PinCode(.pin2, value: pin)
                case .pin3:
                    session.environment.pin3 = PinCode(.pin3, value: pin)
                }
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
