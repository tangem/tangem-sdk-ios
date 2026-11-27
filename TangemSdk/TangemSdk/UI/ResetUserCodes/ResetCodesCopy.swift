//
//  ResetCodesCopy.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct ResetCodesCopy {
    let type: UserCodeType
    let cardId: String?

    private var deviceNumber: String? {
        cardId.flatMap { $0.isEmpty ? nil : $0.replacingOccurrences(of: " ", with: "\u{00A0}") }
    }

    var newCodeTitle: String {
        switch type {
        case .accessCode:
            return "reset_codes_new_code_title".localized
        case .passcode:
            return type.enterNewCodeTitle
        }
    }

    var newCodeSubtitle: String {
        withDeviceNumber("reset_codes_new_code_subtitle_format", fallback: "reset_codes_new_code_subtitle")
    }

    var codePlaceholder: String {
        switch type {
        case .accessCode:
            return "reset_codes_new_code_placeholder".localized
        case .passcode:
            return type.name
        }
    }

    var confirmationPlaceholder: String {
        switch type {
        case .accessCode:
            return "reset_codes_new_code_confirm_placeholder".localized
        case .passcode:
            return type.confirmCodeTitle
        }
    }

    var successTitle: String {
        switch type {
        case .accessCode:
            return "reset_codes_success_title".localized
        case .passcode:
            return "common_success".localized
        }
    }

    var successBody: String {
        withDeviceNumber("reset_codes_success_body_format", fallback: "reset_codes_success_body")
    }

    func stepTitle(for state: ResetPinService.State) -> String {
        switch state {
        case .needScanResetCard:
            return withDeviceNumber("reset_codes_prepare_device_title_format", fallback: "reset_codes_prepare_device_title")
        case .needScanConfirmationCard:
            return "reset_codes_prepare_backup_title".localized
        case .needWriteResetCard:
            return withDeviceNumber("reset_codes_prepare_device_again_title_format", fallback: "reset_codes_prepare_device_again_title")
        case .needCode, .finished:
            return ""
        }
    }

    func stepBody(for state: ResetPinService.State) -> String {
        switch state {
        case .needScanResetCard, .needWriteResetCard:
            return type == .accessCode ? "reset_codes_prepare_device_body".localized : ""
        case .needScanConfirmationCard:
            return "reset_codes_prepare_backup_body".localized
        case .needCode, .finished:
            return ""
        }
    }

    private func withDeviceNumber(_ formatKey: String, fallback key: String) -> String {
        guard let deviceNumber else {
            return key.localized
        }

        return formatKey.localized(deviceNumber)
    }
}
