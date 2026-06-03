//
//  MainTabViewModel.swift
//  TangemSDKExample
//
//  Created by Alexander Osokin on 04.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk
import Combine

@MainActor
class MainTabViewModel: ObservableObject {
    // MARK: - Inputs

    @Published var method: Method = .scan
    @Published var curve: EllipticCurve = .secp256k1
    @Published var mnemonicString: String = ""
    @Published var passphrase: String = ""
    @Published var derivationPath: String = ""
    @Published var signHashesCount: String = "15"
    @Published var attestationMode: AttestationTask.Mode = .normal
    @Published var json: String = ""
    @Published var personalizationConfig: String = ""
    @Published var isUserCodeRecoveryAllowed: Bool = false
    @Published var isPinRequired: Bool = false
    @Published var isNDEFDisabled: Bool = false
    @Published var isDeterministicEntropy: Bool = false

    // MARK: - Outputs

    @Published var logText: String = DebugLogger.logPlaceholder
    @Published var isScanning: Bool = false
    @Published var card: Card?
    @Published var showWalletSelection: Bool = false
    @Published var image: UIImage? = nil

    // MARK: - Config

    @AppStorage("handleErrors") var handleErrors: Bool = true
    @AppStorage("displayLogs") var displayLogs: Bool = false
    @AppStorage("useDevApi") var useDevApi: Bool = false
    @AppStorage("extendedBackup") private var extendedBackup: Bool = false
    @AppStorage("isDevelopmentMode") var isDevelopmentMode: Bool = false
    @AppStorage("accessCodeRequestPolicy") var accessCodeRequestPolicy: AccessCodeRequestPolicy = .default

    private lazy var _tangemSdk: TangemSdk = .init()
    private lazy var logger: DebugLogger = .init()

    var configuredSdk: TangemSdk {
        var config = Config()
        config.linkedTerminal = false
        config.handleErrors = handleErrors
        config.filter.allowedCardTypes = FirmwareVersion.FirmwareType.allCases
        config.accessCodeRequestPolicy = accessCodeRequestPolicy

        var loggers: [TangemSdkLogger] = [ConsoleLogger()]

        if displayLogs {
            loggers.append(logger)
        }

        Config.useDevApi = useDevApi
        Config.extendedBackup = extendedBackup
        Config.isDevelopmentMode = isDevelopmentMode

        config.logConfig = .custom(
            logLevel: [.warning, .error, .command, .debug, .nfc, .session, .apdu, .network, .tlv, .view],
            loggers: loggers
        )

        config.defaultDerivationPaths = [
            .secp256k1: [try! DerivationPath(rawPath: "m/0'/1")],
            .secp256r1: [try! DerivationPath(rawPath: "m/0'/1")],
            .ed25519: [try! DerivationPath(rawPath: "m/0'/1")],
            .ed25519_slip0010: [try! DerivationPath(rawPath: "m/0'/1'")],
            .bip0340: [try! DerivationPath(rawPath: "m/0'/1")],
        ]

        _tangemSdk.config = config
        return _tangemSdk
    }

    private var issuerDataResponse: ReadIssuerDataResponse?
    private var issuerExtraDataResponse: ReadIssuerExtraDataResponse?
    private var savedFiles: [File]?
    private var bag: Set<AnyCancellable> = []

    init() {
        logger
            .logsPublisher
            .debounce(for: 1, scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] logs in
                self?.logText = logs
            }
            .store(in: &bag)

        $method
            .sink { [weak self] newMethod in
                guard let self else { return }

                switch newMethod {
                case .personalize:
                    if personalizationConfig.isEmpty {
                        personalizationConfig = Self.personalizeConfigTemplate
                    }
                case .personalizeV8:
                    if personalizationConfig.isEmpty {
                        personalizationConfig = Self.personalizeConfigTemplateV8
                    }
                default:
                    break
                }
            }
            .store(in: &bag)
    }

    func clear() {
        logText = ""
        logger.clear()
    }

    func copy() {
        UIPasteboard.general.string = logText
    }

    func start(walletIndex: Int? = nil) {
        isScanning = true
        chooseMethod(walletIndex: walletIndex)
    }

    func onAppear() {
        if json.isEmpty {
            json = Self.jsonRpcTemplate
        }
    }

    private func handleCompletion<T>(_ completionResult: Result<T, TangemSdkError>) -> Void {
        switch completionResult {
        case .success(let response):
            complete(with: response)
        case .failure(let error):
            complete(with: error)
        }
    }

    private func complete(with object: Any) {
        logger.log(object)
        isScanning = false
    }

    private func complete(with error: TangemSdkError) {
        if !error.isUserCancelled {
            logger.log("\(error.localizedDescription)")
            logger.log(error)
        }

        isScanning = false
    }

    private func getRandomHash(size: Int = 32) -> Data {
        let array = (0 ..< size).map { _ -> UInt8 in
            UInt8(arc4random_uniform(255))
        }
        return Data(array)
    }

    private func runWithWallet(_ method: (_ walletIndex: Int) -> Void, _ walletIndex: Int?) {
        if let walletIndex {
            method(walletIndex)
            return
        }

        guard let card = card, !card.wallets.isEmpty else {
            complete(with: "Scan card to retrieve wallet")
            return
        }

        if card.wallets.count == 1 {
            method(card.wallets.first!.index)
        } else {
            showWalletSelection.toggle()
        }
    }
}

// MARK: - Editor

extension MainTabViewModel {
    var editorData: String {
        get {
            switch method {
            case .jsonrpc:
                return json
            case .personalize, .personalizeV8:
                return personalizationConfig
            default: return ""
            }
        }

        set {
            switch method {
            case .jsonrpc:
                json = newValue
            case .personalize, .personalizeV8:
                personalizationConfig = newValue
            default: break
            }
        }
    }

    func pasteEditor() {
        switch method {
        case .jsonrpc:
            pasteJson()
        case .personalize, .personalizeV8:
            pastePersonalizationConfig()
        default: break
        }
    }

    func resetPersonalizationConfig() {
        switch method {
        case .personalize:
            personalizationConfig = Self.personalizeConfigTemplate
        case .personalizeV8:
            personalizationConfig = Self.personalizeConfigTemplateV8
        default: break
        }
    }
}

// MARK: - Commands

extension MainTabViewModel {
    func scan() {
        configuredSdk.scanCard(initialMessage: Message(header: "Scan Card", body: "Tap Tangem Card to learn more"), networkService: .init(session: .shared, additionalHeaders: [:])) { result in
            if case .success(let card) = result {
                self.card = card
                self.curve = card.supportedCurves[0]
                self.loadArtworks(for: card)
            }

            self.handleCompletion(result)
        }
    }

    func loadArtworks(for card: Card) {
        let provider = CardArtworksProviderFactory(networkService: .init(session: .shared, additionalHeaders: [:])).makeArtworksProvider(for: card)
        Task {
            let artworks = try await provider.loadArtworks()
            await MainActor.run {
                image = UIImage(data: artworks.large)
                withExtendedLifetime(provider) {}
            }
        }
    }

    func attest() {
        configuredSdk.startSession(with: AttestationTask(mode: attestationMode, networkService: .init(session: .shared, additionalHeaders: [:])), completion: handleCompletion)
    }

    func attestCard() {
        configuredSdk.attestCardKey(attestationMode: .full, completion: handleCompletion)
    }

    func attestWallet(walletIndex: Int) {
        guard let walletPublicKey = card?.wallets.first(where: { $0.index == walletIndex })?.publicKey else {
            complete(with: TangemSdkError.walletUnavailableBackupRequired)
            return
        }

        let path = try? DerivationPath(rawPath: derivationPath)
        if !derivationPath.isEmpty, path == nil {
            complete(with: "Failed to parse hd path")
            return
        }

        UIApplication.shared.endEditing()

        configuredSdk.startSession(with: AttestWalletKeyTask(
            walletPublicKey: walletPublicKey,
            derivationPath: path,
            confirmationMode: .dynamic
        ), completion: handleCompletion)
    }

    func signHash(walletIndex: Int) {
        guard let walletPublicKey = card?.wallets.first(where: { $0.index == walletIndex })?.publicKey else {
            complete(with: TangemSdkError.walletUnavailableBackupRequired)
            return
        }

        let path = try? DerivationPath(rawPath: derivationPath)
        if !derivationPath.isEmpty && path == nil {
            complete(with: "Failed to parse hd path")
            return
        }

        UIApplication.shared.endEditing()

        guard let wallet = card?.wallets[walletPublicKey] else {
            complete(with: "Scan card before")
            return
        }

        let verifyKey = (path.flatMap { wallet.derivedKeys[$0] })?.publicKey ?? walletPublicKey

        let hashSize = wallet.curve == .ed25519 || wallet.curve == .ed25519_slip0010 ? 64 : 32
        let hash = getRandomHash(size: hashSize)

        configuredSdk.sign(
            hash: hash,
            walletPublicKey: walletPublicKey,
            cardId: nil,
            derivationPath: path,
            initialMessage: Message(header: "Signing hash")
        ) { result in

            if case .success(let response) = result {
                let isValid = try? CryptoUtils.verify(curve: wallet.curve, publicKey: verifyKey, hash: hash, signature: response.signature)
                self.logger.log("signature status: \(String(describing: isValid))")
            }

            self.handleCompletion(result)
        }
    }

    func signHashes(walletIndex: Int) {
        guard let walletPublicKey = card?.wallets.first(where: { $0.index == walletIndex })?.publicKey else {
            complete(with: TangemSdkError.walletUnavailableBackupRequired)
            return
        }

        let path = try? DerivationPath(rawPath: derivationPath)
        if !derivationPath.isEmpty, path == nil {
            complete(with: "Failed to parse hd path")
            return
        }

        guard let hashesCount = Int(signHashesCount, radix: 10) else {
            complete(with: "Failed to signed hashes count")
            return
        }

        UIApplication.shared.endEditing()

        let hashes = (0 ..< hashesCount).map { _ -> Data in getRandomHash() }

        configuredSdk.sign(
            hashes: hashes,
            walletPublicKey: walletPublicKey,
            cardId: nil,
            derivationPath: path,
            initialMessage: Message(header: "Signing hashes"),
            completion: handleCompletion
        )
    }

    func derivePublicKey(walletIndex: Int) {
        guard let card = card else {
            complete(with: "Scan card before")
            return
        }

        guard let walletPublicKey = card.wallets.first(where: { $0.index == walletIndex })?.publicKey else {
            complete(with: TangemSdkError.walletUnavailableBackupRequired)
            return
        }

        guard let path = try? DerivationPath(rawPath: derivationPath) else {
            complete(with: "Failed to parse hd path")
            return
        }

        UIApplication.shared.endEditing()

        configuredSdk.deriveWalletPublicKey(
            cardId: card.cardId,
            walletPublicKey: walletPublicKey,
            derivationPath: path,
            completion: handleCompletion
        )
    }

    func createWallet() {
        guard let cardId = card?.cardId else {
            complete(with: "Scan card to retrieve cardId")
            return
        }

        configuredSdk.createWallet(
            curve: curve,
            cardId: cardId,
            completion: handleCompletion
        )
    }

    func importWallet() {
        guard let cardId = card?.cardId else {
            complete(with: "Scan card to retrieve cardId")
            return
        }

        configuredSdk.importWallet(
            curve: curve,
            cardId: cardId,
            mnemonic: mnemonicString,
            passphrase: passphrase,
            completion: handleCompletion
        )
    }

    func createMasterSecret() {
        configuredSdk.startSession(with: CreateMasterSecretCommand(), completion: handleCompletion)
    }

    func importMasterSecret() {
        do {
            let mnemonic = try Mnemonic(with: mnemonicString)
            let factory = AnyMasterKeyFactory(mnemonic: mnemonic, passphrase: passphrase)
            let privateKey = try factory.makeMasterKey(for: .secp256k1)
            let command = CreateMasterSecretCommand(privateKey: privateKey)
            configuredSdk.startSession(with: command, completion: handleCompletion)
        } catch {
            complete(with: error)
        }
    }

    func purgeMasterSecret() {
        configuredSdk.startSession(with: PurgeMasterSecretCommand(), completion: handleCompletion)
    }

    func purgeWallet(walletIndex: Int) {
        guard let cardId = card?.cardId else {
            complete(with: "Scan card to retrieve cardId")
            return
        }

        configuredSdk.purgeWallet(
            walletIndex: walletIndex,
            cardId: cardId,
            completion: handleCompletion
        )
    }

    func chainingExample() {
        configuredSdk.startSession(cardId: nil) { session, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.complete(with: error)
                }
                return
            }

            let scan = ScanTask(networkService: .init(session: .shared, additionalHeaders: [:]))
            scan.run(in: session) { result in
                switch result {
                case .success:
                    session.resume()
                    let secondTaskDelay: TimeInterval = 3
                    DispatchQueue.main.asyncAfter(deadline: .now() + secondTaskDelay) {
                        let createWallet = CreateWalletTask(curve: .secp256k1)
                        createWallet.run(in: session) { result2 in
                            switch result2 {
                            case .success(let response):
                                self.logger.log(response)
                            case .failure:
                                break
                            }

                            DispatchQueue.main.async {
                                self.handleCompletion(result)
                            }

                            session.stop()
                        }
                    }

                case .failure(let error):
                    DispatchQueue.main.async {
                        self.complete(with: error)
                    }
                    session.stop()
                }
            }
        }
    }

    func depersonalize() {
        configuredSdk.startSession(with: DepersonalizeCommand(), completion: handleCompletion)
    }

    func setAccessCode() {
        guard let cardId = card?.cardId else {
            complete(with: "Scan card to retrieve cardId")
            return
        }

        configuredSdk.setAccessCode(
            nil,
            cardId: cardId,
            completion: handleCompletion
        )
    }

    func setPasscode() {
        guard let cardId = card?.cardId else {
            complete(with: "Scan card to retrieve cardId")
            return
        }

        configuredSdk.setPasscode(
            nil,
            cardId: cardId,
            completion: handleCompletion
        )
    }

    func resetUserCodes() {
        guard let cardId = card?.cardId else {
            complete(with: "Scan card to retrieve cardId")
            return
        }

        configuredSdk.resetUserCodes(
            cardId: cardId,
            completion: handleCompletion
        )
    }
}

// MARK: - Files

extension MainTabViewModel {
    func readFiles() {
        configuredSdk.readFiles(
            readPrivateFiles: true,
            fileName: nil,
            walletPublicKey: nil
        ) { result in
            switch result {
            case .success(let files):
                var text = ""
                for file in files {
                    text += file.json + "\n\n"
                    text += "Name: \(String(describing: file.name))" + "\n"
                    text += "File data: \(file.data.hexString)" + "\n\n"

                    if let tlv = Tlv.deserialize(file.data) {
                        let decoder = TlvDecoder(tlv: tlv)
                        let deserializer = WalletDataDeserializer()
                        if let walletData = try? deserializer.deserialize(decoder: decoder) {
                            text += "WalletData: \(walletData.json)" + "\n\n"
                        }
                    }
                }

                if files.isEmpty {
                    text = "No files on the card"
                }
                self.complete(with: text)
            case .failure(let error):
                self.complete(with: error)
            }
        }
    }

    func writeUserFile() {
        let demoPayload = Data(repeating: UInt8(1), count: 10)
        let file: FileToWrite = .byUser(
            data: demoPayload,
            fileName: "User file",
            fileVisibility: .public,
            walletPublicKey: nil
        )

        configuredSdk.writeFiles(files: [file], completion: handleCompletion)
    }

    func writeOwnerFile() {
        guard let cardId = card?.cardId else {
            complete(with: "Scan card to retrieve cardId")
            return
        }

        let filename = "Issuer file"
        let demoPayload = Data(repeating: UInt8(2), count: 10)
        let counter = 1

        let fileHash = try! FileHashHelper.prepareHash(
            for: cardId,
            fileData: demoPayload,
            fileCounter: counter,
            fileName: filename,
            privateKey: Utils.issuer.privateKey
        )
        guard
            let startSignature = fileHash.startingSignature,
            let finalSignature = fileHash.finalizingSignature else {
            complete(with: "Failed to sign data with issuer signature")
            return
        }

        let file: FileToWrite = .byFileOwner(
            data: demoPayload,
            startingSignature: startSignature,
            finalizingSignature: finalSignature,
            counter: counter,
            fileName: filename,
            fileVisibility: .public,
            walletPublicKey: nil
        )

        configuredSdk.writeFiles(files: [file], completion: handleCompletion)
    }

    func deleteFile() {
        configuredSdk.deleteFiles(indices: [0], completion: handleCompletion)
    }

    func updateFilePermissions() {
        var changes: [Int: FileVisibility] = .init()
        changes[0] = .public

        let changeTask = ChangeFileSettingsTask(changes: changes)
        configuredSdk.startSession(with: changeTask, completion: handleCompletion)
    }
}

// MARK: - Deprecated commands

extension MainTabViewModel {
    func readUserData() {
        configuredSdk.readUserData(
            cardId: card?.cardId,
            completion: handleCompletion
        )
    }

    func writeUserData() {
        let userData = Data(hexString: "0102030405060708")

        configuredSdk.writeUserData(
            userData: userData,
            userCounter: 2,
            cardId: card?.cardId,
            completion: handleCompletion
        )
    }

    func writeUserProtectedData() {
        let userData = Data(hexString: "01010101010101")

        configuredSdk.writeUserProtectedData(
            userProtectedData: userData,
            userProtectedCounter: 1,
            cardId: card?.cardId,
            completion: handleCompletion
        )
    }

    func readIssuerData() {
        configuredSdk.readIssuerData(
            cardId: card?.cardId,
            initialMessage: Message(header: "Read issuer data", body: "This is read issuer data request")
        ) { result in
            switch result {
            case .success(let issuerDataResponse):
                self.issuerDataResponse = issuerDataResponse
                self.complete(with: issuerDataResponse)
            case .failure(let error):
                self.complete(with: error)
            }
        }
    }

    func writeIssuerData() {
        guard let cardId = card?.cardId else {
            complete(with: "Scan card to retrieve cardId")
            return
        }

        guard let issuerDataResponse = issuerDataResponse else {
            complete(with: "Please, run ReadIssuerData before")
            return
        }

        let newCounter = (issuerDataResponse.issuerDataCounter ?? 0) + 1
        let sampleData = Data(repeating: UInt8(1), count: 100)
        let sig = try! Secp256k1Utils().sign(Data(hexString: cardId) + sampleData + newCounter.bytes4, with: Utils.issuer.privateKey)

        configuredSdk.writeIssuerData(
            issuerData: sampleData,
            issuerDataSignature: sig,
            issuerDataCounter: newCounter,
            cardId: cardId,
            completion: handleCompletion
        )
    }

    func readIssuerExtraData() {
        configuredSdk.readIssuerExtraData(cardId: card?.cardId) { result in
            switch result {
            case .success(let issuerDataResponse):
                self.issuerExtraDataResponse = issuerDataResponse
                self.complete(with: issuerDataResponse)
                print(issuerDataResponse.issuerData)
            case .failure(let error):
                self.complete(with: error)
            }
        }
    }

    func writeIssuerExtraData() {
        guard let cardId = card?.cardId else {
            complete(with: "Please, scan card before")
            return
        }

        guard let issuerDataResponse = issuerExtraDataResponse else {
            complete(with: "Please, run ReadIssuerExtraData before")
            return
        }
        let newCounter = (issuerDataResponse.issuerDataCounter ?? 0) + 1
        let sampleData = Data(repeating: UInt8(1), count: 2000)
        let issuerKey = Utils.issuer.privateKey
        let secp256k1 = Secp256k1Utils()
        let startSig = try! secp256k1.sign(Data(hexString: cardId) + newCounter.bytes4 + sampleData.count.bytes2, with: issuerKey)
        let finalSig = try! secp256k1.sign(Data(hexString: cardId) + sampleData + newCounter.bytes4, with: issuerKey)

        configuredSdk.writeIssuerExtraData(
            issuerData: sampleData,
            startingSignature: startSig,
            finalizingSignature: finalSig,
            issuerDataCounter: newCounter,
            cardId: cardId,
            completion: handleCompletion
        )
    }

    func resetBackup() {
        configuredSdk.startSession(with: ResetBackupCommand(), completion: handleCompletion)
    }

    func resetToFactory() {
        configuredSdk.startSession(with: ResetToFactorySettingsTask(), completion: handleCompletion)
    }

    func getEntropy() {
        let mode: GetEntropyMode
        if isDeterministicEntropy {
            guard !derivationPath.isEmpty, let path = try? DerivationPath(rawPath: derivationPath) else {
                complete(with: "Failed to parse hd path")
                return
            }

            mode = .deterministic(derivationPath: path)
        } else {
            mode = .random
        }

        UIApplication.shared.endEditing()

        configuredSdk.startSession(
            with: GetEntropyCommand(mode: mode),
            completion: handleCompletion
        )
    }

    func setUserCodeRecoveryAllowed() {
        guard let cardId = card?.cardId else {
            complete(with: "Please, scan card before")
            return
        }

        configuredSdk.setUserCodeRecoveryAllowed(isUserCodeRecoveryAllowed, cardId: cardId, completion: handleCompletion)
    }

    func setPinRequired() {
        let task = SetPinRequiredTask(isRequired: isPinRequired)
        configuredSdk.startSession(with: task, completion: handleCompletion)
    }

    func setNDEFDisabled() {
        let task = SetNDEFDisabledTask(isDisabled: isNDEFDisabled)
        configuredSdk.startSession(with: task, completion: handleCompletion)
    }

    func readMasterSecret() {
        configuredSdk.startSession(with: ReadMasterSecretCommand(), completion: handleCompletion)
    }

    func resetAccessTokens() {
        configuredSdk.startSession(with: ResetAccessTokensTask(), completion: handleCompletion)
    }
}

// MARK: - Json RPC

extension MainTabViewModel {
    func runJsonRpc() {
        UIApplication.shared.endEditing()
        configuredSdk.startSession(with: json) { self.complete(with: $0) }
    }

    private func pasteJson() {
        if let string = UIPasteboard.general.string {
            json = string
        }
    }
}

// MARK: - Personalization

extension MainTabViewModel {
    private func pastePersonalizationConfig() {
        if let string = UIPasteboard.general.string {
            personalizationConfig = string
        }
    }

    func personalize() {
        do {
            guard let configData = personalizationConfig.data(using: .utf8) else {
                throw TangemSdkError.decodingFailed("Failed to convert config to data")
            }

            let config = try JSONDecoder.tangemSdkDecoder.decode(CardConfig.self, from: configData)
            let issuer = try JSONDecoder.tangemSdkDecoder.decode(Issuer.self, from: Self.issuerJson.data(using: .utf8)!)
            let manufacturer = try JSONDecoder.tangemSdkDecoder.decode(Manufacturer.self, from: Self.manufacturerJson.data(using: .utf8)!)
            let personalizeCommand = PersonalizeCommand(
                config: config,
                issuer: issuer,
                manufacturer: manufacturer
            )

            configuredSdk.startSession(with: personalizeCommand, completion: handleCompletion)
        } catch {
            complete(with: error)
        }
    }

    func personalizeV8() {
        do {
            guard let configData = personalizationConfig.data(using: .utf8) else {
                throw TangemSdkError.decodingFailed("Failed to convert config to data")
            }

            let config = try JSONDecoder.tangemSdkDecoder.decode(CardConfigV8.self, from: configData)
            let issuer = try JSONDecoder.tangemSdkDecoder.decode(Issuer.self, from: Self.issuerJson.data(using: .utf8)!)
            let manufacturer = try JSONDecoder.tangemSdkDecoder.decode(Manufacturer.self, from: Self.manufacturerJson.data(using: .utf8)!)
            let personalizeCommand = PersonalizeCommandV8(
                config: config,
                issuer: issuer,
                manufacturer: manufacturer
            )

            configuredSdk.startSession(with: personalizeCommand, completion: handleCompletion)
        } catch {
            complete(with: error)
        }
    }
}

// MARK: - Method Enum

extension MainTabViewModel {
    enum Method: String, CaseIterable {
        case scan
        case signHash
        case signHashes
        case derivePublicKey
        case attest
        case attestCard
        case attestWallet
        case chainingExample
        case setAccessCode
        case setPasscode
        case resetUserCodes
        case createWallet
        case importWallet
        case purgeWallet
        case createMasterSecret
        case importMasterSecret
        case purgeMasterSecret
        // files
        case readFiles
        case writeUserFile
        case writeOwnerFile
        case deleteFile
        case updateFilePermissions
        /// case json-rpc
        case jsonrpc
        // deprecated
        case readIssuerData
        case writeIssuerData
        case readIssuerExtraData
        case writeIssuerExtraData
        case readUserData
        case writeUserData
        case writeUserProtectedData
        // developer
        case depersonalize
        case personalize
        case personalizeV8
        case resetBackup
        case resetToFactory
        case getEntropy
        case setUserCodeRecoveryAllowed
        case setPinRequired
        case setNDEFDisabled
        case readMasterSecret
        case resetAccessTokens
    }

    private func chooseMethod(walletIndex: Int? = nil) {
        switch method {
        case .attest: attest()
        case .attestCard: attestCard()
        case .attestWallet: runWithWallet(attestWallet, walletIndex)
        case .chainingExample: chainingExample()
        case .setAccessCode: setAccessCode()
        case .setPasscode: setPasscode()
        case .resetUserCodes: resetUserCodes()
        case .depersonalize: depersonalize()
        case .scan: scan()
        case .signHash: runWithWallet(signHash, walletIndex)
        case .signHashes: runWithWallet(signHashes, walletIndex)
        case .createWallet: createWallet()
        case .importWallet: importWallet()
        case .purgeWallet: runWithWallet(purgeWallet, walletIndex)
        case .createMasterSecret: createMasterSecret()
        case .importMasterSecret: importMasterSecret()
        case .purgeMasterSecret: purgeMasterSecret()
        case .readFiles: readFiles()
        case .writeUserFile: writeUserFile()
        case .writeOwnerFile: writeOwnerFile()
        case .deleteFile: deleteFile()
        case .updateFilePermissions: updateFilePermissions()
        case .readIssuerData: readIssuerData()
        case .writeIssuerData: writeIssuerData()
        case .readIssuerExtraData: readIssuerExtraData()
        case .writeIssuerExtraData: writeIssuerExtraData()
        case .readUserData: readUserData()
        case .writeUserData: writeUserData()
        case .writeUserProtectedData: writeUserProtectedData()
        case .derivePublicKey: runWithWallet(derivePublicKey, walletIndex)
        case .jsonrpc: runJsonRpc()
        case .personalize: personalize()
        case .personalizeV8: personalizeV8()
        case .resetBackup: resetBackup()
        case .resetToFactory: resetToFactory()
        case .getEntropy: getEntropy()
        case .setUserCodeRecoveryAllowed: setUserCodeRecoveryAllowed()
        case .setPinRequired: setPinRequired()
        case .setNDEFDisabled: setNDEFDisabled()
        case .readMasterSecret: readMasterSecret()
        case .resetAccessTokens: resetAccessTokens()
        }
    }
}
