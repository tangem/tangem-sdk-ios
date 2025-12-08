//
//  CryptoSwiftUtils.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import CryptoSwift

public enum CryptoSwiftUtils {
    public static func encryptAESCCM(
        encryptionKey: Data,
        message: Data,
        iv: Data,
        additionalAuthenticatedData: Data,
        tagLength: Int = 8
    ) throws -> Data {
        let ccm = CCM(
            iv: iv.toBytes,
            tagLength: tagLength,
            messageLength: message.count,
            additionalAuthenticatedData: additionalAuthenticatedData.toBytes
        )

        let aes = try AES(key: encryptionKey.toBytes, blockMode: ccm, padding: .noPadding)
        let encrypted = try aes.encrypt(message.toBytes)
        return Data(encrypted)
    }

    public static func decryptAESCCM(
        encryptionKey: Data,
        encryptedMessage: Data,
        iv: Data,
        additionalAuthenticatedData: Data,
        tagLength: Int = 8
    ) throws -> Data {
        let authenticationTag = encryptedMessage.suffix(tagLength).toBytes

        let ccm = CCM(
            iv: iv.toBytes,
            tagLength: tagLength,
            messageLength: encryptedMessage.count - tagLength,
            authenticationTag: authenticationTag,
            additionalAuthenticatedData: additionalAuthenticatedData.toBytes
        )

        let aes = try AES(key: encryptionKey.toBytes, blockMode: ccm, padding: .noPadding)
        let decrypted = try aes.decrypt(encryptedMessage.toBytes)
        return Data(decrypted)
    }
}
