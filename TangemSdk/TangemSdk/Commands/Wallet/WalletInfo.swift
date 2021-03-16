//
//  WalletInfo.swift
//  TangemSdk
//
//  Created by Andrew Son on 16/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation


public struct WalletInfo: Codable {
    let index: Int
    let status: CardStatus
    var curve: EllipticCurve?
    var settingsMask: SettingsMask?
    var publicKey: Data?
    var signedHashes: Int?
    var userCounter: Int?
    var userProtectedCounter: Int?
}
