//
//  BackupService.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 25.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public class BackupService {
    private static let defaultMaxBackupCardsCount = 2
    private static let v8MaxBackupCardsCount = 3

    public private(set) var currentState: State = .preparing

    public var canAddBackupCards: Bool {
        addedBackupCardsCount < maxBackupCardsCount
            && repo.data.primaryCard?.linkingKey != nil
    }

    public var hasIncompletedBackup: Bool {
        switch currentState {
        case .finalizingPrimaryCard, .finalizingBackupCard:
            return true
        default:
            return false
        }
    }

    public var maxBackupCardsCount: Int {
        guard Config.extendedBackup else {
            return Self.defaultMaxBackupCardsCount
        }

        if let firmwareVersion = repo.data.primaryCard?.firmwareVersion,
           firmwareVersion >= .v8 {
            return Self.v8MaxBackupCardsCount
        }

        return Self.defaultMaxBackupCardsCount
    }

    public var config: Config {
        get { sdk.config }
        set { sdk.config = newValue }
    }

    public var addedBackupCardsCount: Int { repo.data.backupCards.count }
    public var canProceed: Bool { currentState != .preparing && currentState != .finished }
    public var accessCodeIsSet: Bool { repo.data.accessCode != nil }
    public var passcodeIsSet: Bool { repo.data.passcode != nil }
    public var primaryCardIsSet: Bool { repo.data.primaryCard != nil }
    public var primaryCard: PrimaryCard? { repo.data.primaryCard }
    public var backupCards: [BackupCard] { repo.data.backupCards }
    /// Perform additional compatibility checks while adding backup cards. Change this setting only if you understand what you do.
    public var skipCompatibilityChecks: Bool = false

    private let sdk: TangemSdk
    private let networkService: NetworkService
    private var repo: BackupRepo = .init()
    private var currentCommand: AnyObject?
    private var handleErrors: Bool { sdk.config.handleErrors }

    public init(
        sdk: TangemSdk,
        networkService: NetworkService
    ) {
        self.sdk = sdk
        self.networkService = networkService
        updateState()
    }

    deinit {
        Log.debug("BackupService deinit")
    }

    public func discardIncompletedBackup() {
        repo.reset()
        updateState()
    }

    public func addBackupCard(completion: @escaping CompletionResult<Card>) {
        guard let primaryCard = repo.data.primaryCard else {
            completion(.failure(.missingPrimaryCard))
            return
        }

        if handleErrors {
            guard addedBackupCardsCount < maxBackupCardsCount else {
                completion(.failure(.tooMuchBackupCards))
                return
            }
        }

        if primaryCard.certificate != nil {
            readBackupCard(primaryCard, completion: completion)
            return
        }

        // Impossible case due to primaryCard compatible Codable implementation with older app versions.
        guard let primaryCardFirmwareVersion = primaryCard.firmwareVersion else {
            completion(.failure(.missingPrimaryCard))
            return
        }

        fetchCertificate(
            cardId: primaryCard.cardId,
            cardPublicKey: primaryCard.cardPublicKey,
            issuerPublicKey: primaryCard.issuer.publicKey,
            firmwareVersion: primaryCardFirmwareVersion
        ) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let certificate):
                var primaryCard = primaryCard
                primaryCard.certificate = certificate
                repo.data.primaryCard = primaryCard
                readBackupCard(primaryCard, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func setAccessCode(_ code: String) throws {
        repo.data.accessCode = nil
        let code = code.trim()

        if handleErrors {
            guard !code.isEmpty else {
                throw TangemSdkError.accessCodeRequired
            }

            if code == UserCodeType.accessCode.defaultValue {
                throw TangemSdkError.accessCodeCannotBeDefault
            }

            if code.count < UserCodeType.minLength {
                throw TangemSdkError.accessCodeTooShort
            }
        }

        guard currentState == .preparing || currentState == .finalizingPrimaryCard else {
            throw TangemSdkError.accessCodeCannotBeChanged
        }

        repo.data.accessCode = code.getSHA256()
        updateState()
    }

    public func setPasscode(_ code: String) throws {
        repo.data.passcode = nil
        let code = code.trim()

        if handleErrors {
            guard !code.isEmpty else {
                throw TangemSdkError.passcodeRequired
            }

            if code == UserCodeType.passcode.defaultValue {
                throw TangemSdkError.passcodeCannotBeDefault
            }

            if code.count < UserCodeType.minLength {
                throw TangemSdkError.passcodeTooShort
            }
        }

        guard currentState == .preparing || currentState == .finalizingPrimaryCard else {
            throw TangemSdkError.passcodeCannotBeChanged
        }

        repo.data.passcode = code.getSHA256()
        updateState()
    }

    public func proceedBackup(completion: @escaping CompletionResult<Card>) {
        switch currentState {
        case .finalizingPrimaryCard:
            handleFinalizePrimaryCard {
                self.handleCompletion($0, completion: completion)
            }
        case .finalizingBackupCard(let index):
            handleWriteBackupCard(index: index) {
                self.handleCompletion($0, completion: completion)
            }
        case .preparing, .finished:
            completion(.failure(TangemSdkError.backupServiceInvalidState))
        }
    }

    public func setPrimaryCard(_ primaryCard: PrimaryCard) {
        repo.data.primaryCard = primaryCard
        updateState()
    }

    public func readPrimaryCard(cardId: String? = nil, completion: @escaping CompletionResult<Void>) {
        var initialMessage: Message?

        if config.productType == .ring {
            initialMessage = Message(
                header: nil,
                body: "backup_finalize_primary_ring_message".localized
            )
        } else {
            let formattedCardId = cardId.flatMap { CardIdFormatter(style: sdk.config.cardIdDisplayFormat).string(from: $0) }

            initialMessage = formattedCardId.map {
                Message(
                    header: nil,
                    body: "backup_prepare_primary_card_message_format".localized($0)
                )
            }
                ?? Message(header: "backup_prepare_primary_card_message".localized)
        }

        let command = StartPrimaryCardLinkingCommand()
        currentCommand = command
        sdk.startSession(
            with: command,
            cardId: cardId,
            initialMessage: initialMessage
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                setPrimaryCard(response)
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
            currentCommand = nil
        }
    }

    private func handleCompletion(_ result: Result<Card, TangemSdkError>, completion: @escaping CompletionResult<Card>) {
        switch result {
        case .success(let card):
            updateState()
            completion(.success(card))
        case .failure(let error):
            completion(.failure(error.toTangemSdkError()))
        }
    }

    @discardableResult
    private func updateState() -> State {
        if repo.data.accessCode == nil
            || repo.data.primaryCard == nil
            || repo.data.backupCards.isEmpty {
            currentState = .preparing
        } else if repo.data.attestSignature == nil
            || repo.data.backupData.count < repo.data.backupCards.count
            || repo.data.primaryCardFinalized == false {
            currentState = .finalizingPrimaryCard
        } else if repo.data.finalizedBackupCardsCount < repo.data.backupCards.count {
            currentState = .finalizingBackupCard(index: repo.data.finalizedBackupCardsCount + 1)
        } else {
            currentState = .finished
            onBackupCompleted()
        }

        return currentState
    }

    private func addBackupCard(_ backupCardResponse: StartBackupCardLinkingTaskResponse, completion: @escaping CompletionResult<Card>) {
        let backupCard = backupCardResponse.backupCard

        if let existingIndex = repo.data.backupCards.firstIndex(where: { $0.cardId == backupCard.cardId }) {
            repo.data.backupCards.remove(at: existingIndex)
        }

        fetchCertificate(
            cardId: backupCard.cardId,
            cardPublicKey: backupCard.cardPublicKey,
            issuerPublicKey: backupCardResponse.card.issuer.publicKey,
            firmwareVersion: backupCardResponse.card.firmwareVersion
        ) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let certificate):
                var backupCard = backupCard
                backupCard.certificate = certificate
                repo.data.backupCards.append(backupCard)
                updateState()
                completion(.success(backupCardResponse.card))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func readBackupCard(_ primaryCard: PrimaryCard, completion: @escaping CompletionResult<Card>) {
        let command = StartBackupCardLinkingTask(
            primaryCard: primaryCard,
            addedBackupCards: repo.data.backupCards.map { $0.cardId },
            networkService: networkService,
            skipCompatibilityChecks: skipCompatibilityChecks
        )
        currentCommand = command

        sdk.startSession(
            with: command,
            filter: nil,
            initialMessage: Message(
                header: nil,
                body: "backup_add_backup_card_message".localized
            )
        ) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let response):
                addBackupCard(response, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
            currentCommand = nil
        }
    }

    private func handleFinalizePrimaryCard(completion: @escaping CompletionResult<Card>) {
        do {
            if handleErrors {
                if repo.data.accessCode == nil, repo.data.passcode == nil {
                    throw TangemSdkError.accessCodeOrPasscodeRequired
                }
            }

            let accessCode = repo.data.accessCode ?? UserCodeType.accessCode.defaultValue.getSHA256()
            let passcode = repo.data.passcode ?? UserCodeType.passcode.defaultValue.getSHA256()

            guard let primaryCard = repo.data.primaryCard else {
                throw TangemSdkError.missingPrimaryCard
            }

            if handleErrors {
                guard !repo.data.backupCards.isEmpty else {
                    throw TangemSdkError.emptyBackupCards
                }

                guard repo.data.backupCards.count <= maxBackupCardsCount else {
                    throw TangemSdkError.tooMuchBackupCards
                }
            }

            let task = FinalizePrimaryCardTask(
                backupCards: repo.data.backupCards,
                accessCode: accessCode,
                passcode: passcode,
                readBackupStartIndex: repo.data.backupData.count,
                attestSignature: repo.data.attestSignature,
                onLink: {
                    self.repo.data.attestSignature = $0
                    self.repo.data.primaryCardFinalized = false
                },
                onRead: {
                    self.repo.data.backupData[$0.0] = $0.1
                    self.repo.data.primaryCardFinalized = false
                },
                onFinalize: {
                    self.repo.data.primaryCardFinalized = true
                }
            )

            var initialMessage: Message?

            if config.productType == .ring {
                initialMessage = Message(
                    header: nil,
                    body: "backup_finalize_primary_ring_message".localized
                )
            } else if let formattedCardId = CardIdFormatter(style: sdk.config.cardIdDisplayFormat).string(from: primaryCard.cardId) {
                initialMessage = Message(
                    header: nil,
                    body: "backup_finalize_primary_card_message_format".localized(formattedCardId)
                )
            }

            currentCommand = task

            sdk.startSession(
                with: task,
                cardId: primaryCard.cardId,
                initialMessage: initialMessage
            ) { [weak self] result in
                completion(result)
                self?.currentCommand = nil
            }

        } catch {
            completion(.failure(error.toTangemSdkError()))
        }
    }

    private func handleWriteBackupCard(index: Int, completion: @escaping CompletionResult<Card>) {
        do {
            if handleErrors {
                if repo.data.accessCode == nil, repo.data.passcode == nil {
                    throw TangemSdkError.accessCodeOrPasscodeRequired
                }
            }

            let accessCode = repo.data.accessCode ?? UserCodeType.accessCode.defaultValue.getSHA256()
            let passcode = repo.data.passcode ?? UserCodeType.passcode.defaultValue.getSHA256()

            guard let attestSignature = repo.data.attestSignature else {
                throw TangemSdkError.missingPrimaryAttestSignature
            }

            guard let primaryCard = repo.data.primaryCard else {
                throw TangemSdkError.missingPrimaryCard
            }

            let cardIndex = index - 1

            guard cardIndex < repo.data.backupCards.count else {
                throw TangemSdkError.noBackupCardForIndex
            }

            if handleErrors {
                guard repo.data.backupCards.count <= maxBackupCardsCount else {
                    throw TangemSdkError.tooMuchBackupCards
                }
            }

            let backupCard = repo.data.backupCards[cardIndex]

            guard let backupData = repo.data.backupData[backupCard.cardId] else {
                throw TangemSdkError.noBackupDataForCard
            }

            
            // For Wallet 3, the default derivations must be performed at the final step of the backup process.
            let performDerivations: Bool = backupCard.firmwareVersion >= .v8 && cardIndex == repo.data.backupCards.count - 1
            
            let command = FinalizeBackupCardTask(
                primaryCard: primaryCard,
                backupCards: repo.data.backupCards,
                backupData: backupData,
                attestSignature: attestSignature,
                accessCode: accessCode,
                passcode: passcode,
                performDerivations: performDerivations
            )

            var initialMessage: Message?

            if config.productType == .ring {
                initialMessage = Message(
                    header: nil,
                    body: "backup_finalize_backup_ring_message".localized
                )
            } else if let formattedCardId = CardIdFormatter(style: sdk.config.cardIdDisplayFormat).string(from: backupCard.cardId) {
                initialMessage = Message(
                    header: nil,
                    body: "backup_finalize_backup_card_message_format".localized(formattedCardId)
                )
            }

            currentCommand = command

            sdk.startSession(
                with: command,
                cardId: backupCard.cardId,
                initialMessage: initialMessage
            ) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success(let card):
                    repo.data.finalizedBackupCardsCount += 1
                    completion(.success(card))
                case .failure(let error):
                    completion(.failure(error))
                }

                currentCommand = nil
            }

        } catch {
            completion(.failure(error.toTangemSdkError()))
        }
    }

    private func onBackupCompleted() {
        repo.reset()
    }

    private func fetchCertificate(
        cardId: String,
        cardPublicKey: Data,
        issuerPublicKey: Data,
        firmwareVersion: FirmwareVersion,
        completion: @escaping CompletionResult<Data>
    ) {
        let factory = BackupCertificateProviderFactory(networkService: networkService)

        let certificateProvider = factory.makeBackupCertificateProvider(
            cardId: cardId,
            cardPublicKey: cardPublicKey,
            issuerPublicKey: issuerPublicKey,
            firmwareVersion: firmwareVersion
        )

        certificateProvider.getCertificate {
            completion($0)
            withExtendedLifetime(certificateProvider) {}
        }
    }
}

// MARK: - State

public extension BackupService {
    enum State: Equatable {
        case preparing
        case finalizingPrimaryCard
        case finalizingBackupCard(index: Int)
        case finished
    }
}

// MARK: - Storage entities

public struct PrimaryCard: Codable {
    public let cardId: String
    public let cardPublicKey: Data
    public let linkingKey: Data

    // For compatibility check with backup card
    public let existingWalletsCount: Int
    public let isHDWalletAllowed: Bool
    public let issuer: Card.Issuer
    public let walletCurves: [EllipticCurve]
    public let batchId: String? // Optional for compatibility with interrupted backups
    public let firmwareVersion: FirmwareVersion? // Optional for compatibility with interrupted backups
    public let isKeysImportAllowed: Bool? // Optional for compatibility with interrupted backups

    var certificate: Data?
}

public struct BackupCard: Codable {
    public let cardId: String
    public let cardPublicKey: Data
    public let firmwareVersion: FirmwareVersion? // Optional for compatibility with interrupted backups
    public let batchId: String? // Optional for compatibility with interrupted backups

    let linkingKey: Data
    let attestSignature: Data

    var certificate: Data?
}

struct EncryptedBackupData: Codable {
    let data: Data
    let salt: Data
}

struct BackupServiceData: Codable {
    var accessCode: Data? = nil
    var passcode: Data? = nil
    var primaryCard: PrimaryCard? = nil
    var attestSignature: Data? = nil
    var backupCards: [BackupCard] = []
    var backupData: [String: [EncryptedBackupData]] = [:]
    var finalizedBackupCardsCount: Int = 0
    var primaryCardFinalized: Bool? = nil

    var shouldSave: Bool {
        attestSignature != nil || !backupData.isEmpty
    }
}

// MARK: - BackupRepo

class BackupRepo {
    private let storage = SecureStorage()
    private var isFetching: Bool = false

    var data: BackupServiceData = .init() {
        didSet {
            do {
                try save()
            } catch {
                Log.error(error)
            }

            Log.debug("BackupRepo updated")
        }
    }

    init() {
        do {
            try fetch()
        } catch {
            Log.error(error)
        }
    }

    func reset() {
        do {
            try storage.delete(.backupData)
        } catch {
            Log.error(error)
        }
        data = .init()
    }

    private func save() throws {
        guard !isFetching, data.shouldSave else { return }

        let encoded = try JSONEncoder().encode(data)
        try storage.store(encoded, forKey: .backupData)
    }

    private func fetch() throws {
        isFetching = true
        defer { self.isFetching = false }

        if let savedData = try storage.get(.backupData) {
            data = try JSONDecoder().decode(BackupServiceData.self, from: savedData)
        }
    }
}
