//
//  Secp256r1Utils.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

@available(iOS 13.0, *)
class Secp256r1Utils {
    func isPrivateKeyValid(_ privateKey: Data) -> Bool {
        let key = try? P256.Signing.PrivateKey(rawRepresentation: privateKey)
        return key != nil
    }
}
