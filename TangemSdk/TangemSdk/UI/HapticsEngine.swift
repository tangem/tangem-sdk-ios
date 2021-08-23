//
//  HapticsEngine.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 28.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import CoreHaptics
import UIKit

@available(iOS 13.0, *)
class HapticsEngine {
    private var engine: CHHapticEngine?
    private var engineNeedsStart = true
    
    private lazy var supportsHaptics: Bool = {
        return CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }()
    
    func playSuccess() {
        if supportsHaptics {
            do {
                
                guard let path = Bundle.sdkBundle.path(forResource: "Success", ofType: "ahap") else {
                    return
                }
                
                try engine?.playPattern(from: URL(fileURLWithPath: path))
            } catch let error {
                Log.error("Error creating a haptic transient pattern: \(error)")
            }
        }
    }
    
    func playError() {
        if supportsHaptics {
            do {
                guard let path = Bundle.sdkBundle.path(forResource: "Error", ofType: "ahap") else {
                    return
                }
                
                try engine?.playPattern(from: URL(fileURLWithPath: path))
            } catch let error {
                Log.error("Error creating a haptic transient pattern: \(error)")
            }
        } else {
            let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.notificationOccurred(.error)
        }
    }
    
    func playTick() {
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
                Log.error("Error creating a haptic transient pattern: \(error)")
            }
        } else {
            let generator = UIImpactFeedbackGenerator(style: UIImpactFeedbackGenerator.FeedbackStyle.light)
            generator.impactOccurred()
        }
    }
    
    func stop() {
        guard supportsHaptics else {
            return
        }
        
        engine?.stop(completionHandler: {[weak self] error in
            if let error = error {
                Log.error("Haptic Engine Shutdown Error: \(error)")
                return
            }
            self?.engineNeedsStart = true
        })
    }
    
    func start() {
        guard supportsHaptics && engineNeedsStart else {
            return
        }
        
        engine?.start(completionHandler: {[weak self] error in
            if let error = error {
                Log.error("Haptic Engine Start Error: \(error)")
                return
            }
            self?.engineNeedsStart = false
        })
    }
    
    func create() {
        guard supportsHaptics else {
            return
        }
        
        do {
            engine = try CHHapticEngine()
            engine!.playsHapticsOnly = true
            engine!.stoppedHandler = {[weak self] reason in
                Log.debug("CHHapticEngine stop handler: The engine stopped for reason: \(reason.rawValue)")
                self?.engineNeedsStart = true
            }
            engine!.resetHandler = {[weak self] in
                Log.debug("Reset Handler: Restarting the engine.")
                do {
                    // Try restarting the engine.
                    try self?.engine?.start()
                    
                    // Indicate that the next time the app requires a haptic, the app doesn't need to call engine.start().
                    self?.engineNeedsStart = false
                    
                } catch {
                    Log.error("Failed to start the engine with error: \(error)")
                }
            }
        } catch {
            Log.error("CHHapticEngine error: \(error)")
        }
    }
}
