//
//  NFCReader.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CoreNFC
import UIKit

/// Provides NFC communication between an application and Tangem card.
final class NFCReader: NSObject {
    var viewEventsPublisher = CurrentValueSubject<CardReaderViewEvent, Never>(.none)
    private(set) var tag = CurrentValueSubject<NFCTagType, TangemSdkError>(.none)

    var isReady: Bool { isSessionReady }

    /// Session paused indicator for pins UI
    private(set) var isPaused = false
    /// Current connected tag
    private var connectedTag: NFCTag? = nil
    private var isSilentRestartPolling: Bool = false
    /// Active nfc session
    private var readerSession: NFCTagReaderSession?

    /// Session cancellation flag
    @Published private var cancelled: Bool = false

    /// Session invalidation flag
    @Published private var invalidatedWithError: TangemSdkError? = nil

    @Published private var isSessionReady: Bool = false

    /// Session cancellation publisher. Transforms cancellation to error
    private var cancellationPublisher: AnyPublisher<Void, TangemSdkError> {
        $cancelled
            .tryMap { cancelled in
                if cancelled {
                    throw TangemSdkError.userCancelled
                } else {
                    return ()
                }
            }
            .mapError { $0.toTangemSdkError() }
            .eraseToAnyPublisher()
    }

    /// Session restart polling publisher
    private var restartPollingPublisher: CurrentValueSubject<Bool, Never> = .init(false)

    /// Workaround for session timeout error (60 sec)
    private var sessionTimerCancellable: AnyCancellable? = nil

    /// Workaround for tag timeout connection error (20 sec)
    private var tagTimerCancellable: AnyCancellable? = nil

    /// Workaround for nfc stuck
    private var nfcStuckTimerCancellable: AnyCancellable? = nil

    /// Idle timer
    private var idleTimerCancellable: AnyCancellable? = nil

    /// Tag search timer. Sends tagLost event after timeout, if restartPolling called with silent mode
    private var searchTimerCancellable: AnyCancellable? = nil

    /// Keep alert message for restore after pause
    private var _alertMessage: String? = nil

    // Store session live subscriptions
    private var bag = Set<AnyCancellable>()
    private var sessionConnectCancellable: AnyCancellable? = nil

    private var sendRetryCount = Constants.retryCount
    private var startRetryCount = Constants.startRetryCount
    private let pollingOption: NFCTagReaderSession.PollingOption
    private var sessionDidBecomeActiveTS: Date = .init()
    private var firstConnectionTS: Date? = nil
    private var tagConnectionTS: Date? = nil
    private var isBeingStopped = false
    private var stoppedError: TangemSdkError? = nil

    /// Starting from iOS 17 is no longer possible to invoke restart polling after 20 seconds from first connection on some devices
    private lazy var shouldReduceRestartPolling: Bool = {
        if #available(iOS 17, *), NFCUtils.isBrokenRestartPollingDevice {
            return true
        }

        return false
    }()

    private lazy var nfcUtils: NFCUtils = .init()

    init(pollingOption: NFCTagReaderSession.PollingOption = [.iso14443]) {
        self.pollingOption = pollingOption
    }

    deinit {
        Log.debug("Reader deinit")
    }

    private var queue: DispatchQueue = .init(label: "tangem_sdk_reader_queue")
}

// MARK: CardReader

extension NFCReader: CardReader {
    var alertMessage: String {
        get { return _alertMessage ?? "" }
        set {
            if isBeingStopped {
                Log.nfc("Session is being stopped. Skip alert message.")
                return
            }

            readerSession?.alertMessage = newValue
            _alertMessage = newValue
        }
    }

    /// Start session and try to connect with tag
    func startSession(with message: String) {
        Log.nfc("Start NFC session")
        bag = Set<AnyCancellable>()
        isPaused = false
        isSilentRestartPolling = false
        invalidatedWithError = nil
        cancelled = false
        connectedTag = nil
        isBeingStopped = false
        stoppedError = nil
        tagConnectionTS = nil
        firstConnectionTS = nil
        sessionDidBecomeActiveTS = Date()

        _alertMessage = message

        let isExistingSessionActive = readerSession?.isReady ?? false
        if !isExistingSessionActive {
            startNFCStuckTimer()
            start()
        }

        NotificationCenter // For instant cancellation
            .default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: queue)
            .map { _ in return true }
            .filter { [weak self] _ in
                guard let self else { return false }

                let distanceToSessionActive = sessionDidBecomeActiveTS.distance(to: Date())
                if !isSessionReady || distanceToSessionActive < 1 {
                    Log.nfc("Filter out cancelled event")
                    return false
                }
                return true
            }
            .weakAssign(to: \.cancelled, on: self)
            .store(in: &bag)

        $cancelled // speed up cancellation if no tag interaction
            .receive(on: queue)
            .dropFirst()
            .filter { $0 }
            .filter { [weak self] _ in self?.idleTimerCancellable == nil }
            .map { _ in return TangemSdkError.userCancelled }
            .weakAssign(to: \.invalidatedWithError, on: self)
            .store(in: &bag)

        $invalidatedWithError // speed up cancellation if no tag interaction
            .receive(on: queue)
            .dropFirst()
            .compactMap { $0 }
            .filter { [weak self] _ in self?.isSessionReady ?? false }
            .sink { [weak self] error in
                guard let self else { return }

                Log.nfc("Invalidated event received")
                if !isPaused { // skip completion event for paused session.
                    // Actually we need this stuff for immediate cancel(or error) handling only,
                    // before the session detect any tags or if restart polling in action
                    tag.send(completion: .failure(error))
                    tag = .init(.none)
                } else {
                    tagDidDisconnect()
                }

                isSessionReady = false
            }
            .store(in: &bag)

        $isSessionReady // Handle session state
            .receive(on: queue)
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] isReady in
                guard let self else { return }

                Log.nfc("NFC session is active: \(isReady)")
                if isReady {
                    nfcStuckTimerCancellable = nil
                    startSessionTimer()
                } else { // clenup resources
                    stopTimers()
                }

                if !isPaused {
                    viewEventsPublisher.send(isReady ? .sessionStarted : .sessionStopped)
                }
            }
            .store(in: &bag)

        restartPollingPublisher // handle restart polling events
            .receive(on: queue)
            .dropFirst()
            .sink { [weak self] isSilent in
                guard let self, let session = readerSession,
                      session.isReady,
                      !self.isBeingStopped else {
                    return
                }

                if shouldReduceRestartPolling, let firstConnectionTS = firstConnectionTS {
                    let interval = Date().timeIntervalSince(firstConnectionTS)
                    Log.nfc("Restart polling interval is: \(interval)")

                    // 20 is too much because of time inaccuracy
                    if interval >= 16 {
                        Log.nfc("Ignore restart polling")
                        return
                    }
                }

                isSilentRestartPolling = isSilent
                Log.nfc("Restart polling invoked")
                tagDidDisconnect()
                session.restartPolling()

                if isSilent {
                    startSearchTimer()
                }
            }
            .store(in: &bag)
    }

    func resumeSession() {
        Log.nfc("Resume reader session invoked")
        isPaused = false
        startSession(with: _alertMessage ?? "")
    }

    func pauseSession(with errorMessage: String? = nil) {
        Log.nfc("Pause reader session invoked")
        isPaused = true
        stopSession(with: errorMessage)
    }

    func stopSession(with errorMessage: String? = nil) {
        guard readerSession?.isReady == true else {
            return
        }

        if isBeingStopped {
            return
        }

        isBeingStopped = true
        Log.nfc("Stop reader session invoked")
        stopTimers()
        if let errorMessage = errorMessage {
            readerSession?.invalidate(errorMessage: errorMessage)
        } else {
            readerSession?.invalidate()
        }
    }

    func stopSession(with error: Error) {
        stoppedError = error.toTangemSdkError()
        stopSession(with: error.localizedDescription)
    }

    func restartPolling(silent: Bool) {
        restartPollingPublisher.send(silent)
    }

    /// Send apdu command to connected tag
    /// - Parameter apdu: serialized apdu
    /// - Parameter retryOnFail: Should be false for COS v8+ because of secure channel
    /// - Parameter completion: result with ResponseApdu or NFCError otherwise
    func sendPublisher(apdu: CommandApdu, retryOnFail: Bool) -> AnyPublisher<ResponseApdu, TangemSdkError> {
        if isBeingStopped {
            Log.nfc("Session is being stopped. Skip sending.")
            return Empty(completeImmediately: false)
                .setFailureType(to: TangemSdkError.self)
                .eraseToAnyPublisher()
        }

        Log.nfc("Send publisher invoked")

        return Just(())
            .setFailureType(to: TangemSdkError.self)
            .receive(on: queue)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.idleTimerCancellable = nil
            })
            .flatMap { [weak self] _ -> AnyPublisher<ResponseApdu, TangemSdkError> in
                guard let self = self else {
                    return Empty()
                        .setFailureType(to: TangemSdkError.self)
                        .eraseToAnyPublisher()
                }

                guard let connectedTag = connectedTag else {
                    return Empty(completeImmediately: false)
                        .setFailureType(to: TangemSdkError.self)
                        .eraseToAnyPublisher() // wait for tag
                }

                guard case .iso7816(let iso7816tag) = connectedTag else {
                    return Fail(error: TangemSdkError.unsupportedCommand).eraseToAnyPublisher()
                } // [REDACTED_TODO_COMMENT]

                let requestTS = Date()

                return iso7816tag
                    .sendCommandPublisher(cApdu: apdu)
                    .combineLatest(cancellationPublisher)
                    .map { return $0.0 }
                    .receive(on: queue)
                    .tryCatch { [weak self] error -> AnyPublisher<Result<ResponseApdu, TangemSdkError>, TangemSdkError> in
                        guard let self = self else {
                            return Empty(completeImmediately: true)
                                .eraseToAnyPublisher()
                        }

                        if case .userCancelled = error {
                            return Just(.failure(error))
                                .setFailureType(to: TangemSdkError.self)
                                .eraseToAnyPublisher()
                        }

                        guard retryOnFail else {
                            Log.nfc("Got an error, skip retry.")
                            restartPolling(silent: true)
                            return Just(.failure(TangemSdkError.retrySecureChannelNeeded))
                                .setFailureType(to: TangemSdkError.self)
                                .eraseToAnyPublisher()
                        }

                        let distance = requestTS.distance(to: Date())
                        let isDistanceTooLong = distance > Constants.requestToleranceTS
                        if isDistanceTooLong || sendRetryCount <= 0 { // retry to fix old device issues
                            Log.nfc("Invoke restart polling on error")
                            sendRetryCount = Constants.retryCount
                            restartPolling(silent: !isDistanceTooLong) // Use silent mode only if retries are empty
                            return Empty(completeImmediately: false)
                                .eraseToAnyPublisher()
                        } else {
                            sendRetryCount -= 1
                            Log.nfc("Retry send. distance: \(distance)")
                            throw error
                        }
                    }
                    .retry(Constants.retryCount)
                    .handleEvents(receiveOutput: { [weak self] rApdu in
                        guard let self = self else { return }

                        Log.nfc("Response from card received")
                        sendRetryCount = Constants.retryCount
                        startIdleTimer()
                    })
                    .tryMap { try $0.getResponse() }
                    .mapError { $0.toTangemSdkError() }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func start() {
        firstConnectionTS = nil
        readerSession?.invalidate() // Important! We must keep invalidate/begin in balance after start retries
        readerSession = NFCTagReaderSession(pollingOption: pollingOption, delegate: self, queue: queue)!
        readerSession!.alertMessage = _alertMessage!
        readerSession!.begin()
    }

    // MARK: Timers

    private func startNFCStuckTimer() {
        startRetryCount = Constants.startRetryCount
        nfcStuckTimerCancellable = Timer
            .TimerPublisher(interval: Constants.nfcStuckTimeout, runLoop: RunLoop.main, mode: .common)
            .autoconnect()
            .receive(on: queue)
            .sink { [weak self] _ in
                guard let self else { return }

                Log.nfc("Stop by stuck timer")
                startRetryCount -= 1
                if startRetryCount == 0 {
                    tag.send(completion: .failure(.nfcStuck))
                    tag = .init(.none)
                    stopSession()
                } else {
                    start()
                }
            }
    }

    private func startTagTimer() {
        tagTimerCancellable = Timer
            .TimerPublisher(interval: Constants.tagTimeout, tolerance: 0, runLoop: RunLoop.main, mode: .common)
            .autoconnect()
            .receive(on: queue)
            .sink { [weak self] _ in
                guard let self else { return }

                Log.nfc("Stop by tag timer")
                stopSession(with: TangemSdkError.nfcTimeout)
                tagTimerCancellable = nil
            }
    }

    private func startSessionTimer() {
        sessionTimerCancellable = Timer
            .TimerPublisher(interval: Constants.sessionTimeout, runLoop: RunLoop.main, mode: .common)
            .autoconnect()
            .receive(on: queue)
            .sink { [weak self] _ in
                guard let self else { return }

                Log.nfc("Stop by session timer")
                stopSession(with: TangemSdkError.nfcTimeout)
                sessionTimerCancellable = nil
            }
    }

    private func startIdleTimer() {
        idleTimerCancellable = Timer
            .TimerPublisher(interval: Constants.idleTimeout, runLoop: RunLoop.main, mode: .common)
            .autoconnect()
            .receive(on: queue)
            .filter { [weak self] _ in !(self?.isBeingStopped ?? true) }
            .sink { [weak self] _ in
                guard let self else { return }

                Log.nfc("Restart by idle timer")
                restartPolling(silent: true)
                idleTimerCancellable = nil
            }
    }

    private func startSearchTimer() {
        searchTimerCancellable = Timer
            .TimerPublisher(interval: Constants.searchTagTimeout, tolerance: 0, runLoop: RunLoop.main, mode: .common)
            .autoconnect()
            .receive(on: queue)
            .filter { [weak self] _ in self?.connectedTag == nil }
            .sink { [weak self] _ in
                guard let self else { return }

                Log.nfc("Send tag lost view event due timeout")
                isSilentRestartPolling = false
                viewEventsPublisher.send(.tagLost)
                searchTimerCancellable = nil
            }
    }

    private func stopTimers() {
        nfcStuckTimerCancellable = nil
        sessionTimerCancellable = nil
        tagTimerCancellable = nil
        idleTimerCancellable = nil
    }

    private func tagDidDisconnect() {
        Log.nfc("Handle tag lost, cleaning resources: \(String(describing: tag))")

        tag.send(.none)
        connectedTag = nil
        tagTimerCancellable = nil
        idleTimerCancellable = nil
        searchTimerCancellable = nil

        if !isPaused, !isSilentRestartPolling {
            viewEventsPublisher.send(.tagLost)
        }
    }

    private func tagDidConnect(_ nfcTag: NFCTag) {
        connectedTag = nfcTag
        let tagType = nfcTag.tagType

        Log.nfc("Received tag: \(String(describing: tagType))")

        startTagTimer()
        if case .tag = tagType {
            startIdleTimer()
        }

        if isSilentRestartPolling { // reset silent mode
            isSilentRestartPolling = false
        } else if !isPaused {
            viewEventsPublisher.send(.tagConnected)
        }

        tag.send(tagType)
    }
}

// MARK: NFCTagReaderSessionDelegate

extension NFCReader: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        sessionDidBecomeActiveTS = Date()
        isSessionReady = true
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        Log.nfc("NFC Session did invalidate with NFC error: \(error.localizedDescription)")

        if let tagConnectionTS {
            let currentTS = Date()
            let sessionDidBecomeActiveTS = sessionDidBecomeActiveTS
            Log.nfc("Session time is: \(currentTS.timeIntervalSince(sessionDidBecomeActiveTS))")
            Log.nfc("Tag time is: \(currentTS.timeIntervalSince(tagConnectionTS))")
        }

        if nfcStuckTimerCancellable == nil { // handle stuck retries ios14
            invalidatedWithError = stoppedError ?? TangemSdkError.parse(error as! NFCReaderError)
        }

        isBeingStopped = false
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        Log.nfc("NFC tag detected: \(tags)")

        let nfcTag = tags.first!

        sessionConnectCancellable = session.connectPublisher(tag: nfcTag)
            .receive(on: queue)
            .sink { [weak self] completion in
                guard let self else { return }

                switch completion {
                case .failure:
                    restartPolling(silent: false)
                case .finished:
                    break
                }
                sessionConnectCancellable = nil

                tagConnectionTS = Date()

                if firstConnectionTS == nil {
                    firstConnectionTS = tagConnectionTS
                }

            } receiveValue: { [weak self] _ in
                self?.tagDidConnect(nfcTag)
            }
    }
}

// MARK: Constants

extension NFCReader {
    enum Constants {
        static let tagTimeout = 20.0
        static let idleTimeout = 2.0
        static let sessionTimeout = 60.0
        static let nfcStuckTimeout = 1.0
        static let retryCount = 20
        static let startRetryCount = 5
        static let requestToleranceTS = 1.0
        static let searchTagTimeout = 1.0
    }
}
