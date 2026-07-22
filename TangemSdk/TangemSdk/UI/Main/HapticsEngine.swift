//
//  HapticsEngine.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 28.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import CoreHaptics

final class HapticsEngine {
    /// `CHHapticEngine` doesn't depend on the SDK config, so a single engine is shared
    /// by all `TangemSdk` instances in the process.
    static let shared = HapticsEngine()

    /// Serial queue confining the engine life cycle and playback. Keeps `.ahap` file I/O
    /// and engine creation off the caller's (usually main) thread.
    private let queue = DispatchQueue(label: "com.tangem.TangemSdk.HapticsEngine", qos: .userInitiated)
    private let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    private var engine: CHHapticEngine?
    private var engineNeedsStart = true

    /// Cached because ticks fire once a second during security delays. Recreated after
    /// a haptic server reset, as Apple's reset-handler guidance requires.
    private var tickPlayer: CHHapticPatternPlayer?

    private init() {}

    func playSuccess() {
        playPattern(fromResource: "Success")
    }

    func playError() {
        playPattern(fromResource: "Error")
    }

    func playTick() {
        guard supportsHaptics else {
            return
        }

        queue.async {
            guard self.startEngineIfNeeded() else {
                return
            }

            do {
                try self.tickPlayerIfAvailable()?.start(atTime: CHHapticTimeImmediate)
            } catch {
                Log.error("Failed to play the tick pattern: \(error)")
            }
        }
    }

    func start() {
        guard supportsHaptics else {
            return
        }

        queue.async {
            self.createEngineIfNeeded()
            self.startEngineIfNeeded()
        }
    }

    func stop() {
        guard supportsHaptics else {
            return
        }

        queue.async {
            self.engine?.stop(completionHandler: { error in
                if let error = error {
                    Log.error("Haptic Engine Shutdown Error: \(error)")
                }
            })
            // Set synchronously rather than in the async completion: a start() enqueued
            // right after stop() must see the flag, or the next session runs with a
            // stopped engine. If stop actually fails, the redundant start() is harmless.
            self.engineNeedsStart = true
        }
    }

    /// Must be called on `queue`. A failed creation isn't retried until the next
    /// session start, so an unavailable haptic server costs at most one attempt
    /// and one log line per NFC session.
    private func createEngineIfNeeded() {
        guard engine == nil else {
            return
        }

        do {
            let engine = try CHHapticEngine()
            engine.playsHapticsOnly = true
            // Apple requires the handlers to be set before the engine is started.
            configureHandlers(of: engine)
            self.engine = engine
        } catch {
            Log.error("Engine Creation Error: \(error)")
        }
    }

    private func configureHandlers(of engine: CHHapticEngine) {
        // An external stop (interruption, suspension) is a normal part of the engine
        // life cycle, not an error; the engine is restarted on the next use.
        engine.stoppedHandler = { [weak self] reason in
            Log.debug("Stop Handler: The engine stopped for reason: \(reason.logDescription)")
            self?.queue.async {
                self?.engineNeedsStart = true
            }
        }

        engine.resetHandler = { [weak self] in
            Log.debug("Reset Handler: Restarting the engine.")
            self?.queue.async {
                guard let self = self else {
                    return
                }

                self.tickPlayer = nil
                let wasRunning = !self.engineNeedsStart
                self.engineNeedsStart = true

                if wasRunning {
                    self.startEngineIfNeeded()
                }
            }
        }
    }

    /// Must be called on `queue`. Starts the engine in case it's idle, as Apple
    /// recommends before playback. Returns `true` if the engine is running.
    @discardableResult
    private func startEngineIfNeeded() -> Bool {
        guard let engine = engine else {
            return false
        }

        guard engineNeedsStart else {
            return true
        }

        do {
            try engine.start()
            engineNeedsStart = false
            return true
        } catch {
            Log.error("Haptic Engine Start Error: \(error)")
            return false
        }
    }

    /// Must be called on `queue`.
    private func tickPlayerIfAvailable() throws -> CHHapticPatternPlayer? {
        if let tickPlayer = tickPlayer {
            return tickPlayer
        }

        guard let engine = engine else {
            return nil
        }

        let intensityParameter = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.75)
        let sharpnessParameter = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensityParameter, sharpnessParameter],
            relativeTime: 0
        )
        let pattern = try CHHapticPattern(events: [event], parameters: [])

        let player = try engine.makePlayer(with: pattern)
        tickPlayer = player
        return player
    }

    private func playPattern(fromResource resource: String) {
        guard supportsHaptics else {
            return
        }

        queue.async {
            guard self.startEngineIfNeeded() else {
                return
            }

            do {
                let filePath = self.filePath(forResource: resource)

                guard let path = Bundle.sdkBundle.path(forResource: filePath, ofType: "ahap") else {
                    Log.error("Missing haptic pattern resource: \(filePath).ahap")
                    return
                }

                try self.engine?.playPattern(from: URL(fileURLWithPath: path))
            } catch {
                Log.error("Failed to play the \(resource) pattern: \(error)")
            }
        }
    }

    /// SPM preserves folder structure for resources, unlike Cocoapods.
    /// Therefore, a full file path with all intermediate directories must be constructed.
    private func filePath(forResource resource: String) -> String {
        #if SWIFT_PACKAGE
        return [
            "Haptics",
            resource,
        ].joined(separator: "/")
        #else
        return resource
        #endif // SWIFT_PACKAGE
    }
}

private extension CHHapticEngine.StoppedReason {
    var logDescription: String {
        switch self {
        case .audioSessionInterrupt:
            return "audio session interrupt"
        case .applicationSuspended:
            return "application suspended"
        case .idleTimeout:
            return "idle timeout"
        case .notifyWhenFinished:
            return "notify when finished"
        case .engineDestroyed:
            return "engine destroyed"
        case .gameControllerDisconnect:
            return "game controller disconnect"
        case .systemError:
            return "system error"
        @unknown default:
            return "unknown (\(rawValue))"
        }
    }
}
