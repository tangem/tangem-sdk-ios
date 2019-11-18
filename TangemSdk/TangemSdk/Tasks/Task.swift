//
//  Task.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

protocol AnyTask {
    
}

/**
* Events that are are sent in callbacks from `Task`.
* `event(TEvent)`:  A callback that is triggered by a `Task`.
* `completion(TaskError? = nil)` A callback that is triggered when a `Task` is completed. `TaskError` is nil if it's a successful completion of a `Task`
*/
public enum TaskEvent<TEvent> {
    case event(TEvent)
    case completion(TaskError? = nil)
}

/**
* An error class that represent typical errors that may occur when performing Tangem SDK tasks.
* Errors are propagated back to the caller in callbacks.
*/
public enum TaskError: Error, LocalizedError {
    //Serialize apdu errors
    case serializeCommandError
    
    //Card errors
    case unknownStatus(sw: UInt16)
    case errorProcessingCommand
    case invalidState
    case insNotSupported
    case invalidParams
    case needEncryption
    
    //Scan errors
    case vefificationFailed
    case cardError
    
    //Sign errors
    case tooMuchHashesInOneTransaction
    case emptyHashes
    case hashSizeMustBeEqual
    
    case busy
    case userCancelled
    case genericError(Error)
    case unsupported
    //NFC error
    case readerError(NFCReaderError)
    
    public var localizedDescription: String {
        switch self {
        case .readerError(let nfcError):
            return nfcError.localizedDescription
        default:
            return "\(self)"
        }
    }
}

/**
* Allows to perform a group of commands interacting between the card and the application.
* A task opens an NFC session, sends commands to the card and receives its responses,
* repeats the commands if needed, and closes session after receiving the last answer.
*/
open class Task<TEvent>: AnyTask {
    var reader: CardReader!
    weak var delegate: CardManagerDelegate?
    
    deinit {
        print("task deinit")
    }
    
    /**
     * This method should be called to run the `Task` and perform all its operations.
     *
     * - Parameter environment: Relevant current version of a card environment
     * - Parameter callback: It will be triggered during the performance of the `Task`
     */
    public final func run(with environment: CardEnvironment, callback: @escaping (TaskEvent<TEvent>) -> Void) {
        guard reader != nil else {
            fatalError("Card reader is nil")
        }
        
        reader.startSession()
        onRun(environment: environment, callback: callback)
    }
    
    /**
     * In this method the individual Tasks' logic should be implemented.
     */
    public func onRun(environment: CardEnvironment, callback: @escaping (TaskEvent<TEvent>) -> Void) {}
    
    /**
     * This method should be called by Tasks in their `onRun` method wherever
     * they need to communicate with the Tangem Card by launching commands.
     */
    public final func sendCommand<T: CommandSerializer>(_ command: T, environment: CardEnvironment, callback: @escaping (Result<T.CommandResponse, TaskError>) -> Void) {
        //TODO: refactor
        let commandApdu = command.serialize(with: environment)
        sendRequest(command, apdu: commandApdu, environment: environment, callback: callback)
    }
    
    private func sendRequest<T: CommandSerializer>(_ command: T, apdu: CommandApdu, environment: CardEnvironment, callback: @escaping (Result<T.CommandResponse, TaskError>) -> Void) {
        reader.send(commandApdu: apdu) { [weak self] commandResponse in
            switch commandResponse {
            case .success(let responseApdu):
                switch responseApdu.statusWord {
                case .needPause:
                    if let securityDelayResponse = command.deserializeSecurityDelay(with: environment, from: responseApdu) {
                        self?.delegate?.showSecurityDelay(remainingMilliseconds: securityDelayResponse.remainingMilliseconds)
                        if securityDelayResponse.saveToFlash {
                             self?.reader.restartPolling()
                        }
                    }
                    self?.sendRequest(command, apdu: apdu, environment: environment, callback: callback)
                case .needEcryption:
                    //TODO: handle needEcryption
                    
                    callback(.failure(TaskError.needEncryption))
                    
                case .invalidParams:
                    //TODO: handle need pin ?
                    
                    callback(.failure(TaskError.invalidParams))
                    
                case .processCompleted, .pin1Changed, .pin2Changed, .pin3Changed:
                    do {
                        let responseData = try command.deserialize(with: environment, from: responseApdu)
                        callback(.success(responseData))
                    } catch {
                        if let taskError = error as? TaskError {
                            callback(.failure(taskError))
                        } else {
                            callback(.failure(TaskError.genericError(error)))
                        }
                    }
                case .errorProcessingCommand:
                    callback(.failure(TaskError.errorProcessingCommand))
                case .invalidState:
                    callback(.failure(TaskError.invalidState))
                    
                case .insNotSupported:
                    callback(.failure(TaskError.insNotSupported))
                case .unknown:
                    callback(.failure(TaskError.unknownStatus(sw: responseApdu.sw)))
                }
            case .failure(let error):
                if error.code == .readerSessionInvalidationErrorUserCanceled {
                    callback(.failure(TaskError.userCancelled))
                } else {
                    callback(.failure(TaskError.readerError(error)))
                }
            }
        }
    }
}
