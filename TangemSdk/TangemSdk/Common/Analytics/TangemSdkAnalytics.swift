//
//  TangemSdkAnalytics.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
public protocol TangemSdkSupportHandler: AnyObject, Sendable {
    func openSupport(from screen: TangemSdkScreen)
}

@MainActor
public protocol TangemSdkAnalyticsHandler: AnyObject, Sendable {
    func log(_ event: TangemSdkAnalyticsEvent)
}

public enum TangemSdkScreen: Equatable, Sendable {
    case enterAccessCode
    case resetCodesIntro
    case resetCodesNewCode
    case resetCodesScanResetCard
    case resetCodesScanConfirmationCard
    case resetCodesWriteResetCard
    case resetCodesSuccess
}

public enum TangemSdkButton: Equatable, Sendable {
    case `continue`
    case finish
    case forgotCode
    case support
    case close
}

public enum TangemSdkAnalyticsEvent: Equatable, Sendable {
    case screenOpened(TangemSdkScreen)
    case buttonTapped(TangemSdkButton, screen: TangemSdkScreen)
    case resetCodesFinished
    case resetCodesFailed(errorCode: Int)
}
