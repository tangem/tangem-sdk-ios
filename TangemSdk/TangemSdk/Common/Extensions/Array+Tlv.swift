//
//  Array+Tlv.swift
//  TangemSdk
//
//  Created by Andrew Son on 22/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public extension Array where Element == Tlv {
    /// Serialize array of tlv items to Data
    /// - Parameter array: tlv array
    func serialize() -> Data {
        return Data(reduce([]) { $0 + $1.serialize() })
    }

    /// Convenience getter for tlv item
    /// - Parameter tag: tag to find
    func item(for tag: TlvTag) -> Element? {
        first(where: { $0.tag == tag })
    }

    /// Convenience getter for tlv
    /// - Parameter tag: tag to find
    func value(for tag: TlvTag) -> Data? {
        item(for: tag)?.value
    }

    /// - Parameter tag: tag to check
    func contains(tag: TlvTag) -> Bool {
        value(for: tag) != nil
    }

    /// Convenience getter for multiple tlvs with same tag
    /// - Parameter tag: tag to find
    func items(for tag: TlvTag) -> [Element] {
        filter { $0.tag == tag }
    }
}
