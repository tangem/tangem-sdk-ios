//
//  ResponseApdu.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 27/09/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

/// Stores response data from the card and parses it to `Tlv` and `StatusWord`.
public struct ResponseApdu {
    /// Status word code, reflecting the status of the response
    public var sw: UInt16 { return UInt16( (UInt16(sw1) << 8) | UInt16(sw2) ) }
    /// Parsed status word.
    public var statusWord: StatusWord { return StatusWord(rawValue: sw) ?? .unknown }

    let sw1: Byte
    let sw2: Byte
    let data: Data

    var swBytes: Data { Data([sw1, sw2]) }

    public init(_ data: Data, _ sw1: Byte, _ sw2: Byte) {
        self.sw1 = sw1
        self.sw2 = sw2
        self.data = data
    }

    /// Converts raw response data  to the array of TLVs.
    public func getTlvData() -> [Tlv]? {
        guard let tlv = Tlv.deserialize(data) else { // Initialize TLV array with raw data from card response
            return nil
        }

        return tlv
    }

    /// Decrypts the response APDU data using AES-CBC encryption.
    /// - Parameter encryptionKey: The key used for decryption. If nil, returns the original APDU.
    /// - Throws: `TangemSdkError.invalidResponseApdu` if decryption fails or data integrity check fails.
    /// - Returns: A new `ResponseApdu` with decrypted payload data.
    func decrypt(encryptionKey: Data?) throws -> ResponseApdu {
        guard let encryptionKey else {
            return self
        }

        if data.isEmpty { //error response. nothing to decrypt
            return self
        }

        if data.count < 16 { //not encrypted response. nothing to decrypt
            return self
        }

        let decryptedData = try data.decrypt(with: encryptionKey)
        guard decryptedData.count >= 4 else {
            throw TangemSdkError.invalidResponseApdu
        }

        let length = decryptedData[0...1].toInt()
        let crc = decryptedData[2...3]
        let payload = decryptedData[4...]

        guard length == payload.count, crc == payload.crc16() else {
            throw TangemSdkError.invalidResponseApdu
        }

        return ResponseApdu(payload, self.sw1, self.sw2)
    }

    /// Decrypts the response APDU data using AES-CCM encryption.
    /// - Parameters:
    ///   - encryptionKey: The key used for decryption. If nil, returns the original APDU.
    ///   - nonce: The nonce (initialization vector) used for CCM decryption.
    /// - Throws: `TangemSdkError.invalidResponseApdu` if data is too short for decryption.
    /// - Returns: A new `ResponseApdu` with decrypted payload data.
    func decryptCcm(encryptionKey: Data?, nonce: Data) throws -> ResponseApdu {
        guard let encryptionKey else {
            return self
        }

        if data.isEmpty { //error response. nothing to decrypt
            return self
        }

        // minimum length of AES-CCM encrypted data is 8 bytes (authentication tag)
        guard data.count >= 8 else {
            throw TangemSdkError.invalidResponseApdu
        }

        let payload = try data.decryptAESCCM(
            with: encryptionKey,
            iv: nonce,
            additionalAuthenticatedData: swBytes
        )

        return ResponseApdu(payload, self.sw1, self.sw2)
    }
}

extension ResponseApdu: CustomStringConvertible {
    public var description: String {
        return "<-- RECEIVED [\(data.count + 2) bytes]: *** \(sw1) \(sw2) (SW: \(statusWord))"
    }
}
