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
    // Inputs
    @Published var isPermanent: Bool = false
    @Published var curve: EllipticCurve = .secp256k1
    @Published var attestationMode: AttestationTask.Mode = .normal
    @Published var method: Method = .scan
    
    // Outputs
    @Published var logText: String = ""
    @Published var isScanning: Bool = false
    
    private lazy var tangemSdk: TangemSdk = {
        var config = Config()
        config.logСonfig = .custom(logLevel: [.debug])
        config.linkedTerminal = false
        config.allowedCardTypes = FirmwareVersion.FirmwareType.allCases
        return TangemSdk(config: config)
    }()
    
    private var card: Card?
    private var issuerDataResponse: ReadIssuerDataResponse?
    private var issuerExtraDataResponse: ReadIssuerExtraDataResponse?
    private var savedFiles: [File]?
    
    func clear() {
        logText = ""
    }
    
    func start() {
        isScanning = true
        chooseMethod()
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
}

// MARK:- Commands
extension AppModel {
    func scan() {
        tangemSdk.scanCard(initialMessage: Message(header: "Scan Card", body: "Tap Tangem Card to learn more")) { result in
            if case let .success(card) = result {
                self.card = card
            }
            
            self.handleCompletion(result)
        }
    }
    
    func attest() {
        tangemSdk.startSession(with: AttestationTask(mode: attestationMode), completion: handleCompletion)
    }
    
    func signHash() {
        let hash = getRandomHash()
        guard let publicKey = card?.wallets.first?.publicKey else { return }
        
        tangemSdk.sign(hash: hash,
                       walletPublicKey: publicKey,
                       cardId: card?.cardId,
                       initialMessage: Message(header: "Signing hashes", body: "Signing hashes with wallet with pubkey: \(publicKey.hexString)"),
                       completion: handleCompletion)
    }
    
    func signHashes() {
        let hashes = (0..<5).map {_ -> Data in getRandomHash()}
        guard let publicKey = card?.wallets.first?.publicKey else { return }
        
        tangemSdk.sign(hashes: hashes,
                       walletPublicKey: publicKey,
                       cardId: card?.cardId,
                       initialMessage: Message(header: "Signing hashes", body: "Signing hashes with wallet with pubkey: \(publicKey.hexString)"),
                       completion: handleCompletion)
    }
    
    func createWallet() {
        tangemSdk.createWallet(curve: curve,
                               isPermanent: isPermanent,
                               cardId: card?.cardId,
                               completion: handleCompletion)
    }
    
    func purgeWallet() {
        guard let publicKey = card?.wallets.first?.publicKey else { return }
        
        tangemSdk.purgeWallet(walletPublicKey: publicKey,
                              cardId: card?.cardId,
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
        tangemSdk.depersonalize(completion: handleCompletion)
    }
    
    func changePin1() {
        tangemSdk.changePin1(pin: nil,
                             cardId: card?.cardId,
                             completion: handleCompletion)
    }
    
    func changePin2() {
        tangemSdk.changePin2(pin: nil,
                             cardId: card?.cardId,
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
                                         counter: counter,
                                         issuerPublicKey: Utils.issuer.publicKey)
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
        tangemSdk.changeFilesSettings(changes: [FileSettingsChange(fileIndex: file.fileIndex, settings: newSettings)], cardId: card?.cardId) { (result) in
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
    
}


extension AppModel {
    enum Method: String, CaseIterable {
        case scan
        case signHash
        case signHashes
        case attest
        case chainingExample
        case depersonalize
        case changePin1
        case changePin2
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
        //deprecated
        case readIssuerData
        case writeIssuerData
        case readIssuerExtraData
        case writeIssuerExtraData
        case readUserData
        case writeUserData
        case writeUserProtectedData
    }
    
    private func chooseMethod() {
        switch method {
        case .attest: attest()
        case .chainingExample: chainingExample()
        case .changePin1: changePin1()
        case .changePin2: changePin2()
        case .depersonalize: depersonalize()
        case .scan: scan()
        case .signHash: signHash()
        case .signHashes:  signHashes()
        case .createWallet: createWallet()
        case .purgeWallet:  purgeWallet()
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
        }
    }
}

