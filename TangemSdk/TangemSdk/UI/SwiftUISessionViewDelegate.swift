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
final class SwiftUISessionViewDelegate {
    public var config: Config
    
    private let reader: CardReader
    private let engine: HapticsEngine
    private var pinnedMessage: String?
    private var infoScreen: MainViewController
    
    init(reader: CardReader, config: Config) {
        self.reader = reader
        self.config = config
        self.engine = HapticsEngine()
        self.infoScreen = MainViewController.makeController(with: config)
        engine.create()
    }
    
    private func presentInfoScreenIfNeeded() {
        guard !self.infoScreen.isBeingPresented, self.infoScreen.presentingViewController == nil,
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
    
    private func runInMainThread(_ block: @autoclosure @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}

@available(iOS 13.0, *)
extension SwiftUISessionViewDelegate: SessionViewDelegate {
    func setState(_ state: SessionViewState) {
        Log.view("Set state: \(state)")
        if state.shouldPlayHaptics {
            engine.playTick()
        }

        runInMainThread(self.infoScreen.setState(state, animated: true))
        runInMainThread(self.presentInfoScreenIfNeeded())
    }
    
    func showAlertMessage(_ text: String) {
        Log.view("Show alert message: \(text)")
        reader.alertMessage = text
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
        runInMainThread(self.presentInfoScreenIfNeeded())
        engine.start()
    }
    
    func sessionStopped(completion: (() -> Void)?) {
        Log.view("Session stopped")
        pinnedMessage = nil
        engine.stop()
        runInMainThread(self.dismissInfoScreen(completion: completion))
    }
    
    func setConfig(_ config: Config) {
        self.config = config
        self.infoScreen = MainViewController.makeController(with: config)
    }
    
    //TODO: Refactor UI
    func attestationDidFail(isDevelopmentCard: Bool, onContinue: @escaping () -> Void, onCancel: @escaping () -> Void) {
        let title = TangemSdkError.cardVerificationFailed.localizedDescription
        let message = isDevelopmentCard ? "This is a development card. You can continue at your own risk"
            : "This card may be production sample or conterfeit. You can continue at your own risk"
        
        runInMainThread(UIAlertController.showShouldContinue(from: self.infoScreen,
                                                             title: title,
                                                             message: message,
                                                             onContinue: onContinue,
                                                             onCancel: onCancel))
    }
    
    //TODO: Refactor UI
    func attestationCompletedOffline(onContinue: @escaping () -> Void, onCancel: @escaping () -> Void, onRetry: @escaping () -> Void) {
        let title =  "Online attestation failed"
        let message = "We cannot finish card's online attestation at this time. You can continue at your own risk and try again later, retry now or cancel the operation"
        
        runInMainThread(UIAlertController.showShouldContinue(from: self.infoScreen,
                                                             title: title,
                                                             message: message,
                                                             onContinue: onContinue,
                                                             onCancel: onCancel,
                                                             onRetry: onRetry))
    }
    
    //TODO: Refactor UI
    func attestationCompletedWithWarnings(onContinue: @escaping () -> Void) {
        let title = "Warning"
        let message = "Too large runs count of Attest Wallet or Sign looks suspicious."
        runInMainThread(UIAlertController.showAlert(from: self.infoScreen,
                                                    title: title,
                                                    message: message,
                                                    onContinue: onContinue))
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
