//
//  CardSession.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 18.03.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CommonCrypto

public typealias CompletionResult<T> = (Result<T, TangemSdkError>) -> Void

/// Base protocol for run tasks in a card session
@available(iOS 13.0, *)
public protocol CardSessionRunnable {    
    var requiresPin2: Bool {get}
    /// Simple interface for responses received after sending commands to Tangem cards.
    associatedtype CommandResponse: ResponseCodable
    
    /// The starting point for custom business logic. Adopt this protocol and use `TangemSdk.startSession` to run
    /// - Parameters:
    ///   - session: You can run commands in this session
    ///   - completion: Call the completion handler to complete the task.
    func run(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>)
}

@available(iOS 13.0, *)
extension CardSessionRunnable {    
    public var requiresPin2: Bool {
        return false
    }
}

@available(iOS 13.0, *)
protocol CardSessionPreparable {
    func prepare(_ session: CardSession, completion: @escaping CompletionResult<Void>)
}

/// Allows interaction with Tangem cards. Should be open before sending commands
@available(iOS 13.0, *)
public class CardSession {
    enum CardSessionState {
        case inactive
        case active
    }
    /// Allows interaction with users and shows visual elements.
    public let viewDelegate: SessionViewDelegate
    
    var state: CardSessionState = .inactive
    /// Contains data relating to the current Tangem card. It is used in constructing all the commands,
    /// and commands can modify `SessionEnvironment`.
    public internal(set) var environment: SessionEnvironment
    public private(set) var connectedTag: NFCTagType? = nil
    
    private let reader: CardReader
    private let initialMessage: Message?
    private let showScanOnboarding: Bool
    private var cardId: String?
    private let storageService: StorageService
    private let environmentService: SessionEnvironmentService
    private var sendSubscription: [AnyCancellable] = []
    private var connectedTagSubscription: [AnyCancellable] = []
    
    private var needPreflightRead = true
    private var pin2Required = false
    
    /// Main initializer
    /// - Parameters:
    ///   - environmentService: Contains data relating to a Tangem card
    ///   - cardId: CID, Unique Tangem card ID number. If not nil, the SDK will check that you tapped the  card with this cardID and will return the `wrongCard` error' otherwise
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - cardReader: NFC-reader implementation
    ///   - viewDelegate: viewDelegate implementation
    public init(environmentService: SessionEnvironmentService, cardId: String? = nil, initialMessage: Message? = nil, showScanOnboarding: Bool, cardReader: CardReader, viewDelegate: SessionViewDelegate, storageService: StorageService) {
        self.reader = cardReader
        self.viewDelegate = viewDelegate
        self.environmentService = environmentService
        self.environment = environmentService.createEnvironment(cardId: cardId)
        self.initialMessage = initialMessage
        self.cardId = cardId
        self.storageService = storageService
        self.showScanOnboarding = showScanOnboarding
    }
    
    deinit {
        print ("Card session deinit")
    }
    
    /// This metod starts a card session, performs preflight `Read` command,  invokes the `run ` method of `CardSessionRunnable` and closes the session.
    /// - Parameters:
    ///   - runnable: The CardSessionRunnable implemetation
    ///   - completion: Completion handler. `(Swift.Result<CardSessionRunnable.CommandResponse, TangemSdkError>) -> Void`
    public func start<T>(with runnable: T, completion: @escaping CompletionResult<T.CommandResponse>) where T : CardSessionRunnable {
        guard TangemSdk.isNFCAvailable else {
            completion(.failure(.unsupportedDevice))
            return
        }
        
        guard state == .inactive && !reader.isReady else {
            completion(.failure(.busy))
            return
        }
        
        prepareSession(for: runnable) { prepareResult in
            switch prepareResult {
            case .success:
                //        requestPinIfNeeded(.pin1) {[weak self] result in
                //            switch result {
                //            case .success:
                //                self?.requestPinIfNeeded(.pin2) {[weak self] result in
                //                    switch result {
                //                    case .success:
                self.start() {[weak self] session, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                        return
                    }
                    
                    runnable.run(in: self) {result in
                        self.handleRunnableCompletion(runnableResult: result, completion: completion)
                    }
                }
                //
                //                    case .failure(let error):
                //                        DispatchQueue.main.async {
                //                            completion(.failure(error))
                //                        }
                //                    }
                //                }
                //
                //            case .failure(let error):
                //                DispatchQueue.main.async {
                //                    completion(.failure(error))
                //                }
                //            }
            //        }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func prepareSession<T: CardSessionRunnable>(for runnable: T, completion: @escaping CompletionResult<Void>) {
        needPreflightRead = (runnable as? PreflightReadCapable)?.needPreflightRead ?? self.needPreflightRead
        pin2Required = runnable.requiresPin2
        
        if let preparable = runnable as? CardSessionPreparable {
            preparable.prepare(self, completion: completion)
        } else {
            completion(.success(()))
        }
    }
    
    /// Starts a card session and performs preflight `Read` command.
    /// - Parameter onSessionStarted: Delegate with the card session. Can contain error
    public func start(_ onSessionStarted: @escaping (CardSession, TangemSdkError?) -> Void) {
        guard TangemSdk.isNFCAvailable else {
            onSessionStarted(self, .unsupportedDevice)
            return
        }
        
        guard state == .inactive && !reader.isReady else {
            onSessionStarted(self, .busy)
            return
        }
        
        state = .active
        viewDelegate.sessionStarted()
        
        reader.tag //Subscription for dispatch tag lost/connected events into viewdelegate
            .dropFirst()
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .removeDuplicates()
            .sink(receiveCompletion: {_ in},
                  receiveValue: {[unowned self] tag in
                    if tag != nil {
                        self.viewDelegate.tagConnected()
                    } else {
                        self.viewDelegate.tagLost()
                    }
            })
            .store(in: &connectedTagSubscription)
        
        reader.tag //Subscription for handle tag lost/connected events
            .dropFirst()
            .sink(receiveCompletion: {_ in},
                  receiveValue: {[unowned self] tag in
                    if tag != nil {
                        self.connectedTag = tag
                    } else {
                        self.connectedTag = nil
                        self.environment.encryptionKey = nil
                    }
            })
            .store(in: &connectedTagSubscription)
        
        reader.tag //Subscription for session initialization and handling any error before session is activated
            .compactMap{ $0 }
            .first()
            .sink(receiveCompletion: { [unowned self] readerCompletion in
                if case let .failure(error) = readerCompletion {
                    self.stop(error: error)
                    onSessionStarted(self, error)
                }}, receiveValue: { [unowned self] tag in
                    self.viewDelegate.sessionStarted()
                    if case .tag = tag, self.needPreflightRead {
                        self.preflightCheck(onSessionStarted)
                    } else {
                        self.viewDelegate.sessionInitialized()
                        onSessionStarted(self, nil)
                    }
            })
            .store(in: &connectedTagSubscription)
        
//        if !storageService.bool(forKey: .hasSuccessfulTapIn) && showScanOnboarding {
//            viewDelegate.showScanUI(session: self) {
//                onSessionStarted(self, TangemSdkError.userCancelled)
//            }
//        } else {
		start()
//        }
    }
    /// Stops the current session with the text message. If nil, the default message will be shown
    /// - Parameter message: The message to show
    public func stop(message: String? = nil) {
        if let message = message {
            viewDelegate.showAlertMessage(message)
        }
        reader.stopSession()
        connectedTagSubscription = []
        sendSubscription = []
        viewDelegate.sessionStopped()
        
        if !storageService.bool(forKey: .hasSuccessfulTapIn) {
            storageService.set(boolValue: true, forKey: .hasSuccessfulTapIn)
        }
        
        environmentService.saveEnvironmentValues(environment, cardId: cardId)
        state = .inactive
    }
    
    /// Stops the current session with the error message.  Error's `localizedDescription` will be used
    /// - Parameter error: The error to show
    public func stop(error: Error) {
        reader.stopSession(with: error.localizedDescription)
        connectedTagSubscription = []
        sendSubscription = []
        viewDelegate.sessionStopped()
        state = .inactive
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
        guard sendSubscription.isEmpty else {
            completion(.failure(.busy))
            return
        }
        
        guard state == .active else {
            completion(.failure(.sessionInactive))
            return
        }
        
        reader.tag
            .compactMap{ $0 }
            .flatMap { _ in self.establishEncryptionIfNeeded() }
            .flatMap { apdu.encryptPublisher(encryptionMode: self.environment.encryptionMode, encryptionKey: self.environment.encryptionKey) }
            .flatMap { self.reader.sendPublisher(apdu: $0) }
            .flatMap { $0.decryptPublisher(encryptionKey: self.environment.encryptionKey) }
            .sink(receiveCompletion: { readerCompletion in
                self.sendSubscription = []
                if case let .failure(error) = readerCompletion {
                    completion(.failure(error))
                }
            }, receiveValue: { responseApdu in
                self.sendSubscription = []
                completion(.success(responseApdu))
            })
            .store(in: &sendSubscription)
    }
    
    /// Perform read slix2 tags
    /// - Parameter completion: Completion handler. Invoked by nfc-reader
    public final func readSlix2Tag(completion: @escaping (Result<ResponseApdu, TangemSdkError>) -> Void)  {
        reader.readSlix2Tag(completion: completion)
    }
    
    func pause(error: TangemSdkError? = nil) {
        environment.encryptionKey = nil
        reader.stopSession(with: error?.localizedDescription)
    }
    
    func resume() {
        reader.resumeSession()
    }
    
    func start() {
        reader.startSession(with: initialMessage?.alertMessage)
    }
    
    private func handleRunnableCompletion<TResponse>(runnableResult: Result<TResponse, TangemSdkError>, completion: @escaping CompletionResult<TResponse>) {
        switch runnableResult {
        case .success(let runnableResponse):
            stop(message: Localization.nfcAlertDefaultDone)
            DispatchQueue.main.async { completion(.success(runnableResponse)) }
        case .failure(let error):
            stop(error: error)
            DispatchQueue.main.async { completion(.failure(error)) }
        }
    }
    
    @available(iOS 13.0, *)
    private func preflightCheck(_ onSessionStarted: @escaping (CardSession, TangemSdkError?) -> Void) {
        ReadCommand().run(in: self) { [weak self] readResult in
            guard let self = self else { return }
            
            switch readResult {
            case .success(let readResponse):
                var wrongCardError: TangemSdkError? = nil
                
                if let expectedCardId = self.cardId?.uppercased(),
                    let actualCardId = readResponse.cardId?.uppercased() {
                    
                    if expectedCardId != actualCardId {
                        wrongCardError = .wrongCardNumber
                    }
                }
                
                if !self.environment.allowedCardTypes.contains(readResponse.cardType) {
                    wrongCardError = .wrongCardType
                }
                
                if let wrongCardError = wrongCardError {
                    self.viewDelegate.wrongCard(message: wrongCardError.localizedDescription)
                    DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                        guard self.reader.isReady else {
                            onSessionStarted(self, .userCancelled)
                            self.stop()
                            return
                        }
                        
                        self.restartPolling()
                        self.preflightCheck(onSessionStarted)
                    }
                    return
                }
                
                self.cardId = readResponse.cardId
                if let cid = self.cardId {
                    self.environment = self.environmentService.updateEnvironment(self.environment, for: cid)
                }
                
                if let nfcReader = self.reader as? NFCReader {
                    if NfcUtils.isPoorNfcQualityDevice,
                       let fw = readResponse.firmwareVersionValue, fw < 2.39,
                       let sd = readResponse.pauseBeforePin2, sd > 500 {
                        nfcReader.oldCardSignCompatibilityMode = true
                    } else {
                        nfcReader.oldCardSignCompatibilityMode = false
                    }
                }
                
                self.viewDelegate.sessionInitialized()
                onSessionStarted(self, nil)
            case .failure(let error):
                onSessionStarted(self, error)
                self.stop(error: error)
            }
        }
    }
    
    private func establishEncryptionIfNeeded() -> AnyPublisher<Void, TangemSdkError> {
        if self.environment.encryptionMode == .none || self.environment.encryptionKey != nil {
            return Just(()).setFailureType(to: TangemSdkError.self).eraseToAnyPublisher()
        }
        
        guard let encryptionHelper = EncryptionHelperFactory.make(for: self.environment.encryptionMode) else {
            return Fail(error: .cryptoUtilsError).eraseToAnyPublisher()
        }
        
        let openSessionCommand = OpenSessionCommand(sessionKeyA: encryptionHelper.keyA)
        let openSesssionApdu = try! openSessionCommand.serialize(with: self.environment)
        
        return reader
            .sendPublisher(apdu: openSesssionApdu)
            .flatMap { responseApdu -> AnyPublisher<Void, TangemSdkError> in
                let response = try! openSessionCommand.deserialize(with: self.environment, from: responseApdu)
                
                var uid: Data
                if let uidFromResponse = response.uid {
                    uid = uidFromResponse
                } else {
                    if case let .tag(tagUid) = self.connectedTag {
                        uid = tagUid
                    } else {
                        return Fail(error: .failedToEstablishEncryption).eraseToAnyPublisher()
                    }
                }
                
                guard let protocolKey = self.environment.pin1.value?.pbkdf2sha256(salt: uid, rounds: 50),
                    let secret = encryptionHelper.generateSecret(keyB: response.sessionKeyB) else {
                        return Fail(error: .cryptoUtilsError).eraseToAnyPublisher()
                }
                
                let sessionKey = (secret + protocolKey).getSha256()
                self.environment.encryptionKey = sessionKey
                return Just(()).setFailureType(to: TangemSdkError.self).eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
    
    func requestPinIfNeeded(_ pinType: PinCode.PinType, _ completion: @escaping CompletionResult<Void>) {
        switch pinType {
        case .pin1:
            guard environment.pin1.value == nil else {
                completion(.success(()))
                return
            }
        case .pin2:
            guard /*pin2Required &&*/ environment.pin2.value == nil else {
                completion(.success(()))
                return
            }
        case .pin3:
            guard environment.pin3.value == nil else {
                completion(.success(()))
                return
            }
        }
        
        viewDelegate.requestPin(pinType: pinType, cardId: self.cardId) {[weak self] pin in
            guard let self = self else { return }
            
            if let pin = pin {
                switch pinType {
                case .pin1:
                    self.environment.pin1 = PinCode(.pin1, stringValue: pin)
                case .pin2:
                    self.environment.pin2 = PinCode(.pin2, stringValue: pin)
                case .pin3:
                    self.environment.pin3 = PinCode(.pin3, stringValue: pin)
                }
                completion(.success(()))
            } else {
                completion(.failure(TangemSdkError.from(pinType: pinType)))
            }
        }
    }
}

//ed25519 from cryptokit?
