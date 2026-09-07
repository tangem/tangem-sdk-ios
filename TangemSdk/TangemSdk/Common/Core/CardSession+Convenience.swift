//
//  CardSession+Convenience.swift
//  TangemSdk
//
//  Created by Andrey Fedorov on 07.09.2026.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public extension CardSession {
    func pauseIfNeeded(message: String) {
        guard !reader.isPaused else {
            return
        }

        viewDelegate.showAlertMessage(message)
        reader.pauseSession()
    }

    func pauseIfNeeded(error: TangemSdkError? = nil) {
        guard !reader.isPaused else {
            return
        }

        reader.pauseSession(with: error?.localizedDescription)
    }

    func resumeIfNeeded() {
        guard reader.isPaused else {
            return
        }

        reader.resumeSession()
    }
}
