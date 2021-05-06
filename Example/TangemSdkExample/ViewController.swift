//
//  ViewController.swift
//  TangemSDKExample
//
//  Created by Alexander Osokin on 10/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import UIKit
import TangemSdk

@available(iOS 13.0, *)
class ViewController: UIViewController {
    @IBOutlet weak var logView: UITextView!
    @IBOutlet weak var walletIndexLabel: UILabel!
    @IBOutlet weak var walletMaxIndexLabel: UILabel!
    @IBOutlet weak var walletIndexSlider: UISlider!
    @IBOutlet weak var isReusableSwitch: UISwitch!
    @IBOutlet weak var prohibitPurgeWalletSwitch: UISwitch!
    
    lazy var tangemSdk: TangemSdk = {
        var config = Config()
        config.logСonfig = .custom(logLevel: [.apdu, .debug, .tlv], loggers: [ConsoleLogger()])
        config.linkedTerminal = false
        return TangemSdk(config: config)
    }()
    lazy var timer: MillisecTimer = {
       let timer = MillisecTimer(logger: log(_:))
        return timer
    }()
    
    var card: Card?
    var issuerDataResponse: ReadIssuerDataResponse?
    var issuerExtraDataResponse: ReadIssuerExtraDataResponse?
    var savedFiles: [File]?
    var filesDataCounter: Int?
    var prohibitPurgeWallet: Bool = false
    var isReusableWallet: Bool = true
    
    var walletIndex: Int = 0
    var walIn: WalletIndex {
        .index(walletIndex)
    }
    
    var walletPublicKey: Data? {
        guard let wallet = card?.wallet(at: .index(walletIndex)) else {
            self.log("Can't find wallet at index: \(walletIndex)")
            return nil
        }
        
        guard let publicKey = wallet.publicKey else {
            clearTapped(self)
            self.log("Wallet doesn't contain public key. Wallet status: \(wallet.status)")
            return nil
        }
        
        return publicKey
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prohibitPurgeWalletSwitch.isOn = prohibitPurgeWallet
        isReusableSwitch.isOn = isReusableWallet
    }
    
    private func updateWalletIndex(to index: Int) {
        walletIndex = index
        walletIndexLabel.text = "\(walletIndex)"
    }
    
    @IBAction func prohibitPurgeWalletChanged(_ sender: UISwitch) {
        prohibitPurgeWallet = sender.isOn
    }
    
    @IBAction func isReusableSwitchChanged(_ sender: UISwitch) {
        isReusableWallet = sender.isOn
    }
    
    @IBAction func walletIndexUpdate(_ sender: UISlider) {
        let step: Float = 1
        let roundedValue = round(sender.value / step) * step
        sender.value = roundedValue
        updateWalletIndex(to: Int(roundedValue))
    }
    
    @IBAction func scanCardTapped(_ sender: UIButton) {
        sender.showActivityIndicator()
        timer.start()
        tangemSdk.scanCard(initialMessage: Message(header: "Scan Card", body: "Tap Tangem Card to learn more")) { [unowned self] result in
            switch result {
            case .success(let card):
                self.card = card
                let maxWalletIndex = (card.walletsCount ?? 1) - 1
                self.walletIndexSlider.maximumValue = Float(maxWalletIndex)
                self.walletIndexSlider.value = 0
                self.walletMaxIndexLabel.text = "\(maxWalletIndex)"
                self.updateWalletIndex(to: 0)
                self.logView.text = ""
                self.timer.stop()
                self.log("read result: \(card)")
            case .failure(let error):
                self.handle(error)
            }
            sender.hideActivityIndicator()
        }
    }
    
    @IBAction func signHashTapped(_ sender: UIButton) {
        let hash = getRandomHash()
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        guard let publicKey = walletPublicKey else { return }
        
        tangemSdk.sign(hash: hash, walletPublicKey: publicKey, cardId: cardId, initialMessage: Message(header: "Signing hashes", body: "Signing hashes with wallet with pubkey: \(publicKey.asHexString())")) { [unowned self] result in
            switch result {
            case .success(let signResponse):
                self.log(signResponse)
            case .failure(let error):
                self.handle(error)
            }
        }
    }
    
    @IBAction func signHashesTapped(_ sender: Any) {
        let hashes = (0..<5).map {_ -> Data in getRandomHash()}
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        guard let publicKey = walletPublicKey else { return }
        
        tangemSdk.sign(hashes: hashes, walletPublicKey: publicKey, cardId: cardId, initialMessage: Message(header: "Signing hashes", body: "Signing hashes with wallet with pubkey: \(publicKey.asHexString())")) { [unowned self] result in
            switch result {
            case .success(let signResponse):
                self.log(signResponse)
            case .failure(let error):
                self.handle(error)
            }
        }
    }
    @IBAction func getIssuerDataTapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        tangemSdk.readIssuerData(cardId: cardId, initialMessage: Message(header: "Read issuer data", body: "This is read issuer data request")){ [unowned self] result in
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
    
    @IBAction func writeIssuerDataTapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        guard let issuerDataResponse = issuerDataResponse else {
            self.log("Please, run GetIssuerData before")
            return
        }
        
        let newCounter = (issuerDataResponse.issuerDataCounter ?? 0) + 1
        let sampleData = Data(repeating: UInt8(1), count: 100)
        let issuerKey = Data(hexString: "")
        let sig = Secp256k1Utils.sign(Data(hexString: cardId) + sampleData + newCounter.bytes4, with: issuerKey)!
        
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
    @IBAction func readIssuerExtraDatatapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        tangemSdk.readIssuerExtraData(cardId: cardId){ [unowned self] result in
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
    
    @IBAction func writeIssuerExtraDataTapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        guard let issuerDataResponse = issuerExtraDataResponse else {
            self.log("Please, run GetIssuerExtraData before")
            return
        }
        let newCounter = (issuerDataResponse.issuerDataCounter ?? 0) + 1
        let sampleData = Data(repeating: UInt8(1), count: 2000)
        let issuerKey = Data(hexString: "")
        
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
    
    @IBAction func createWalletTapped(_ sender: UIButton) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        let tag = sender.tag
        var walletConfig: WalletConfig? = nil
        if tag > 0 {
            var curve: EllipticCurve
            switch tag {
            case 2:
                curve = .ed25519
            case 3:
                curve = .secp256r1
            default:
                curve = .secp256k1
            }
            walletConfig = WalletConfig(isReusable: isReusableWallet, prohibitPurgeWallet: prohibitPurgeWallet, curveId: curve, signingMethods: .signHash)
        }
        
        tangemSdk.createWallet(config: walletConfig, cardId: cardId) { [unowned self] result in
            switch result {
            case .success(let response):
                self.log(response)
            case .failure(let error):
                self.handle(error)
            //handle completion. Unlock UI, etc.
            }
        }
        
    }
    
    @IBAction func purgeWalletByPubkeyTapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        guard let publicKey = walletPublicKey else {
            return
        }
        
        tangemSdk.purgeWallet(walletPublicKey: publicKey, cardId: cardId) { [unowned self] result in
            switch result {
            case .success(let response):
                self.log(response)
            case .failure(let error):
                self.handle(error)
            //handle completion. Unlock UI, etc.
            }
        }
    }
    
    @IBAction func readUserDataTapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        tangemSdk.readUserData(cardId: cardId) { [unowned self] result in
            switch result {
            case .success(let response):
                self.log(response)
            case .failure(let error):
                self.handle(error)
            //handle completion. Unlock UI, etc.
            }
        }
    }
    
    
    @IBAction func writeUserDataTapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        let userData = Data(hexString: "0102030405060708")
        
        tangemSdk.writeUserData(userData: userData, userCounter: 2, cardId: cardId){ [unowned self] result in
            switch result {
            case .success(let response):
                self.log(response)
            case .failure(let error):
                self.handle(error)
            //handle completion. Unlock UI, etc.
            }
        }
    }
    
    @IBAction func writeUserProtectedDataTapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        let userData = Data(hexString: "01010101010101")
        
        tangemSdk.writeUserProtectedData(userProtectedData: userData, userProtectedCounter: 1, cardId: cardId){ [unowned self] result in
            switch result {
            case .success(let response):
                self.log(response)
            case .failure(let error):
                self.handle(error)
            //handle completion. Unlock UI, etc.
            }
        }
    }
    
    @available(iOS 13.0, *)
    func chainingExample() {
        tangemSdk.startSession(cardId: nil) { session, error in
            let cmd1 = CheckWalletCommand(curve: session.environment.card!.wallets.first!.curve!, publicKey: session.environment.card!.wallets.first!.publicKey!)
            cmd1.run(in: session, completion: { result in
                switch result {
                case .success(let response1):
                    DispatchQueue.main.async {
                        self.log(response1)
                    }
                    let cmd2 = CheckWalletCommand(curve: session.environment.card!.wallets.first!.curve!, publicKey: session.environment.card!.wallets.first!.publicKey!)
                    cmd2.run(in: session, completion: { result in
                        switch result {
                        case .success(let response2):
                            DispatchQueue.main.async {
                                self.log(response2)
                            }
                            session.stop() // close session manually
                        case .failure(let error):
                            print(error)
                        }
                    })
                case .failure(let error):
                    print(error)
                }
            })
        }
    }
    
    @IBAction func depersonalizeTapped(_ sender: Any) {
        tangemSdk.depersonalize() { result in
            switch result {
            case .success(let response):
                self.log(response)
            case .failure(let error):
                self.handle(error)
            }
        }
    }
    
    @IBAction func verifyCardTapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        (sender as! UIButton).showActivityIndicator()
        tangemSdk.verify(online: true, cardId: cardId) { result in
            switch result {
            case .success(let response):
                self.log(response)
            case .failure(let error):
                self.handle(error)
            }
            (sender as! UIButton).hideActivityIndicator()
        }
    }
    
    @IBAction func changePin1Tapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        tangemSdk.changePin1(pin: nil, cardId: cardId) { result in
            switch result {
            case .success(let response):
                self.log(response)
            case .failure(let error):
                self.handle(error)
            }
        }
    }
    
    @IBAction func changePin2Tapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        tangemSdk.changePin2(pin: nil, cardId: cardId) { result in
            switch result {
            case .success(let response):
                self.log(response)
            case .failure(let error):
                self.handle(error)
            }
        }
    }
    
    @IBAction func readFilesTapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        tangemSdk.readFiles(cardId: cardId) { result in
            switch result {
            case .success(let response):
                self.log(response)
                self.savedFiles = response.files
            case .failure(let error):
                self.handle(error)
            }
        }
    }
    
    @IBAction func readPublicFilesTapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        tangemSdk.readFiles(readPrivateFiles: false, cardId: cardId) { (result) in
            switch result {
            case .success(let response):
                self.savedFiles = response.files
                self.log(response)
            case .failure(let error):
                self.handle(error)
            }
        }
    }
    
    @IBAction func writeSingleFileTapped(_ sender: Any) {
        guard let _ = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        let demoData = Data(repeating: UInt8(1), count: 100)
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
    
    @IBAction func writeSingleSignedFileTapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        let demoData = Data(repeating: UInt8(1), count: 500)
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
    
    @IBAction func writeMultipleFilesTapped(_ sender: Any) {
        guard let _ = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        let demoData = Data(repeating: UInt8(1), count: 100)
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
    
    @IBAction func deleteFirstFileTapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        guard let savedFiles = self.savedFiles else {
            log("Please, read files before")
            return
        }
        
        guard savedFiles.count > 0 else {
            log("No saved files on card")
            return
        }
        
        tangemSdk.deleteFiles(indicesToDelete: [savedFiles[0].fileIndex], cardId: cardId) { (result) in
            switch result {
            case .success:
                self.savedFiles = nil
                self.log("First file deleted from card. Please, perform read files command")
            case .failure(let error):
                self.handle(error)
            }
        }
    }
    
    @IBAction func deleteAllFilesTapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        guard let savedFiles = self.savedFiles else {
            log("Please, read files before")
            return
        }
        
        guard savedFiles.count > 0 else {
            log("No saved files on card")
            return
        }
        
        tangemSdk.deleteFiles(indicesToDelete: nil, cardId: cardId) { (result) in
            switch result {
            case .success:
                self.savedFiles = nil
                self.log("All files where deleted from card. Please, perform read files command")
            case .failure(let error):
                self.handle(error)
            }
        }
    }
    
    @IBAction func updateFirstFileSettingsTapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            log("Please, scan card before")
            return
        }
        
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
        tangemSdk.changeFilesSettings(changes: [FileSettingsChange(fileIndex: file.fileIndex, settings: newSettings)], cardId: cardId) { (result) in
            switch result {
            case .success:
                self.savedFiles = nil
                self.log("File settings updated to \(file.fileSettings!). Please, perform read files command")
            case .failure(let error):
                self.handle(error)
            }
        }
    }
    
    @IBAction func clearTapped(_ sender: Any) {
        self.logView.text = ""
    }
    
    private func log(_ object: Any) {
        self.logView.text = self.logView.text.appending("\(object)\n\n")
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
