//
//  SwiftUISessionViewDelegate.swift
//  TangemSdk
//
//  Created by Andrew Son on 02/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

@available(iOS 13.0, *)
final class SwiftUISessionViewDelegate: SessionViewDelegate {
    public var config: Config
    
    private let reader: CardReader
    private let engine: HapticsEngine
    private var pinnedMessage: String?
    
    private lazy var infoScreen: MainViewController = {
        let controller =  MainViewController(rootView: MainView())
        controller.modalPresentationStyle = .overFullScreen
        controller.modalTransitionStyle = .crossDissolve
        return controller
    }()
    
    init(reader: CardReader, config: Config) {
        self.reader = reader
        self.config = config
        self.engine = HapticsEngine()
        engine.create()
    }
    
    func setState(_ state: SessionViewState) {
        Log.view(state)
        runInMainThread {
            self.infoScreen.setState(state, animated: true)
        }
    }
    
    func showAlertMessage(_ text: String) {
        Log.view("Show alert message: \(text)")
        reader.alertMessage = text
    }
    
    func requestUserCode(type: UserCodeType, cardId: String?, completion: @escaping (_ code: String?) -> Void) {
        runInMainThread {
            Log.view("Showing user code request with type: \(type)")
            switch type {
            case .accessCode:
                self.requestPin(.pin1, cardId: cardId, completion: completion)
            case .passcode:
                self.requestPin(.pin2, cardId: cardId, completion: completion)
            }
        }
    }
    func requestUserCodeChange(type: UserCodeType, cardId: String?, completion: @escaping CompletionResult<(currentCode: String, newCode: String)>) {
        runInMainThread {
            Log.view("Showing user code change request with type: \(type)")
            switch type {
            case .accessCode:
                self.requestChangePin(.pin1, cardId: cardId, completion: completion)
            case .passcode:
                self.requestChangePin(.pin2, cardId: cardId, completion: completion)
            }
        }
    }
    
    func tagConnected() {
        Log.view("Tag connected")
        if let pinnedMessage = pinnedMessage {
            showAlertMessage(pinnedMessage)
            self.pinnedMessage = nil
        }
        engine.playSuccess()
        setState(.default)
    }
    
    func tagLost() {
        Log.view("Tag lost")
        pinnedMessage = reader.alertMessage
        showAlertMessage(Localization.nfcAlertDefault)
        setState(.scan)
    }
    
    func wrongCard(message: String?) {
        Log.view("Wrong card detected")
        engine.playError()
        
        if let message = message {
            let oldMessage = reader.alertMessage
            showAlertMessage(message)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.showAlertMessage(oldMessage)
            }
        }
    }
    
    func sessionStarted() {
        Log.view("Session started")
        
        runInMainThread {
            self.presentInfoScreen()
        }
        
        engine.start()
    }
    
    func sessionStopped(completion: (() -> Void)?) {
        Log.view("Session stopped")
        pinnedMessage = nil
        engine.stop()
        runInMainThread {
            self.dismissInfoScreen(completion: completion)
        }
    }
    
    func setConfig(_ config: Config) {
        self.config = config
    }
    
    //TODO: Refactor UI
    func attestationDidFail(isDevelopmentCard: Bool, onContinue: @escaping () -> Void, onCancel: @escaping () -> Void) {
        let title = TangemSdkError.cardVerificationFailed.localizedDescription
        let message = isDevelopmentCard ? "This is a development card. You can continue at your own risk"
            : "This card may be production sample or conterfeit. You can continue at your own risk"
        
        runInMainThread {
            UIAlertController.showShouldContinue(from: self.infoScreen, title: title, message: message, onContinue: onContinue, onCancel: onCancel)
        }
    }
    
    //TODO: Refactor UI
    func attestationCompletedOffline(onContinue: @escaping () -> Void, onCancel: @escaping () -> Void, onRetry: @escaping () -> Void) {
        let title =  "Online attestation failed"
        let message = "We cannot finish card's online attestation at this time. You can continue at your own risk and try again later, retry now or cancel the operation"
        
        runInMainThread {
            UIAlertController.showShouldContinue(from: self.infoScreen, title: title, message: message, onContinue: onContinue, onCancel: onCancel, onRetry: onRetry)
        }
    }
    
    //TODO: Refactor UI
    func attestationCompletedWithWarnings(onContinue: @escaping () -> Void) {
        let title = "Warning"
        let message = "Too large runs count of Attest Wallet or Sign looks suspicious."
        runInMainThread {
            UIAlertController.showAlert(from: self.infoScreen, title: title, message: message, onContinue: onContinue)
        }
    }
    
    private func presentInfoScreen() {
        guard !self.infoScreen.isBeingPresented,
              let topmostViewController = UIApplication.shared.topMostViewController
        else { return }
        
        topmostViewController.present(self.infoScreen, animated: true, completion: nil)
    }
    
    private func dismissInfoScreen(completion: (() -> Void)?) {
        if self.infoScreen.isBeingDismissed {
            completion?()
            return
        }
        
        if self.infoScreen.isBeingPresented {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.infoScreen.dismiss(animated: false, completion: completion)
            }
            return
        }
        
        self.infoScreen.dismiss(animated: true, completion: completion)
    }
    
    private func requestPin(_ state: PinViewControllerState, cardId: String?, completion: @escaping (String?) -> Void) {
        let cardId = formatCardId(cardId)
        let storyBoard = UIStoryboard(name: "PinStoryboard", bundle: .sdkBundle)
        let vc = storyBoard.instantiateViewController(identifier: "PinViewController", creator: { coder in
            return PinViewController(coder: coder, state: state, cardId: cardId, completionHandler: completion)
        })
        if let topmostViewController = UIApplication.shared.topMostViewController {
            vc.modalPresentationStyle = .fullScreen
            // infoScreenAppearWork?.cancel()
            topmostViewController.present(vc, animated: true, completion: nil)
        } else {//
            completion(nil)
        }
    }
    
    private func requestChangePin(_ state: PinViewControllerState, cardId: String?, completion: @escaping CompletionResult<(currentCode: String, newCode: String)>) {
        let cardId = formatCardId(cardId)
        let storyBoard = UIStoryboard(name: "PinStoryboard", bundle: .sdkBundle)
        let vc = storyBoard.instantiateViewController(identifier: "ChangePinViewController", creator: { coder in
            return  ChangePinViewController(coder: coder, state: state, cardId: cardId, completionHandler: completion)
        })
        if let topmostViewController = UIApplication.shared.topMostViewController {
            vc.modalPresentationStyle = .fullScreen
            // infoScreenAppearWork?.cancel()
            topmostViewController.present(vc, animated: true, completion: nil)
        } else {
            completion(.failure(.unknownError))
        }
    }
    
    private func formatCardId(_ cid: String?) -> String? {
        guard let cid = cid else {
            return nil
        }
        
        let cidFormatter = CardIdFormatter()
        return cidFormatter.formatted(cid: cid, numbers: config.cardIdDisplayedNumbersCount)
    }
    
    private func runInMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}

//TODO: Localize
fileprivate extension UIAlertController {
    static func showShouldContinue(from controller: UIViewController, title: String, message: String, onContinue: @escaping () -> Void, onCancel: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "I understand", style: .destructive) { _ in onContinue() })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in onCancel() } )
        controller.present(alert, animated: true)
    }
    
    static func showShouldContinue(from controller: UIViewController, title: String, message: String, onContinue: @escaping () -> Void, onCancel: @escaping () -> Void, onRetry: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "I understand", style: .destructive) { _ in onContinue() })
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in onRetry() })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in onCancel() } )
        controller.present(alert, animated: true)
    }
    
    static func showAlert(from controller: UIViewController, title: String, message: String, onContinue: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default) { _ in onContinue() })
        controller.present(alert, animated: true)
    }
}
