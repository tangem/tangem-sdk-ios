//
//  ViewController.swift
//  TangemSDKExample
//
//  Created by Alexander Osokin on 10/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import UIKit
import TangemSdk

class ViewController: UIViewController {
    @IBOutlet weak var logView: UITextView!
    
    lazy var tangemSdk: TangemSdk = {
        var config = Config()
        config.linkedTerminal = false
        config.legacyMode = false
        return TangemSdk(config: config)
    }()
    
    var card: Card?
    var issuerDataResponse: ReadIssuerDataResponse?
    var issuerExtraDataResponse: ReadIssuerExtraDataResponse?
	var savedFiles: [File]?
	var filesDataCounter: Int?
    
    @IBAction func scanCardTapped(_ sender: Any) {
        tangemSdk.scanCard {[unowned self] result in
            switch result {
            case .success(let card):
                self.card = card
                self.logView.text = ""
                self.log("read result: \(card)")
            case .failure(let error):
                self.handle(error)
            }
        }
    }
    
    @IBAction func signHashesTapped(_ sender: Any) {
        if #available(iOS 13.0, *) {
            let hashes = (0..<1).map {_ -> Data in getRandomHash()}
            guard let cardId = card?.cardId else {
                self.log("Please, scan card before")
                return
            }
            
            tangemSdk.sign(hashes: hashes, cardId: cardId) {[unowned self] result in
                switch result {
                case .success(let signResponse):
                    self.log(signResponse)
                case .failure(let error):
                    self.handle(error)
                }
            }
        } else {
            // Fallback on earlier versions
            self.log("Only iOS 13+")
        }
    }
    @IBAction func getIssuerDataTapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        if #available(iOS 13.0, *) {
            tangemSdk.readIssuerData(cardId: cardId){ [unowned self] result in
                switch result {
                case .success(let issuerDataResponse):
                    self.issuerDataResponse = issuerDataResponse
                    self.log(issuerDataResponse)
                case .failure(let error):
                    self.handle(error)
                    //handle completion. Unlock UI, etc.
                }
            }
        } else {
            // Fallback on earlier versions
            self.log("Only iOS 13+")
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
        
        if #available(iOS 13.0, *) {
            tangemSdk.writeIssuerData(cardId: cardId,
                                      issuerData: sampleData,
                                      issuerDataSignature: sig,
                                      issuerDataCounter: newCounter) { [unowned self] result in
                                        switch result {
                                        case .success(let issuerDataResponse):
                                            self.log(issuerDataResponse)
                                        case .failure(let error):
                                            self.handle(error)
                                            //handle completion. Unlock UI, etc.
                                        }
            }
        } else {
            // Fallback on earlier versions
            self.log("Only iOS 13+")
        }
    }
    @IBAction func readIssuerExtraDatatapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        if #available(iOS 13.0, *) {
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
        } else {
            // Fallback on earlier versions
            self.log("Only iOS 13+")
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
        
        if #available(iOS 13.0, *) {
            tangemSdk.writeIssuerExtraData(cardId: cardId,
                                           issuerData: sampleData,
                                           startingSignature: startSig,
                                           finalizingSignature: finalSig,
                                           issuerDataCounter: newCounter) { [unowned self] result in
                                            switch result {
                                            case .success(let writeResponse):
                                                self.log(writeResponse)
                                            case .failure(let error):
                                                self.handle(error)
                                                //handle completion. Unlock UI, etc.
                                            }
            }
        } else {
            // Fallback on earlier versions
            self.log("Only iOS 13+")
        }
    }
    
    @IBAction func createWalletTapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        if #available(iOS 13.0, *) {
            tangemSdk.createWallet(cardId: cardId) { [unowned self] result in
                switch result {
                case .success(let response):
                    self.log(response)
                case .failure(let error):
                    self.handle(error)
                    //handle completion. Unlock UI, etc.
                }
            }
        } else {
            // Fallback on earlier versions
            self.log("Only iOS 13+")
        }
        
    }
    
    @IBAction func purgeWalletTapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        if #available(iOS 13.0, *) {
            tangemSdk.purgeWallet(cardId: cardId) { [unowned self] result in
                switch result {
                case .success(let response):
                    self.log(response)
                case .failure(let error):
                    self.handle(error)
                    //handle completion. Unlock UI, etc.
                }
            }
        } else {
            // Fallback on earlier versions
            self.log("Only iOS 13+")
        }
    }
    
    @IBAction func readUserDataTapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        if #available(iOS 13.0, *) {
            tangemSdk.readUserData(cardId: cardId) { [unowned self] result in
                switch result {
                case .success(let response):
                    self.log(response)
                case .failure(let error):
                    self.handle(error)
                    //handle completion. Unlock UI, etc.
                }
            }
        } else {
            // Fallback on earlier versions
            self.log("Only iOS 13+")
        }
    }
    
    
    @IBAction func writeUserDataTapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        let userData = Data(hexString: "0102030405060708")
        
        if #available(iOS 13.0, *) {
            tangemSdk.writeUserData(cardId: cardId, userData: userData, userCounter: 2){ [unowned self] result in
                switch result {
                case .success(let response):
                    self.log(response)
                case .failure(let error):
                    self.handle(error)
                    //handle completion. Unlock UI, etc.
                }
            }

        } else {
            // Fallback on earlier versions
            self.log("Only iOS 13+")
        }
    }
    
    @IBAction func writeUserProtectedDataTapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        let userData = Data(hexString: "01010101010101")
        
        if #available(iOS 13.0, *) {
            tangemSdk.writeUserProtectedData(cardId: cardId, userProtectedData: userData, userProtectedCounter: 1 ){ [unowned self] result in
                switch result {
                case .success(let response):
                    self.log(response)
                case .failure(let error):
                    self.handle(error)
                    //handle completion. Unlock UI, etc.
                }
            }
        } else {
            // Fallback on earlier versions
            self.log("Only iOS 13+")
        }
    }
    
    @available(iOS 13.0, *)
    func chainingExample() {
        tangemSdk.startSession(cardId: nil) { session, error in
            let cmd1 = CheckWalletCommand(curve: session.environment.card!.curve!, publicKey: session.environment.card!.walletPublicKey!)
            cmd1.run(in: session, completion: { result in
                switch result {
                case .success(let response1):
                    DispatchQueue.main.async {
                        self.log(response1)
                    }
                    let cmd2 = CheckWalletCommand(curve: session.environment.card!.curve!, publicKey: session.environment.card!.walletPublicKey!)
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
        
        tangemSdk.verify(cardId: cardId, online: true) { result in
            switch result {
            case .success(let response):
                self.log(response)
            case .failure(let error):
                self.handle(error)
            }
        }
    }
    
    @IBAction func changePin1Tapped(_ sender: Any) {
        guard let cardId = card?.cardId else {
            self.log("Please, scan card before")
            return
        }
        
        tangemSdk.changePin1(cardId: cardId, pin: nil) { result in
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
        
        tangemSdk.changePin2(cardId: cardId, pin: nil) { result in
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
		
		tangemSdk.readFiles(cardId: cardId, readSettings: ReadFilesTaskSettings(readPrivateFiles: false)) { (result) in
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
		
		tangemSdk.deleteFiles(cardId: cardId, indicesToDelete: [savedFiles[0].fileIndex]) { (result) in
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
		
		tangemSdk.deleteFiles(cardId: cardId, indicesToDelete: nil) { (result) in
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
		file.fileSettings = file.fileSettings == .public ? .private : .public
		tangemSdk.changeFilesSettings(cardId: cardId, files: [file]) { (result) in
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
        print(object)
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
