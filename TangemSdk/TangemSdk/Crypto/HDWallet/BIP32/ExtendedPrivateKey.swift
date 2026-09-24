//
//  ExtendedPrivateKey.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import CryptoKit
import Foundation

/// BIP32 extended private key
public struct ExtendedPrivateKey: Equatable, Hashable, JSONStringConvertible, Codable {
    public let privateKey: Data
    public let chainCode: Data

    public let depth: Int
    public let parentFingerprint: Data
    public let childNumber: UInt32

    public init(privateKey: Data, chainCode: Data, depth: Int, parentFingerprint: Data, childNumber: UInt32) throws {
        self.privateKey = privateKey
        self.chainCode = chainCode
        self.depth = depth
        self.parentFingerprint = parentFingerprint
        self.childNumber = childNumber

        if depth == 0, parentFingerprint.contains(where: { $0 != 0 }) || childNumber != 0 {
            throw ExtendedKeySerializationError.wrongKey
        }
    }

    /// The master key
    /// - Parameters:
    ///   - privateKey: privateKey
    ///   - chainCode: chainCode
    public init(privateKey: Data, chainCode: Data) {
        self.privateKey = privateKey
        self.chainCode = chainCode
        depth = 0
        parentFingerprint = Data(hexString: "0x00000000")
        childNumber = 0
    }

    /// This function performs CKDpriv((kpar, cpar), i) → (ki, ci) to compute a child extended private key from the parent extended private key.
    ///  It is defined for both hardened and non-hardened child keys. `secp256k1` only.
    ///  In case the derived key is invalid, the derivation proceeds with the next index, as required by BIP32.
    public func derivePrivateKey(node: DerivationNode) throws -> ExtendedPrivateKey {
        let secp256k1 = Secp256k1Utils()

        guard secp256k1.isPrivateKeyValid(privateKey) else {
            throw TangemSdkError.unsupportedCurve
        }

        let publicKey = try secp256k1.createPublicKey(privateKey: privateKey, compressed: true)

        return try BIP32.deriveWithRetry(from: node.index) { index in
            // let I = HMAC-SHA512(Key = cpar, Data = 0x00 || ser256(kpar) || ser32(i)) for hardened keys
            // let I = HMAC-SHA512(Key = cpar, Data = serP(point(kpar)) || ser32(i)) for non-hardened keys
            let data = index >= BIP32.Constants.hardenedOffset ? Data(UInt8(0)) + privateKey + index.bytes4 : publicKey + index.bytes4
            let hmac = HMAC<SHA512>.authenticationCode(for: data, using: SymmetricKey(data: chainCode))

            return try makeChildKey(digest: Data(hmac), index: index, parentPublicKey: publicKey, secp256k1: secp256k1)
        }
    }

    /// This function performs CKDpriv((kpar, cpar), i) → (ki, ci) to compute a child extended private key from the parent extended private key.
    ///  It is defined for both hardened and non-hardened child keys. `secp256k1` only.
    ///  In case the derived key is invalid, the derivation proceeds with the next index, as required by BIP32.
    public func derivePrivateKey(path derivationPath: DerivationPath) throws -> ExtendedPrivateKey {
        var key: ExtendedPrivateKey = self

        for node in derivationPath.nodes {
            key = try key.derivePrivateKey(node: node)
        }

        return key
    }

    func makeChildKey(digest: Data, index: UInt32, parentPublicKey: Data, secp256k1: Secp256k1Utils = Secp256k1Utils()) throws -> ExtendedPrivateKey {
        let derivedPrivateKey: Data

        do {
            derivedPrivateKey = try secp256k1.tweakAdd(privateKey: privateKey, tweak: digest[0 ..< 32])
        } catch {
            // BIP32: parse256(IL) ≥ n or ki = 0
            throw HDWalletError.invalidChildKey
        }

        return try ExtendedPrivateKey(
            privateKey: derivedPrivateKey,
            chainCode: digest[32 ..< 64],
            depth: depth + 1,
            parentFingerprint: parentPublicKey.sha256Ripemd160.prefix(4),
            childNumber: index
        )
    }

    public func makePublicKey(for curve: EllipticCurve) throws -> ExtendedPublicKey {
        let publicKey = try CryptoUtils.makePublicKey(from: privateKey, curve: curve)

        return try ExtendedPublicKey(
            publicKey: publicKey,
            chainCode: chainCode,
            depth: depth,
            parentFingerprint: parentFingerprint,
            childNumber: childNumber
        )
    }

    public func serializeToWIFCompressed(for networkType: NetworkType) -> String {
        return WIF.encodeToWIFCompressed(privateKey, networkType: networkType)
    }

    public func sign(_ data: Data, curve: EllipticCurve) throws -> Data {
        return try data.sign(privateKey: privateKey, curve: curve)
    }
}

// MARK: - ExtendedKeySerializable

extension ExtendedPrivateKey: ExtendedKeySerializable {
    public init(from extendedKeyString: String, networkType: NetworkType) throws {
        guard let data = extendedKeyString.base58CheckDecodedData else {
            throw ExtendedKeySerializationError.decodingFailed
        }

        guard data.count == ExtendedKeySerializer.Constants.dataLength else {
            throw ExtendedKeySerializationError.wrongLength
        }

        let decodedVersion = UInt32(data.prefix(4).toInt()!) // it's safe to force unwrap here, because of size

        let version = ExtendedKeySerializer.Version.private

        guard decodedVersion == version.getPrefix(for: networkType) else {
            throw ExtendedKeySerializationError.wrongVersion
        }

        let depth = data.dropFirst(4).prefix(1).toInt()! // it's safe to force unwrap here, because of size
        let parentFingerprint = data.dropFirst(5).prefix(4)
        let childNumber = UInt32(data.dropFirst(9).prefix(4).toInt()!) // it's safe to force unwrap here, because of size
        let chainCode = data.dropFirst(13).prefix(32)
        let privateKey = data.suffix(32)
        let prefix = data.dropFirst(45).prefix(1)

        guard prefix == Data(UInt8(0)) else {
            throw ExtendedKeySerializationError.decodingFailed
        }

        guard Secp256k1Utils().isPrivateKeyValid(privateKey) else {
            throw TangemSdkError.unsupportedCurve
        }

        try self.init(
            privateKey: privateKey,
            chainCode: chainCode,
            depth: depth,
            parentFingerprint: parentFingerprint,
            childNumber: childNumber
        )
    }

    public func serialize(for networkType: NetworkType) throws -> String {
        var data = Data(capacity: ExtendedKeySerializer.Constants.dataLength)

        let version = ExtendedKeySerializer.Version.private

        data += version.getPrefix(for: networkType).bytes4
        data += depth.byte
        data += parentFingerprint
        data += childNumber.bytes4
        data += chainCode
        data += Data(UInt8(0)) + privateKey

        guard data.count == ExtendedKeySerializer.Constants.dataLength else {
            throw ExtendedKeySerializationError.wrongLength
        }

        let resultString = Array(data).base58CheckEncodedString
        return resultString
    }
}
