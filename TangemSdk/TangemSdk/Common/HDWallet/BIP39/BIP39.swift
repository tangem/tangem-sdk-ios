//
//  BIP39.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 06.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public struct BIP39 {
    /// Generate a mnemonic.
    /// - Parameters:
    ///   - entropyLength: An  entropy length to use. Default is 128 bit.
    ///   - wordlist: A wordlist to use. Default is english.
    /// - Returns: Generated mnemonic
    public func generateMnemonic(entropyLength: EntropyLength = .bits128, wordlist: Wordlist = .en) throws -> [String] {
        guard entropyLength.rawValue % 32 == 0 else {
            throw MnemonicError.mnenmonicCreationFailed
        }

        let entropyBytesCount = entropyLength.rawValue / 8
        let entropyData = try CryptoUtils.generateRandomBytes(count: entropyBytesCount)
        return try generateMnemonic(from: entropyData, wordlist: wordlist)
    }

    /// Generate a mnemonic from data. Useful for testing purposes.
    /// - Parameters:
    ///   - data: Entropy data in hex format
    ///   - wordlist: A wordlist to use.
    /// - Returns: Generated mnemonic
    func generateMnemonic(from entropyData: Data, wordlist: Wordlist) throws -> [String] {
        guard let entropyLength = EntropyLength(rawValue: entropyData.count * 8) else {
            throw MnemonicError.invalidEntropyLength
        }

        let entropyHashBits = entropyData.getSha256().toBits()
        let checksumBitLength = entropyLength.rawValue / 32
        let entropyChecksumBits = entropyHashBits.prefix(checksumBitLength)

        let entropyBits = entropyData.toBits()
        let concatenatedBits = entropyBits + entropyChecksumBits
        let bitIndexes = concatenatedBits.chunked(into: 11)
        let indexes = bitIndexes.compactMap { Int($0.joined(), radix: 2) }

        guard indexes.count == entropyLength.wordsCount else {
            throw MnemonicError.mnenmonicCreationFailed
        }

        let allWords = wordlist.words
        let maxWordIndex = allWords.count

        guard indexes.allSatisfy({ $0 < maxWordIndex }) else {
            throw MnemonicError.mnenmonicCreationFailed
        }

        let words = indexes.map { allWords[$0] }
        return words
    }
}
