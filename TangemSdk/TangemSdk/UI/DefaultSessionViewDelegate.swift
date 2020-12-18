//
//  DefaultSessionViewDelegate.swift
//  TangemSdk
//
//  Created by Andrew Son on 02/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import CoreHaptics

@available(iOS 13.0, *)
final class DefaultSessionViewDelegate: SessionViewDelegate {
	private let reader: CardReader
	private var engine: CHHapticEngine?
	private var engineNeedsStart = true
	private let transitioningDelegate: FadeTransitionDelegate
	private var infoScreenAppearWork: DispatchWorkItem?
    private var pinMessage: String?
	
	private lazy var infoScreen: InformationScreenViewController = {
		InformationScreenViewController.instantiateController(transitioningDelegate: transitioningDelegate)
	}()
	
	private lazy var delayFormatter: DateComponentsFormatter = {
		let formatter = DateComponentsFormatter()
		formatter.unitsStyle = .full
		formatter.allowedUnits = [.second, .nanosecond]
		return formatter
	}()
	
	private lazy var supportsHaptics: Bool = {
		return CHHapticEngine.capabilitiesForHardware().supportsHaptics
	}()
	
	init(reader: CardReader) {
		self.reader = reader
		self.transitioningDelegate = FadeTransitionDelegate()
		createHapticEngine()
	}
    
    func pinMessage(_ text: String?) {
        pinMessage = text
        
        guard let message = text else { return }
        
        showAlertMessage(message)
    }
	
	func showAlertMessage(_ text: String) {
		reader.alertMessage = text
	}
	
	func hideUI(_ indicatorMode: IndicatorMode?) {
		print("Session view delegate hideUI with mode: \(indicatorMode)")
		guard let indicatorMode = indicatorMode else {
			DispatchQueue.main.async {
				self.dismissInfoScreen()
			}
			return
		}
		
		DispatchQueue.main.async {
			switch indicatorMode {
			case .sd:
				self.infoScreen.setState(.spinner, animated: true)
			case .percent:
				self.dismissInfoScreen()
			}
		}
	}
	
	private var remainingSecurityDelaySec: Float = 0
	func showSecurityDelay(remainingMilliseconds: Int, message: Message?, hint: String?) {
		print("Showing security delay")
		playTick()
        
        let unwrappedMessage = message?.alertMessage ?? Localization.nfcAlertDefault
        if let pinnedMessage = pinMessage {
            showAlertMessage(pinnedMessage + "\n" + unwrappedMessage)
        } else {
            showAlertMessage(unwrappedMessage)
        }
        
		DispatchQueue.main.async {
			guard remainingMilliseconds >= 100 else {
				self.infoScreen.setState(.spinner, animated: true)
				return
			}
			
			let remainingSeconds = Float(remainingMilliseconds/100)
			self.remainingSecurityDelaySec = remainingSeconds
			
			if self.infoScreen.state != .securityDelay {
				self.infoScreen.setupIndicatorTotal(remainingSeconds + 1)
			}
			
			self.infoScreen.setState(.securityDelay, animated: true)
				
			self.presentInfoScreen()
			self.infoScreen.tickSD(remainingValue: remainingSeconds, message: "\(Int(remainingSeconds))", hint: hint ?? Localization.nfcAlertDefault)
		}
	}
	
	
	func showPercentLoading(_ percent: Int, message: Message?, hint: String?) {
		playTick()
		showAlertMessage(message?.alertMessage ?? Localization.nfcAlertDefault)
		
		DispatchQueue.main.async {
			self.infoScreen.setState(.percentProgress, animated: true)
			self.presentInfoScreen()
			self.infoScreen.tickPercent(percentValue: percent, message: String(format: "%@%%", percent.description), hint: hint)
		}
	}
	
	func showUndefinedSpinner() {
		guard remainingSecurityDelaySec <= 1 else { return }
		
		infoScreenAppearWork?.cancel()
		DispatchQueue.main.async {
			self.presentInfoScreen()
			self.infoScreen.setState(.spinner, animated: true)
		}
	}
	
	func requestPin(pinType: PinCode.PinType, cardId: String?, completion: @escaping (_ pin: String?) -> Void) {
		switch pinType {
		case .pin1:
			requestPin(.pin1, cardId: cardId, completion: completion)
		case .pin2:
			requestPin(.pin2, cardId: cardId, completion: completion)
		case .pin3:
			requestPin(.pin3, cardId: cardId, completion: completion)
		}
	}
	
	func requestPinChange(pinType: PinCode.PinType, cardId: String?, completion: @escaping CompletionResult<(currentPin: String, newPin: String)>) {
		switch pinType {
		case .pin1:
			requestChangePin(.pin1, cardId: cardId, completion: completion)
		case .pin2:
			requestChangePin(.pin2, cardId: cardId, completion: completion)
		case .pin3:
			requestChangePin(.pin3, cardId: cardId, completion: completion)
		}
	}
	
	func tagConnected() {
		showUndefinedSpinner()
		print("tag did connect")
	}
	
	func tagLost() {
		switchInfoScreen(to: .howToScan, animated: true)
		print("tag lost")
	}
	
	func wrongCard(message: String?) {
		playError()
		
		if let message = message {
			let oldMessage = reader.alertMessage
			showAlertMessage(message)
			DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
				self.showAlertMessage(oldMessage)
			}
		}
	}
	
	func sessionStarted() {
		print("Session started")
		infoScreenAppearWork = DispatchWorkItem(block: {
			self.showInfoScreen()
		})
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: infoScreenAppearWork!)
		startHapticsEngine()
	}
	
	func sessionInitialized() {
		print("Session initialized")
		playSuccess()
	}
	
	func sessionStopped() {
		print("Session stopped")
		infoScreenAppearWork?.cancel()
        pinMessage = nil
		dismissInfoScreen()
		stopHapticsEngine()
	}
	
	func showInfoScreen() {
		switchInfoScreen(to: .howToScan, animated: false)
	}
	
	private func presentInfoScreen() {
		DispatchQueue.main.async {
			guard
				self.infoScreen.presentingViewController == nil,
				!self.infoScreen.isBeingPresented,
				let topmostViewController = UIApplication.shared.topMostViewController,
				!(topmostViewController is PinViewController || topmostViewController is ChangePinViewController)
			else { return }
			
			topmostViewController.present(self.infoScreen, animated: true, completion: nil)
		}
	}
	
	private func dismissInfoScreen() {
		DispatchQueue.main.async {
			if self.infoScreen.presentedViewController != nil ||
				self.infoScreen.presentingViewController == nil ||
				self.infoScreen.isBeingDismissed {
				return
			}
			
			self.infoScreen.dismiss(animated: true, completion: nil)
		}
	}
	
	private func switchInfoScreen(to state: InformationScreenViewController.State, animated: Bool = true) {
		infoScreen.setState(state, animated: animated)
		presentInfoScreen()
	}
	
	private func requestPin(_ state: PinViewControllerState, cardId: String?, completion: @escaping (String?) -> Void) {
		let storyBoard = UIStoryboard(name: "PinStoryboard", bundle: .sdkBundle)
		let vc = storyBoard.instantiateViewController(identifier: "PinViewController", creator: { coder in
			return PinViewController(coder: coder, state: state, cardId: cardId, completionHandler: completion)
		})
		if let topmostViewController = UIApplication.shared.topMostViewController {
			vc.modalPresentationStyle = .fullScreen
			infoScreenAppearWork?.cancel()
			topmostViewController.present(vc, animated: true, completion: nil)
		} else {
			completion(nil)
		}
	}
	
	private func requestChangePin(_ state: PinViewControllerState, cardId: String?, completion: @escaping CompletionResult<(currentPin: String, newPin: String)>) {
		let storyBoard = UIStoryboard(name: "PinStoryboard", bundle: .sdkBundle)
		let vc = storyBoard.instantiateViewController(identifier: "ChangePinViewController", creator: { coder in
			return  ChangePinViewController(coder: coder, state: state, cardId: cardId, completionHandler: completion)
		})
		if let topmostViewController = UIApplication.shared.topMostViewController {
			vc.modalPresentationStyle = .fullScreen
			infoScreenAppearWork?.cancel()
			topmostViewController.present(vc, animated: true, completion: nil)
		} else {
			completion(.failure(.unknownError))
		}
	}
	
	private func playSuccess() {
		if supportsHaptics {
			do {
				
				guard let path = Bundle.sdkBundle.path(forResource: "Success", ofType: "ahap") else {
					return
				}
				
				try engine?.playPattern(from: URL(fileURLWithPath: path))
			} catch let error {
				print("Error creating a haptic transient pattern: \(error)")
			}
		}
	}
	
	private func playError() {
		if supportsHaptics {
			do {
				guard let path = Bundle.sdkBundle.path(forResource: "Error", ofType: "ahap") else {
					return
				}
				
				try engine?.playPattern(from: URL(fileURLWithPath: path))
			} catch let error {
				print("Error creating a haptic transient pattern: \(error)")
			}
		} else {
			let notificationGenerator = UINotificationFeedbackGenerator()
			notificationGenerator.notificationOccurred(.error)
		}
	}
	
	private func playTick() {
		if supportsHaptics {
			do {
				// Create an event (static) parameter to represent the haptic's intensity.
				let intensityParameter = CHHapticEventParameter(parameterID: .hapticIntensity,
																value: 0.75)
				
				// Create an event (static) parameter to represent the haptic's sharpness.
				let sharpnessParameter = CHHapticEventParameter(parameterID: .hapticSharpness,
																value: 0.5)
				
				// Create an event to represent the transient haptic pattern.
				let event = CHHapticEvent(eventType: .hapticTransient,
										  parameters: [intensityParameter, sharpnessParameter],
										  relativeTime: 0)
				
				let pattern = try CHHapticPattern(events: [event], parameters: [])
				
				// Create a player to play the haptic pattern.
				let player = try engine?.makePlayer(with: pattern)
				try player?.start(atTime: CHHapticTimeImmediate) // Play now.
			} catch let error {
				print("Error creating a haptic transient pattern: \(error)")
			}
		} else {
			let generator = UIImpactFeedbackGenerator(style: UIImpactFeedbackGenerator.FeedbackStyle.light)
			generator.impactOccurred()
		}
	}
	
	private func stopHapticsEngine() {
		guard supportsHaptics else {
			return
		}
		
		engine?.stop(completionHandler: {[weak self] error in
			if let error = error {
				print("Haptic Engine Shutdown Error: \(error)")
				return
			}
			self?.engineNeedsStart = true
		})
	}
	
	private func startHapticsEngine() {
		guard supportsHaptics && engineNeedsStart else {
			return
		}
		
		engine?.start(completionHandler: {[weak self] error in
			if let error = error {
				print("Haptic Engine Start Error: \(error)")
				return
			}
			self?.engineNeedsStart = false
		})
	}
	
	private func createHapticEngine() {
		guard supportsHaptics else {
			return
		}
		
		do {
			engine = try CHHapticEngine()
			engine!.playsHapticsOnly = true
			engine!.stoppedHandler = {[weak self] reason in
				print("CHHapticEngine stop handler: The engine stopped for reason: \(reason.rawValue)")
				self?.engineNeedsStart = true
			}
			engine!.resetHandler = {[weak self] in
				print("Reset Handler: Restarting the engine.")
				do {
					// Try restarting the engine.
					try self?.engine?.start()
					
					// Indicate that the next time the app requires a haptic, the app doesn't need to call engine.start().
					self?.engineNeedsStart = false
					
				} catch {
					print("Failed to start the engine")
				}
			}
		} catch {
			print("CHHapticEngine error: \(error)")
		}
	}
}
