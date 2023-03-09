//
//  ExtendedPrivateKey.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 07.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
/// BIP32 extended private key
public struct ExtendedPrivateKey: Equatable, Hashable, JSONStringConvertible, Codable {
    public let privateKey: Data
    public let chainCode: Data

    public init(privateKey: Data, chainCode: Data) {
        self.privateKey = privateKey
        self.chainCode = chainCode
    }
}
