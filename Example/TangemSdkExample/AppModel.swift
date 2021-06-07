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
    @Published var prohibitPurgeWallet: Bool = false
    @Published var curve: EllipticCurve = .secp256k1
    
    // Outputs
    @Published var logText: String = ""
    @Published var isScanning: Bool = false
    
    private lazy var tangemSdk: TangemSdk = {
        var config = Config()
        config.logСonfig = .custom(logLevel: [.apdu, .debug, .tlv], loggers: [ConsoleLogger()])
        config.linkedTerminal = false
        return TangemSdk(config: config)
    }()
    
    private var card: Card?
    private var issuerDataResponse: ReadIssuerDataResponse?
    private var issuerExtraDataResponse: ReadIssuerExtraDataResponse?
    private var savedFiles: [File]?
    
    func clear() {
        logText = ""
    }
    
    private func log(_ object: Any) {
        let text: String = (object as? JSONStringConvertible)?.json ?? "\(object)"
        logText = logText.appending("\(text)\n\n")
    }
    
    private func handle(_ error: TangemSdkError) {
        if !error.isUserCancelled {
            self.log("\(error.localizedDescription)")
        }
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
        isScanning = true
        tangemSdk.scanCard(initialMessage: Message(header: "Scan Card", body: "Tap Tangem Card to learn more")) { [unowned self] result in
            switch result {
            case .success(let card):
                self.card = card
                self.log(card)
            case .failure(let error):
                self.handle(error)
            }
            isScanning = false
        }
    }
    
    func signHash() {
        let hash = getRandomHash()
        guard let publicKey = card?.wallets.first?.publicKey else { return }
        
        tangemSdk.sign(hash: hash, walletPublicKey: publicKey, cardId: card?.cardId, initialMessage: Message(header: "Signing hashes", body: "Signing hashes with wallet with pubkey: \(publicKey.asHexString())")) { [unowned self] result in
            switch result {
            case .success(let signResponse):
                self.log(signResponse)
            case .failure(let error):
                self.handle(error)
            }
        }
    }
    
    func signHashes() {
        let hashes = (0..<5).map {_ -> Data in getRandomHash()}
        guard let publicKey = card?.wallets.first?.publicKey else { return }
        
        tangemSdk.sign(hashes: hashes, walletPublicKey: publicKey, cardId: card?.cardId, initialMessage: Message(header: "Signing hashes", body: "Signing hashes with wallet with pubkey: \(publicKey.asHexString())")) { [unowned self] result in
            switch result {
            case .success(let signResponse):
                self.log(signResponse)
            case .failure(let error):
                self.handle(error)
            }
        }
    }
    
    func createWallet() {
        let walletConfig = WalletConfig(prohibitPurgeWallet: prohibitPurgeWallet,
                                                        curve: curve,
                                                        signingMethods: .signHash)

        tangemSdk.createWallet(config: walletConfig, cardId: card?.cardId) { [unowned self] result in
            switch result {
            case .success(let response):
                self.log(response)
            case .failure(let error):
                self.handle(error)
            //handle completion. Unlock UI, etc.
            }
        }
    }
    
    func purgeWallet() {
        guard let publicKey = card?.wallets.first?.publicKey else { return }
        
        tangemSdk.purgeWallet(walletPublicKey: publicKey, cardId: card?.cardId) { [unowned self] result in
            switch result {
            case .success(let response):
                self.log(response)
            case .failure(let error):
                self.handle(error)
            //handle completion. Unlock UI, etc.
            }
        }
    }
    

    func chainingExample() {
        tangemSdk.startSession(cardId: nil) { session, error in
            if let error = error {
                DispatchQueue.main.async {
                    print(error)
                }
                return
            }
            
            let verifyCommand = VerifyCardCommand()
            verifyCommand.run(in: session) { result in
                DispatchQueue.main.async {
                    print(result)
                }
                session.stop()
            }
        }
    }
    
    func depersonalize() {
        tangemSdk.depersonalize() { result in
            switch result {
            case .success(let response):
                self.log(response)
            case .failure(let error):
                self.handle(error)
            }
        }
    }
    
    func verifyCard() {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        // (sender as! UIButton).showActivityIndicator()
        tangemSdk.verify(online: true, cardId: cardId) { result in
            switch result {
            case .success(let response):
                self.log(response)
            case .failure(let error):
                self.handle(error)
            }
            // (sender as! UIButton).hideActivityIndicator()
        }
    }
    
    func changePin1() {
        tangemSdk.changePin1(pin: nil, cardId: card?.cardId) { result in
            switch result {
            case .success(let response):
                self.log(response)
            case .failure(let error):
                self.handle(error)
            }
        }
    }
    
    func changePin2() {
        tangemSdk.changePin2(pin: nil, cardId: card?.cardId) { result in
            switch result {
            case .success(let response):
                self.log(response)
            case .failure(let error):
                self.handle(error)
            }
        }
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
                self.handle(error)
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
                self.handle(error)
            }
        }
    }
    
    func writeSingleFile() {
        let demoData = Data(repeating: UInt8(1), count: 2000)
        let data = FileDataProtectedByPasscode(data: demoData)
        tangemSdk.writeFiles(files: [data]) { (result) in
            switch result {
            case .success(let response):
                self.log(response)
            case .failure(let error):
                self.handle(error)
            }
        }
    }
    
    func writeSingleSignedFile() {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        let demoData = Data(repeating: UInt8(1), count: 2500)
        let counter = 1
        let fileHash = FileHashHelper.prepareHash(for: cardId, fileData: demoData, fileCounter: counter, privateKey: Utils.issuer.privateKey)
        guard
            let startSignature = fileHash.startingSignature,
            let finalSignature = fileHash.finalizingSignature
        else {
            self.log("Failed to sign data with issuer signature")
            return
        }
        tangemSdk.writeFiles(files: [
            FileDataProtectedBySignature(data: demoData,
                                         startingSignature: startSignature,
                                         finalizingSignature: finalSignature,
                                         counter: counter,
                                         issuerPublicKey: Utils.issuer.publicKey)
        ]) { (result) in
            switch result {
            case .success(let response):
                self.log(response)
            case .failure(let error):
                self.handle(error)
            }
        }
    }
    
    func writeMultipleFiles() {
        let demoData = Data(repeating: UInt8(1), count: 1000)
        let data = FileDataProtectedByPasscode(data: demoData)
        let secondDemoData = Data(repeating: UInt8(1), count: 5)
        let secondData = FileDataProtectedByPasscode(data: secondDemoData)
        tangemSdk.writeFiles(files: [data, secondData]) { (result) in
            switch result {
            case .success(let response):
                self.log(response)
            case .failure(let error):
                self.handle(error)
            }
        }
    }
    
    func deleteFirstFile() {
        guard let savedFiles = self.savedFiles else {
            log("Please, read files before")
            return
        }
        
        guard savedFiles.count > 0 else {
            log("No saved files on card")
            return
        }
        
        tangemSdk.deleteFiles(indicesToDelete: [savedFiles[0].fileIndex], cardId: card?.cardId) { (result) in
            switch result {
            case .success:
                self.savedFiles = nil
                self.log("First file deleted from card. Please, perform read files command")
            case .failure(let error):
                self.handle(error)
            }
        }
    }
    
    func deleteAllFiles() {
        guard let savedFiles = self.savedFiles else {
            log("Please, read files before")
            return
        }
        
        guard savedFiles.count > 0 else {
            log("No saved files on card")
            return
        }
        
        tangemSdk.deleteFiles(indicesToDelete: nil, cardId: card?.cardId) { (result) in
            switch result {
            case .success:
                self.savedFiles = nil
                self.log("All files where deleted from card. Please, perform read files command")
            case .failure(let error):
                self.handle(error)
            }
        }
    }
    
    func updateFirstFileSettings() {
        guard let savedFiles = self.savedFiles else {
            log("Please, read files before")
            return
        }
        
        guard savedFiles.count > 0 else {
            log("No saved files on card")
            return
        }
        
        let file = savedFiles[0]
        let newSettings: FileSettings = file.fileSettings == .public ? .private : .public
        tangemSdk.changeFilesSettings(changes: [FileSettingsChange(fileIndex: file.fileIndex, settings: newSettings)], cardId: card?.cardId) { (result) in
            switch result {
            case .success:
                self.savedFiles = nil
                self.log("File settings updated to \(newSettings.json). Please, perform read files command")
            case .failure(let error):
                self.handle(error)
            }
        }
    }
}

//MARK:- Deprecated commands
extension AppModel {
    func readUserData() {
        tangemSdk.readUserData(cardId: card?.cardId) { [unowned self] result in
            switch result {
            case .success(let response):
                self.log(response)
            case .failure(let error):
                self.handle(error)
            //handle completion. Unlock UI, etc.
            }
        }
    }
    
    func writeUserData() {
        let userData = Data(hexString: "0102030405060708")
        
        tangemSdk.writeUserData(userData: userData, userCounter: 2, cardId: card?.cardId){ [unowned self] result in
            switch result {
            case .success(let response):
                self.log(response)
            case .failure(let error):
                self.handle(error)
            //handle completion. Unlock UI, etc.
            }
        }
    }
    
    func writeUserProtectedData() {
        let userData = Data(hexString: "01010101010101")
        
        tangemSdk.writeUserProtectedData(userProtectedData: userData, userProtectedCounter: 1, cardId: card?.cardId){ [unowned self] result in
            switch result {
            case .success(let response):
                self.log(response)
            case .failure(let error):
                self.handle(error)
            //handle completion. Unlock UI, etc.
            }
        }
    }
    
    func getIssuerData() {
        tangemSdk.readIssuerData(cardId: card?.cardId, initialMessage: Message(header: "Read issuer data", body: "This is read issuer data request")){ [unowned self] result in
            switch result {
            case .success(let issuerDataResponse):
                self.issuerDataResponse = issuerDataResponse
                self.log(issuerDataResponse)
            case .failure(let error):
                self.handle(error)
            //handle completion. Unlock UI, etc.
            }
        }
    }
    
    func writeIssuerData() {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        
        guard let issuerDataResponse = issuerDataResponse else {
            self.log("Please, run ReadIssuerData before")
            return
        }
        
        let newCounter = (issuerDataResponse.issuerDataCounter ?? 0) + 1
        let sampleData = Data(repeating: UInt8(1), count: 100)
        let sig = Secp256k1Utils.sign(Data(hexString: cardId) + sampleData + newCounter.bytes4, with: Utils.issuer.privateKey)!
        
        tangemSdk.writeIssuerData(issuerData: sampleData,
                                  issuerDataSignature: sig,
                                  issuerDataCounter: newCounter,
                                  cardId: cardId) { [unowned self] result in
            switch result {
            case .success(let issuerDataResponse):
                self.log(issuerDataResponse)
            case .failure(let error):
                self.handle(error)
            //handle completion. Unlock UI, etc.
            }
        }
    }
    
    func readIssuerExtraData() {
        tangemSdk.readIssuerExtraData(cardId: card?.cardId){ [unowned self] result in
            switch result {
            case .success(let issuerDataResponse):
                self.issuerExtraDataResponse = issuerDataResponse
                self.log(issuerDataResponse)
                print(issuerDataResponse.issuerData.asHexString())
            case .failure(let error):
                self.handle(error)
            //handle completion. Unlock UI, etc.
            }
        }
    }

    func writeIssuerExtraData() {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        
        guard let issuerDataResponse = issuerExtraDataResponse else {
            self.log("Please, run ReadIssuerExtraData before")
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
                                       cardId: cardId) { [unowned self] result in
            switch result {
            case .success(let writeResponse):
                self.log(writeResponse)
            case .failure(let error):
                self.handle(error)
            //handle completion. Unlock UI, etc.
            }
        }
    }
    
}
