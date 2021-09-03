//
//  Model.swift
//  TangemSDKExample
//
//  Created by Alexander Osokin on 04.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk

class AppModel: ObservableObject {
    //MARK:- Inputs
    @Published var method: Method = .scan
    
    //Wallet creation
    @Published var curve: EllipticCurve = .secp256k1
    //Sign
    @Published var hdPath: String = ""
    //Attestation
    @Published var attestationMode: AttestationTask.Mode = .normal
    //JSON-RPC
    @Published var json: String =  ""
    
    //MARK:-  Outputs
    @Published var logText: String = AppModel.logPlaceholder
    @Published var isScanning: Bool = false
    @Published var card: Card?
    @Published var showWalletSelection: Bool = false
    
    lazy var backupService: BackupService = {
        return BackupService(sdk: tangemSdk)
    }()
    
    lazy var resetPinService: ResetPinService = {
        return ResetPinService(sdk: tangemSdk)
    }()
    
    private lazy var tangemSdk: TangemSdk = {
        var config = Config()
        config.logСonfig = .custom(logLevel: [.apdu, .command, .debug, .error, .nfc, .session, .view, .warning, .tlv])
        config.linkedTerminal = false
        config.allowUntrustedCards = true
        config.filter.allowedCardTypes = FirmwareVersion.FirmwareType.allCases
        return TangemSdk(config: config)
    }()
  
    private var issuerDataResponse: ReadIssuerDataResponse?
    private var issuerExtraDataResponse: ReadIssuerExtraDataResponse?
    private var savedFiles: [File]?
    private static let logPlaceholder = "Logs will appear here"
    
    func clear() {
        logText = ""
    }
    
    func copy() {
        UIPasteboard.general.string = logText
    }
    
    func start(walletPublicKey: Data? = nil) {
        isScanning = true
        chooseMethod(walletPublicKey: walletPublicKey)
    }
    
    private func handleCompletion<T>(_ completionResult: Result<T, TangemSdkError>) -> Void {
        switch completionResult {
        case .success(let response):
            self.complete(with: response)
        case .failure(let error):
            self.complete(with: error)
        }
    }
    
    private func log(_ object: Any) {
        let text: String = (object as? JSONStringConvertible)?.json ?? "\(object)"
        if logText == AppModel.logPlaceholder {
            logText = ""
        }
        logText = "\(text)\n\n" + logText
    }
    
    private func complete(with object: Any) {
        log(object)
        isScanning = false
    }
    
    private func complete(with error: TangemSdkError) {
        if !error.isUserCancelled {
            self.log("\(error.localizedDescription)")
        }
        
        isScanning = false
    }
    
    private func getRandomHash(size: Int = 32) -> Data {
        let array = (0..<size).map{ _ -> UInt8 in
            UInt8(arc4random_uniform(255))
        }
        return Data(array)
    }
    
    private func runWithPublicKey(_ method: (_ walletPublicKey: Data) -> Void, _ walletPublicKey: Data?) {
        if let publicKey = walletPublicKey {
            method(publicKey)
            return
        }
        
        guard let card = card, !card.wallets.isEmpty else {
            self.complete(with: "Scan card to retrieve wallet")
            return
        }
        
        if card.wallets.count == 1 {
            method(card.wallets.first!.publicKey)
        } else {
            showWalletSelection.toggle()
        }
    }
}

// MARK:- Commands
extension AppModel {
    func scan() {
        tangemSdk.scanCard(initialMessage: Message(header: "Scan Card", body: "Tap Tangem Card to learn more")) { result in
            if case let .success(card) = result {
                self.card = card
                self.curve = card.supportedCurves[0]
            }
            
            self.handleCompletion(result)
        }
    }
    
    func attest() {
        tangemSdk.startSession(with: AttestationTask(mode: attestationMode), completion: handleCompletion)
    }
    
    func signHash(walletPublicKey: Data) {
        guard let cardId = card?.cardId else {
            self.complete(with: "Scan card to retrieve cardId")
            return
        }
        
        
        let path = try? DerivationPath(rawPath: hdPath)
        if !hdPath.isEmpty && path == nil {
            self.complete(with: "Failed to parse hd path")
            return
        }
        
        UIApplication.shared.endEditing()
        
        tangemSdk.sign(hash: getRandomHash(),
                       walletPublicKey: walletPublicKey,
                       cardId: cardId,
                       hdPath: path,
                       initialMessage: Message(header: "Signing hash"),
                       completion: handleCompletion)
    }
    
    func signHashes(walletPublicKey: Data) {
        guard let cardId = card?.cardId else {
            self.complete(with: "Scan card to retrieve cardId")
            return
        }
        
        let path = try? DerivationPath(rawPath: hdPath)
        if !hdPath.isEmpty && path == nil {
            self.complete(with: "Failed to parse hd path")
            return
        }
        
        UIApplication.shared.endEditing()
        
        let hashes = (0..<5).map {_ -> Data in getRandomHash()}
        
        tangemSdk.sign(hashes: hashes,
                       walletPublicKey: walletPublicKey,
                       cardId: cardId,
                       hdPath: path,
                       initialMessage: Message(header: "Signing hashes"),
                       completion: handleCompletion)
    }
    
    func derivePublicKey() {
        guard let card = card else {
            self.complete(with: "Scan card before")
            return
        }
        
        guard card.firmwareVersion >= .hdWalletAvailable else {
            self.complete(with: "Not supported firmware verison.")
            return
        }
        
        guard let wallet = card.wallets.first(where: { $0.curve == .secp256k1 }),
              let chainCode = wallet.chainCode else {
            self.complete(with: "The wallet with the secp256k1 curve not found")
            return
        }
        
        guard let path = try? DerivationPath(rawPath: hdPath) else {
            self.complete(with: "Failed to parse hd path")
            return
        }
        
        UIApplication.shared.endEditing()
        
        let masterKey = ExtendedPublicKey(compressedPublicKey: wallet.publicKey,
                                          chainCode: chainCode)
        
        do {
            let childKey = try masterKey.derivePublicKey(path: path)
            handleCompletion(.success(childKey))
        } catch {
            self.complete(with: error.localizedDescription)
        }
    }
    
    func createWallet() {
        guard let cardId = card?.cardId else {
            self.complete(with: "Scan card to retrieve cardId")
            return
        }
        
        tangemSdk.createWallet(curve: curve,
                               cardId: cardId,
                               completion: handleCompletion)
    }
    
    func purgeWallet(walletPublicKey: Data) {
        guard let cardId = card?.cardId else {
            self.complete(with: "Scan card to retrieve cardId")
            return
        }
        
        tangemSdk.purgeWallet(walletPublicKey: walletPublicKey,
                              cardId: cardId,
                              completion: handleCompletion)
    }

    func chainingExample() {
        tangemSdk.startSession(cardId: nil) { session, error in
            if let error = error {
                DispatchQueue.main.async {
                    print(error)
                }
                return
            }
            
            let verifyCommand = AttestCardKeyCommand()
            verifyCommand.run(in: session) { result in
                DispatchQueue.main.async {
                    print(result)
                }
                session.stop()
            }
        }
    }
    
    func depersonalize() {
        tangemSdk.startSession(with: DepersonalizeCommand(), completion: handleCompletion)
    }
    
    func setAccessCode() {
        guard let cardId = card?.cardId else {
            self.complete(with: "Scan card to retrieve cardId")
            return
        }
        
        tangemSdk.setAccessCode(nil,
                                cardId: cardId,
                                completion: handleCompletion)
    }
    
    func setPasscode() {
        guard let cardId = card?.cardId else {
            self.complete(with: "Scan card to retrieve cardId")
            return
        }
        
        tangemSdk.setPasscode(nil,
                              cardId: cardId,
                              completion: handleCompletion)
    }
    
    func resetUserCodes() {
        guard let cardId = card?.cardId else {
            self.complete(with: "Scan card to retrieve cardId")
            return
        }
        
        tangemSdk.resetUserCodes(cardId: cardId,
                                 completion: handleCompletion)
    }
}

//MARK:- Files
extension AppModel {
    func readFiles() {
        tangemSdk.readFiles(readPrivateFiles: true, cardId: card?.cardId) { result in
            switch result {
            case .success(let response):
                self.log(response)
                self.savedFiles = response.files
            case .failure(let error):
                self.complete(with: error)
            }
        }
    }
    
    func readPublicFiles() {
        tangemSdk.readFiles(readPrivateFiles: false, cardId: card?.cardId) { (result) in
            switch result {
            case .success(let response):
                self.savedFiles = response.files
                self.log(response)
            case .failure(let error):
                self.complete(with: error)
            }
        }
    }
    
    func writeSingleFile() {
        let demoData = Data(repeating: UInt8(1), count: 2000)
        let data = FileDataProtectedByPasscode(data: demoData)
        tangemSdk.writeFiles(files: [data], completion: handleCompletion)
    }
    
    func writeSingleSignedFile() {
        guard let cardId = card?.cardId else {
            self.complete(with: "Scan card to retrieve cardId")
            return
        }
        
        let demoData = Data(repeating: UInt8(1), count: 2500)
        let counter = 1
        let fileHash = FileHashHelper.prepareHash(for: cardId, fileData: demoData, fileCounter: counter, privateKey: Utils.issuer.privateKey)
        guard
            let startSignature = fileHash.startingSignature,
            let finalSignature = fileHash.finalizingSignature
        else {
            self.complete(with: "Failed to sign data with issuer signature")
            return
        }
        tangemSdk.writeFiles(files: [
            FileDataProtectedBySignature(data: demoData,
                                         startingSignature: startSignature,
                                         finalizingSignature: finalSignature,
                                         counter: counter)
        ], completion: handleCompletion)
    }
    
    func writeMultipleFiles() {
        let demoData = Data(repeating: UInt8(1), count: 1000)
        let data = FileDataProtectedByPasscode(data: demoData)
        let secondDemoData = Data(repeating: UInt8(1), count: 5)
        let secondData = FileDataProtectedByPasscode(data: secondDemoData)
        
        tangemSdk.writeFiles(files: [data, secondData],
                             completion: handleCompletion)
    }
    
    func deleteFirstFile() {
        guard let savedFiles = self.savedFiles else {
            self.complete(with: "Please, read files before")
            return
        }
        
        guard savedFiles.count > 0 else {
            self.complete(with: "No saved files on card")
            return
        }
        
        tangemSdk.deleteFiles(indicesToDelete: [savedFiles[0].fileIndex], cardId: card?.cardId) { (result) in
            switch result {
            case .success:
                self.savedFiles = nil
                self.complete(with: "First file deleted from card. Please, perform read files command")
            case .failure(let error):
                self.complete(with: error)
            }
        }
    }
    
    func deleteAllFiles() {
        guard let savedFiles = self.savedFiles else {
            self.complete(with: "Please, read files before")
            return
        }
        
        guard savedFiles.count > 0 else {
            self.complete(with: "No saved files on card")
            return
        }
        
        tangemSdk.deleteFiles(indicesToDelete: nil, cardId: card?.cardId) { (result) in
            switch result {
            case .success:
                self.savedFiles = nil
                self.complete(with: "All files where deleted from card. Please, perform read files command")
            case .failure(let error):
                self.complete(with: error)
            }
        }
    }
    
    func updateFirstFileSettings() {
        guard let savedFiles = self.savedFiles else {
            self.complete(with: "Please, read files before")
            return
        }
        
        guard savedFiles.count > 0 else {
            self.complete(with: "No saved files on card")
            return
        }
        
        let file = savedFiles[0]
        let newSettings: FileSettings = file.fileSettings == .public ? .private : .public
        tangemSdk.changeFileSettings(changes: [FileSettingsChange(fileIndex: file.fileIndex, settings: newSettings)], cardId: card?.cardId) { (result) in
            switch result {
            case .success:
                self.savedFiles = nil
                self.complete(with: "File settings updated to \(newSettings.json). Please, perform read files command")
            case .failure(let error):
                self.complete(with: error)
            }
        }
    }
}

//MARK:- Deprecated commands
extension AppModel {
    func readUserData() {
        tangemSdk.readUserData(cardId: card?.cardId,
                               completion: handleCompletion)
    }
    
    func writeUserData() {
        let userData = Data(hexString: "0102030405060708")
        
        tangemSdk.writeUserData(userData: userData,
                                userCounter: 2,
                                cardId: card?.cardId,
                                completion: handleCompletion)
    }
    
    func writeUserProtectedData() {
        let userData = Data(hexString: "01010101010101")
        
        tangemSdk.writeUserProtectedData(userProtectedData: userData,
                                         userProtectedCounter: 1,
                                         cardId: card?.cardId,
                                         completion: handleCompletion)
    }
    
    func readIssuerData() {
        tangemSdk.readIssuerData(cardId: card?.cardId,
                                 initialMessage: Message(header: "Read issuer data", body: "This is read issuer data request")){ result in
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
            self.complete(with: "Scan card to retrieve cardId")
            return
        }
        
        
        guard let issuerDataResponse = issuerDataResponse else {
            self.complete(with: "Please, run ReadIssuerData before")
            return
        }
        
        let newCounter = (issuerDataResponse.issuerDataCounter ?? 0) + 1
        let sampleData = Data(repeating: UInt8(1), count: 100)
        let sig = Secp256k1Utils.sign(Data(hexString: cardId) + sampleData + newCounter.bytes4, with: Utils.issuer.privateKey)!
        
        tangemSdk.writeIssuerData(issuerData: sampleData,
                                  issuerDataSignature: sig,
                                  issuerDataCounter: newCounter,
                                  cardId: cardId,
                                  completion: handleCompletion)
    }
    
    func readIssuerExtraData() {
        tangemSdk.readIssuerExtraData(cardId: card?.cardId){ result in
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
            self.complete(with: "Please, scan card before")
            return
        }
        
        
        guard let issuerDataResponse = issuerExtraDataResponse else {
            self.complete(with: "Please, run ReadIssuerExtraData before")
            return
        }
        let newCounter = (issuerDataResponse.issuerDataCounter ?? 0) + 1
        let sampleData = Data(repeating: UInt8(1), count: 2000)
        let issuerKey = Utils.issuer.privateKey
        
        let startSig = Secp256k1Utils.sign(Data(hexString: cardId) + newCounter.bytes4 + sampleData.count.bytes2, with: issuerKey)!
        let finalSig = Secp256k1Utils.sign(Data(hexString: cardId) + sampleData + newCounter.bytes4, with: issuerKey)!
        
        tangemSdk.writeIssuerExtraData(issuerData: sampleData,
                                       startingSignature: startSig,
                                       finalizingSignature: finalSig,
                                       issuerDataCounter: newCounter,
                                       cardId: cardId,
                                       completion: handleCompletion)
    }
    
    func personalizeBackup2() {
        let config = try! JSONDecoder.tangemSdkDecoder.decode(CardConfig.self, from: AppModel.configJsonBackup2.data(using: .utf8)!)
        let issuer = try! JSONDecoder.tangemSdkDecoder.decode(Issuer.self, from: AppModel.issuerJson.data(using: .utf8)!)
        let manufacturer = try! JSONDecoder.tangemSdkDecoder.decode(Manufacturer.self, from: AppModel.manufacturerJson.data(using: .utf8)!)
        
        let personalizeCommand = PersonalizeCommand(config: config,
                                                    issuer: issuer,
                                                    manufacturer: manufacturer)
        
        tangemSdk.startSession(with: personalizeCommand, completion: handleCompletion)
    }
    
    func personalizeBackup1() {
        let config = try! JSONDecoder.tangemSdkDecoder.decode(CardConfig.self, from: AppModel.configJsonBackup1.data(using: .utf8)!)
        let issuer = try! JSONDecoder.tangemSdkDecoder.decode(Issuer.self, from: AppModel.issuerJson.data(using: .utf8)!)
        let manufacturer = try! JSONDecoder.tangemSdkDecoder.decode(Manufacturer.self, from: AppModel.manufacturerJson.data(using: .utf8)!)
        let personalizeCommand = PersonalizeCommand(config: config,
                                                    issuer: issuer,
                                                    manufacturer: manufacturer)
        
        tangemSdk.startSession(with: personalizeCommand, completion: handleCompletion)
    }
    
    func personalizeOrigin() {
        let config = try! JSONDecoder.tangemSdkDecoder.decode(CardConfig.self, from: AppModel.configJsonOrigin.data(using: .utf8)!)
        let issuer = try! JSONDecoder.tangemSdkDecoder.decode(Issuer.self, from: AppModel.issuerJson.data(using: .utf8)!)
        let manufacturer = try! JSONDecoder.tangemSdkDecoder.decode(Manufacturer.self, from: AppModel.manufacturerJson.data(using: .utf8)!)
        let personalizeCommand = PersonalizeCommand(config: config,
                                                    issuer: issuer,
                                                    manufacturer: manufacturer)
        
        tangemSdk.startSession(with: personalizeCommand, completion: handleCompletion)
    }
}

//MARK:- Json RPC
extension AppModel {
    var jsonRpcTemplate: String {
    """
    {
        "jsonrpc": "2.0",
        "id": 2,
        "method": "",
        "params": {
            
        }
    }
    """
    }
    
    func runJsonRpc() {
        UIApplication.shared.endEditing()
        tangemSdk.startSession(with: json) { self.complete(with: $0) }
    }
    
    func pasteJson() {
        if let string = UIPasteboard.general.string {
            json = string
            
            if #available(iOS 14.0, *) {} else {
                log(json)
            }
        }
    }
    
    func printJson() {
        log(json)
    }
}


extension AppModel {
    enum Method: String, CaseIterable {
        case scan
        case signHash
        case signHashes
        case derivePublicKey
        case attest
        case chainingExample
        case setAccessCode
        case setPasscode
        case resetUserCodes
        case createWallet
        case purgeWallet
        //files
        case readFiles
        case readPublicFiles
        case writeSingleFile
        case writeSingleSignedFile
        case writeMultipleFiles
        case deleteFirstFile
        case deleteAllFiles
        case updateFirstFileSettings
        //case json-rpc
        case jsonrpc
        //deprecated
        case readIssuerData
        case writeIssuerData
        case readIssuerExtraData
        case writeIssuerExtraData
        case readUserData
        case writeUserData
        case writeUserProtectedData
        //developer
        case depersonalize
        case personalizeO
        case personalizeB1
        case personalizeB2
    }
    
    private func chooseMethod(walletPublicKey: Data? = nil) {
        switch method {
        case .attest: attest()
        case .chainingExample: chainingExample()
        case .setAccessCode: setAccessCode()
        case .setPasscode: setPasscode()
        case .resetUserCodes: resetUserCodes()
        case .depersonalize: depersonalize()
        case .scan: scan()
        case .signHash: runWithPublicKey(signHash, walletPublicKey)
        case .signHashes: runWithPublicKey(signHashes, walletPublicKey)
        case .createWallet: createWallet()
        case .purgeWallet: runWithPublicKey(purgeWallet, walletPublicKey)
        case .readFiles: readFiles()
        case .readPublicFiles: readPublicFiles()
        case .writeSingleFile: writeSingleFile()
        case .writeSingleSignedFile: writeSingleSignedFile()
        case .writeMultipleFiles: writeMultipleFiles()
        case .deleteFirstFile: deleteFirstFile()
        case .deleteAllFiles: deleteAllFiles()
        case .updateFirstFileSettings: updateFirstFileSettings()
        case .readIssuerData: readIssuerData()
        case .writeIssuerData: writeIssuerData()
        case .readIssuerExtraData: readIssuerExtraData()
        case .writeIssuerExtraData: writeIssuerExtraData()
        case .readUserData: readUserData()
        case .writeUserData: writeUserData()
        case .writeUserProtectedData: writeUserProtectedData()
        case .derivePublicKey: derivePublicKey()
        case .jsonrpc: runJsonRpc()
        case .personalizeO: personalizeOrigin()
        case .personalizeB1: personalizeBackup1()
        case .personalizeB2: personalizeBackup2()
        }
    }
}
