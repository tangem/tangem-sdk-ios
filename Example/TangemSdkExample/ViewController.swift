//
//  ViewController.swift
//  TangemSDKExample
//
//  Created by Alexander Osokin on 10/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import UIKit
import TangemSdk
import CoreNFC

class ViewController: UIViewController {
    
    var cardManager: CardManager = CardManager()
    
    var card: Card?
    
    @IBAction func scanCardTapped(_ sender: Any) {
        cardManager.scanCard {[unowned self] scanResult in
            var date = Date()
            switch scanResult {
            case .event(let scanEvent):
                switch scanEvent {
                case .onRead(let card):
                    date = Date()
                    self.card = card
                    print("read result: \(card)")
                case .onVerify(let isGenuine):
                    let dateDiff = Calendar.current.dateComponents([.second,.nanosecond], from: date, to: Date())
                    print("Verify time is: \(dateDiff.second ?? 0).\(dateDiff.nanosecond ?? 0) sec.")
                    print("verify result: \(isGenuine)")
                }
            case .failure(let error):
                if case .userCancelled = error {
                    //silence error
                    return
                }
                let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.show(alertController, sender: nil)
            case .success(let newEnvironment):
                print("Sign completed with environment: \(newEnvironment)")
            }
        }
    }
    
    @IBAction func signHashesTapped(_ sender: Any) {
        let hash1 = Data(repeating: 1, count: 32) //dummy hashes
        let hash2 = Data(repeating: 2, count: 32)
        let hashes = [hash1, hash2]
        guard let cardId = card?.cardId else {
            print("Please, scan card before")
            return
        }
        
        cardManager.sign(hashes: hashes, environment: CardEnvironment(cardId: cardId)) { signResult  in
            switch signResult {
            case .event(let signResponse):
                print(signResponse)
            case .failure(let error):
                if case .userCancelled = error {
                    //silence error
                    return
                }
                print(error.localizedDescription)
            case .success(let newEnvironment):
                print("Sign completed with environment: \(newEnvironment)")
            }
        }
    }
}
