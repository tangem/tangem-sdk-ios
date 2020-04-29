//
//  CardSession.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 18.03.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public typealias CompletionResult<T> = (Result<T, SessionError>) -> Void

/// Base protocol for run tasks in a card session
public protocol CardSessionRunnable {
    
    /// Simple interface for responses received after sending commands to Tangem cards.
    associatedtype CommandResponse: TlvCodable
    
    /// The starting point for custom business logic. Adopt this protocol and use `TangemSdk.startSession` to run
    /// - Parameters:
    ///   - session: You can run commands in this session
    ///   - completion: Call the completion handler to complete the task.
    func run(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>)
}

/// Allows interaction with Tangem cards. Should be open before sending commands
public class CardSession {
    /// Allows interaction with users and shows visual elements.
    public let viewDelegate: SessionViewDelegate
    
    /// Contains data relating to the current Tangem card. It is used in constructing all the commands,
    /// and commands can modify `SessionEnvironment`.
    public private(set) var environment: SessionEnvironment
    
    /// True when some operation is still in progress.
    public private(set) var isBusy = false
    
    private let reader: CardReader
    private let semaphore = DispatchSemaphore(value: 1)
    private let initialMessage: String?
    private var cardId: String?
    
    /// Main initializer
    /// - Parameters:
    ///   - environment: Contains data relating to a Tangem card
    ///   - cardId: CID, Unique Tangem card ID number. If not nil, the SDK will check that you tapped the  card with this cardID and will return the `wrongCard` error' otherwise
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - cardReader: NFC-reader implementation
    ///   - viewDelegate: viewDelegate implementation
    public init(environment: SessionEnvironment, cardId: String? = nil, initialMessage: String? = nil, cardReader: CardReader, viewDelegate: SessionViewDelegate) {
        self.reader = cardReader
        self.viewDelegate = viewDelegate
        self.environment = environment
        self.initialMessage = initialMessage
        self.cardId = cardId
    }
    
    deinit {
        print ("Card session deinit")
    }
    
    /// This metod starts a card session, performs preflight `Read` command,  invokes the `run ` method of `CardSessionRunnable` and closes the session.
    /// - Parameters:
    ///   - runnable: The CardSessionRunnable implemetation
    ///   - completion: Completion handler. `(Swift.Result<CardSessionRunnable.CommandResponse, SessionError>) -> Void`
    public func start<T>(with runnable: T, completion: @escaping CompletionResult<T.CommandResponse>) where T : CardSessionRunnable {
        start {session, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            if #available(iOS 13.0, *), (runnable is ReadCommand) { //We already done ReadCommand on iOS 13
                self.handleRunnableCompletion(runnableResult: .success(self.environment.card as! T.CommandResponse), completion: completion)
                return
            }
            
            runnable.run(in: self) {result in
                self.handleRunnableCompletion(runnableResult: result, completion: completion)
            }
        }
    }
    
    /// Starts a card session and performs preflight `Read` command.
    /// - Parameter delegate: Delegate with the card session. Can contain error
    public func start(delegate: @escaping (CardSession, SessionError?) -> Void) {
        do {
            try startSession()
        } catch {
            delegate(self, error as? SessionError)
            return
        }

        if #available(iOS 13.0, *) {
            preflightRead() {result in
                switch result {
                case .success:
                    delegate(self, nil)
                case .failure(let error):
                    delegate(self, error)
                    self.stop(error: error)
                }
            }
        } else {
            delegate(self, nil)
        }
    }
    
    /// Stops the current session with the text message. If nil, the default message will be shown
    /// - Parameter message: The message to show
    public func stop(message: String? = nil) {
        if let message = message {
            viewDelegate.showAlertMessage(message)
        }
        reader.stopSession()
        setBusy(false)
    }
    
    /// Stops the current session with the error message.  Error's `localizedDescription` will be used
    /// - Parameter error: The error to show
    public func stop(error: Error) {
        reader.stopSession(with: error.localizedDescription)
        setBusy(false)
    }
    
    /// Restarts the polling sequence so the reader session can discover new tags.
    public func restartPolling() {
        reader.restartPolling()
    }
    
    /// Sends `CommandApdu` to the current card
    /// - Parameters:
    ///   - apdu: The apdu to send
    ///   - completion: Completion handler. Invoked by nfc-reader
    public final func send(apdu: CommandApdu, completion: @escaping CompletionResult<ResponseApdu>) {
        reader.send(commandApdu: apdu, completion: completion)
    }
    
    private func handleRunnableCompletion<TResponse>(runnableResult: Result<TResponse, SessionError>, completion: @escaping CompletionResult<TResponse>) {
        switch runnableResult {
        case .success(let runnableResponse):
            stop(message: Localization.nfcAlertDefaultDone)
            DispatchQueue.main.async { completion(.success(runnableResponse)) }
        case .failure(let error):
            stop(error: error)
            DispatchQueue.main.async { completion(.failure(error)) }
        }
    }
    
    private func startSession() throws {
        guard TangemSdk.isNFCAvailable else {
            throw SessionError.unsupportedDevice
        }
        
        if isBusy { throw SessionError.busy }
        setBusy(true)
        reader.startSession(with: initialMessage)
    }
    
    private func setBusy(_ isBusy: Bool) {
        semaphore.wait()
        defer { semaphore.signal() }
        self.isBusy = isBusy
    }
    
    @available(iOS 13.0, *)
    private func preflightRead(completion: @escaping CompletionResult<ReadResponse>) {
        let readCommand = ReadCommand()
        readCommand.run(in: self) { readResult in
            switch readResult {
            case .success(let readResponse):
                if let expectedCardId = self.cardId?.uppercased(),
                    let actualCardId = readResponse.cardId?.uppercased(),
                    expectedCardId != actualCardId {
                    let error = SessionError.wrongCard
                    self.stop(error: error)
                    completion(.failure(error))
                    return
                }
                
                self.environment.card = readResponse
                self.cardId = readResponse.cardId
                completion(.success(readResponse))
            case .failure(let error):
                if !self.tryHandleError(error) {
                    self.stop(error: error)
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func tryHandleError(_ error: SessionError) -> Bool {
        switch error {
        case .needEncryption:
             //TODO: handle need encryption
            return false
        default:
            return false
        }
    }
}
