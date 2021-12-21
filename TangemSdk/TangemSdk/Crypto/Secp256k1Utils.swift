//
//  Secp256k1Utils.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 07.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk_secp256k1

@available(iOS 13.0, *)
public final class Secp256k1Utils {
    static let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN|SECP256K1_CONTEXT_VERIFY))
    
    deinit {
        secp256k1_context_destroy(Secp256k1Utils.context)
    }
    
    public static func verify(signature: Data, publicKey: Data, message: Data) throws -> Bool {
        return try verify(signature: signature, publicKey: publicKey, hash: message.getSha256())
    }
    
    public static func verify(signature: Data, publicKey: Data, hash: Data) throws -> Bool {
        guard let ctx = context else { throw TangemSdkError.cryptoUtilsError("Failed to create the context") }
        
        var pubKey = try parsePublicKey(publicKey)
        var normalizedSig = try parseNormalize(signature)
        
        guard secp256k1_ecdsa_verify(ctx, &normalizedSig, hash.toBytes, &pubKey) == 1 else {
            return false
        }
        
        return true
    }
    
    /**
     * Extension function to sign a byte array with the `Secp256k1` elliptic curve cryptography.
     *
     * - Parameter key: Key to sign data
     * - Parameter data: Data to sign
     *
     * - Returns: Signed data
     */
    public static func sign(_ data: Data, with key: Data) throws -> Data {
        guard let ctx = context else { throw TangemSdkError.cryptoUtilsError("Failed to create the context") }
        
        var signature = secp256k1_ecdsa_signature()
        guard secp256k1_ecdsa_sign(ctx, &signature, Array(data.getSha256()), Array(key), nil, nil) == 1 else {
            throw TangemSdkError.cryptoUtilsError("Failed to sign")
        }
        
        var signatureData = [Byte](repeating: 0, count: 64)
        _ = secp256k1_ecdsa_signature_serialize_compact(ctx, &signatureData, &signature)
        
        return Data(signatureData)
    }
    
    /// Generate private/public keypair with secp256k1.
    /// - Returns: `KeyPair` with  32-bytes length `private key` and  65-bytes length uncompressed `public key`
    public static func generateKeyPair() throws -> KeyPair {
        let privateKey = try CryptoUtils.generateRandomBytes(count: 32)
        let publicKey = try createPublicKey(privateKey: privateKey, compressed: false)
        return KeyPair(privateKey: privateKey, publicKey: publicKey)
    }
    
    public static func createPublicKey(privateKey: Data, compressed: Bool) throws -> Data {
        guard let ctx = context else { throw TangemSdkError.cryptoUtilsError("Failed to create the context") }
        
        let privateKey = privateKey.toBytes
        var publicKey = secp256k1_pubkey()
        
        guard secp256k1_ec_seckey_verify(ctx, privateKey) == 1 else {
            throw TangemSdkError.cryptoUtilsError("Failed to verify the private key")
        }
        
        guard secp256k1_ec_pubkey_create(ctx, &publicKey, privateKey) == 1 else {
            throw TangemSdkError.cryptoUtilsError("Failed to create the public key")
        }
        
        return try serializePublicKey(publicKey: &publicKey, compressed: compressed)
    }
    
    public static func sum(compressedPubKey1: Data, compressedPubKey2: Data) throws -> Data {
        guard let ctx = context else { throw TangemSdkError.cryptoUtilsError("Failed to create the context") }

        var pubKey1 = try parsePublicKey(compressedPubKey1)
        var pubKey2 = try parsePublicKey(compressedPubKey2)
        var publicKeySecp = secp256k1_pubkey()
        var result: Int32 = 0
        
        withUnsafePointer(to: &pubKey1) { pointer1 in
            withUnsafePointer(to: &pubKey2) { pointer2 in
                var pubkeyPointers: [UnsafePointer<secp256k1_pubkey>?] = [pointer1, pointer2]
                
                result = secp256k1_ec_pubkey_combine(ctx, &publicKeySecp, &pubkeyPointers, 2)
            }
        }
       
        guard result == 1 else {
            throw TangemSdkError.cryptoUtilsError("Failed to sum keys")
        }

        return try serializePublicKey(publicKey: &publicKeySecp, compressed: true)
    }
    
    public static func serializeToDer(signature: Data) throws -> Data {
        guard let ctx = context else { throw TangemSdkError.cryptoUtilsError("Failed to create the context") }
        
        var normalizedSig = try parseNormalize(signature)
        var length: Int = 128
        var der = [UInt8].init(repeating: UInt8(0x0), count: Int(length))
        guard secp256k1_ecdsa_signature_serialize_der(ctx, &der, &length, &normalizedSig) == 1 else {
            throw TangemSdkError.cryptoUtilsError("Failed to serialize the signature")
        }
        
        return Data(der[0..<Int(length)])
    }
    
    public static func unmarshal(signature: Data, hash: Data, publicKey: Data) throws -> (v: Data, r: Data, s: Data) {
        guard try verify(signature: signature, publicKey: publicKey, hash: hash) else {
            throw TangemSdkError.cryptoUtilsError("Failed to verify the signature")
        }
        
        var recoveredSignature: Data? = nil
        
        for v in 27..<31 {
            let testV = UInt8(v)
            let testSign = Data(signature + [testV])
            let recoveredKey = try recoverPublicKey(hash: hash, signature: testSign, compressed: publicKey.count == 33)
            if recoveredKey == publicKey {
                recoveredSignature = testSign
                break
            }
        }
        
        guard let recovered = recoveredSignature, recovered.count == 65 else {
            throw TangemSdkError.cryptoUtilsError("Failed to recover the signature")
        }

        let v = Data([recovered[64]])
        let r = Data(recovered[0..<32])
        let s = Data(recovered[32..<64])
        return (v: v, r: r, s: s)
    }    
    
    public static func compressPublicKey(_ walletPublicKey: Data) throws -> Data {
        guard let ctx = context else { throw TangemSdkError.cryptoUtilsError("Failed to create the context") }
        
        //already compressed
        if walletPublicKey.count == 33 {
            return walletPublicKey
        }
        
        guard walletPublicKey.count == 65 else {
            throw TangemSdkError.cryptoUtilsError("Invalid key")
        }
        
        var pubkey = secp256k1_pubkey()
        guard secp256k1_ec_pubkey_parse(ctx, &pubkey, Array(walletPublicKey), 65) == 1 else { throw TangemSdkError.cryptoUtilsError("Failed to parse the key") }
        
        return try serializePublicKey(publicKey: &pubkey, compressed: true)
    }
    
    public static func decompressPublicKey(_ walletPublicKey: Data) throws -> Data {
        guard let ctx = context else { throw TangemSdkError.cryptoUtilsError("Failed to create the context") }
        
        //already decompressed
        if walletPublicKey.count == 65 {
            return walletPublicKey
        }
        
        guard walletPublicKey.count == 33 else {
            throw TangemSdkError.cryptoUtilsError("Invalid key")
        }
        
        var pubkey = secp256k1_pubkey()
        guard secp256k1_ec_pubkey_parse(ctx, &pubkey, Array(walletPublicKey), 33) == 1 else { throw TangemSdkError.cryptoUtilsError("Failed to parse the key") }
        
        return try serializePublicKey(publicKey: &pubkey, compressed: false)
    }
    
    public static func normalize(signature: Data) throws -> Data {
        guard let ctx = context else { throw TangemSdkError.cryptoUtilsError("Failed to create the context") }
        
        var sig = try parseSignature(signature)
        var normalized = secp256k1_ecdsa_signature()
        let result = secp256k1_ecdsa_signature_normalize(ctx, &normalized, &sig)
      
        if result == 0 { //already normalized
            return signature
        }
        
        var serialized = [UInt8].init(repeating: UInt8(0x0), count: 64)
        secp256k1_ecdsa_signature_serialize_compact(ctx, &serialized, &normalized)
        return Data(serialized)
    }
    
    public static func getSharedSecret(privateKey: Data, publicKey: Data) throws -> Data {
        guard let ctx = context else { throw TangemSdkError.cryptoUtilsError("Failed to create the context") }
        
        let privkey = privateKey.toBytes
        var pubkey = try parsePublicKey(publicKey)
        var sharedSecret = Array(repeating: UInt8(0), count: 32)
        guard secp256k1_ecdh(ctx, &sharedSecret, &pubkey, privkey, nil, nil) == 1 else {
            throw TangemSdkError.cryptoUtilsError("Failed to compute an EC Diffie-Hellman secret ")
        }
        
        return Data(sharedSecret)
    }
    
    private static func recoverPublicKey(hash: Data, recoverableSignature: inout secp256k1_ecdsa_recoverable_signature) throws -> secp256k1_pubkey {
        guard let ctx = context else { throw TangemSdkError.cryptoUtilsError("Failed to create the context") }
        
        guard hash.count == 32 else { throw TangemSdkError.cryptoUtilsError("Hash size must be 32 bytes length") }
        
        var publicKey: secp256k1_pubkey = secp256k1_pubkey()
        let result = hash.withUnsafeBytes({ (hashRawBufferPointer: UnsafeRawBufferPointer) -> Int32? in
            if let hashRawPointer = hashRawBufferPointer.baseAddress, !hashRawBufferPointer.isEmpty {
                let hashPointer = hashRawPointer.assumingMemoryBound(to: UInt8.self)
                return withUnsafePointer(to: &recoverableSignature, { (signaturePointer:UnsafePointer<secp256k1_ecdsa_recoverable_signature>) -> Int32 in
                    withUnsafeMutablePointer(to: &publicKey, { (pubKeyPtr: UnsafeMutablePointer<secp256k1_pubkey>) -> Int32 in
                        let res = secp256k1_ecdsa_recover(ctx, pubKeyPtr,
                                                          signaturePointer, hashPointer)
                        return res
                    })
                })
            } else {
                return nil
            }
        })
        
        guard let res = result, res != 0 else {
            throw TangemSdkError.cryptoUtilsError("Failed to recover the public key")
        }
        
        return publicKey
    }
    
    private static func serializePublicKey(publicKey: inout secp256k1_pubkey, compressed: Bool) throws -> Data {
        guard let ctx = context else { throw TangemSdkError.cryptoUtilsError("Failed to create the context") }
        
        var keyLength = compressed ? 33 : 65
        var serializedPubkey = Array(repeating: UInt8(0), count: Int(keyLength))
        
        secp256k1_ec_pubkey_serialize(ctx, &serializedPubkey,
                                      &keyLength,
                                      &publicKey,
                                      UInt32(compressed ? SECP256K1_EC_COMPRESSED : SECP256K1_EC_UNCOMPRESSED))
        
        return Data(serializedPubkey)
    }
    
    private static func serializeSignature(recoverableSignature: inout secp256k1_ecdsa_recoverable_signature) throws -> Data {
        guard let ctx = context else { throw TangemSdkError.cryptoUtilsError("Failed to create the context") }
        
        var serializedSignature = Data(repeating: 0x00, count: 64)
        var v: Int32 = 0
        let result = serializedSignature.withUnsafeMutableBytes { (serSignatureRawBufferPointer: UnsafeMutableRawBufferPointer) -> Int32? in
            if let serSignatureRawPointer = serSignatureRawBufferPointer.baseAddress, !serSignatureRawBufferPointer.isEmpty {
                let serSignaturePointer = serSignatureRawPointer.assumingMemoryBound(to: UInt8.self)
                return withUnsafePointer(to: &recoverableSignature) { (signaturePointer:UnsafePointer<secp256k1_ecdsa_recoverable_signature>) -> Int32 in
                    withUnsafeMutablePointer(to: &v, { (vPtr: UnsafeMutablePointer<Int32>) -> Int32 in
                        let res = secp256k1_ecdsa_recoverable_signature_serialize_compact(ctx, serSignaturePointer, vPtr, signaturePointer)
                        return res
                    })
                }
            } else {
                return nil
            }
        }
        
        guard let res = result, res != 0 else {
            throw TangemSdkError.cryptoUtilsError("Failed to serialize the signature")
        }
        
        if (v == 0 || v == 27 || v == 31 || v == 35) {
            serializedSignature.append(0x1b)
        } else if (v == 1 || v == 28 || v == 32 || v == 36) {
            serializedSignature.append(0x1c)
        } else {
            throw TangemSdkError.cryptoUtilsError("Failed to serialize the signature")
        }
        
        return Data(serializedSignature)
    }
    
    private static func parsePublicKey(_ publicKey: Data) throws -> secp256k1_pubkey {
        guard let ctx = context else { throw TangemSdkError.cryptoUtilsError("Failed to create the context") }
        
        var pubkey = secp256k1_pubkey()
        
        guard secp256k1_ec_pubkey_parse(ctx, &pubkey, publicKey.toBytes, publicKey.count) == 1 else {
            throw TangemSdkError.cryptoUtilsError("Failed to parse the key")
        }
        
        return pubkey
    }
    
    private static func parseSignature(_ signature: Data) throws -> secp256k1_ecdsa_signature {
        guard let ctx = context else { throw TangemSdkError.cryptoUtilsError("Failed to create the context") }
        
        var sig = secp256k1_ecdsa_signature()
        
        guard secp256k1_ecdsa_signature_parse_compact(ctx, &sig, signature.toBytes) == 1 else {
            throw TangemSdkError.cryptoUtilsError("Failed to parse the signature")
        }
        
        return sig
    }
    
    private static func parseNormalize(_ signature: Data) throws -> secp256k1_ecdsa_signature {
        guard let ctx = context else { throw TangemSdkError.cryptoUtilsError("Failed to create the context") }
        
        var sig = secp256k1_ecdsa_signature()
        
        guard secp256k1_ecdsa_signature_parse_compact(ctx, &sig, signature.toBytes) == 1 else {
            throw TangemSdkError.cryptoUtilsError("Failed to parse the signature")
        }
        
        var normalizedSig = secp256k1_ecdsa_signature()
        _ = secp256k1_ecdsa_signature_normalize(ctx, &normalizedSig, &sig)
        return normalizedSig
    }
    
    private static func recoverPublicKey(hash: Data, signature: Data, compressed: Bool = false) throws -> Data {
        guard hash.count == 32 else { throw TangemSdkError.cryptoUtilsError("Hash size must be 32 bytes length") }
        
        guard signature.count == 65 else { throw TangemSdkError.cryptoUtilsError("Invalid signature") }
        
        var recoverableSignature = try parseRecoverableSignature(signature: signature)
        var publicKey = try recoverPublicKey(hash: hash, recoverableSignature: &recoverableSignature)
        let serializedKey = try serializePublicKey(publicKey: &publicKey, compressed: compressed)
        return serializedKey
    }
    
    private static func parseRecoverableSignature(signature: Data) throws -> secp256k1_ecdsa_recoverable_signature {
        guard let ctx = context else { throw TangemSdkError.cryptoUtilsError("Failed to create the context") }
        
        guard signature.count == 65 else { throw TangemSdkError.cryptoUtilsError("Invalid signature") }
        
        var recoverableSignature: secp256k1_ecdsa_recoverable_signature = secp256k1_ecdsa_recoverable_signature()
        let serializedSignature = Data(signature[0..<64])
        var v = Int32(signature[64])
        if v >= 27 && v <= 30 {
            v -= 27
        } else if v >= 31 && v <= 34 {
            v -= 31
        } else if v >= 35 && v <= 38 {
            v -= 35
        }
        
        let result = serializedSignature.withUnsafeBytes { (serRawBufferPtr: UnsafeRawBufferPointer) -> Int32? in
            if let serRawPtr = serRawBufferPtr.baseAddress, !serRawBufferPtr.isEmpty {
                let serPtr = serRawPtr.assumingMemoryBound(to: UInt8.self)
                return withUnsafeMutablePointer(to: &recoverableSignature, { (signaturePointer:UnsafeMutablePointer<secp256k1_ecdsa_recoverable_signature>) -> Int32 in
                    let res = secp256k1_ecdsa_recoverable_signature_parse_compact(ctx, signaturePointer, serPtr, v)
                    return res
                })
            } else {
                return nil
            }
        }
        
        guard let res = result, res != 0 else {
            throw TangemSdkError.cryptoUtilsError("Failed to parse the recoverable signature")
        }
        
        return recoverableSignature
    }
}
