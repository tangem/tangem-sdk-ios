//
//  CardSession+Notification.swift
//  TangemSdk
//
//  Created by Aleksei Lobankov on 05.08.2025.
//

import struct Foundation.Notification

extension Notification.Name {
    /// Posted when a card session starts.
    public static let cardSessionDidStart = Notification.Name("com.tangem-sdk-ios.CardSessionDidStart")

    /// Posted when a card session finishes, whether successfully or due to a failure.
    public static let cardSessionDidFinish = Notification.Name("com.tangem-sdk-ios.CardSessionDidFinish")
}
