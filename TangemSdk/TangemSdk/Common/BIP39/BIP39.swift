//
//  BIP39.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 06.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
struct BIP39 {
    /// Generate a mnemonic.
    /// - Parameters:
    ///   - entropyLength: The  entropy length to use. Default is 128 bit.
    ///   - wordlist: The wordlist to use. Default is english.
    /// - Returns: The generated mnemonic splitted to components
    func generateMnemonic(entropyLength: EntropyLength = .bits128, wordlist: Wordlist = .en) throws -> [String] {
        guard entropyLength.rawValue % 32 == 0 else {
            throw MnemonicError.mnenmonicCreationFailed
        }

        let entropyBytesCount = entropyLength.rawValue / 8
        let entropyData = try CryptoUtils.generateRandomBytes(count: entropyBytesCount)
        return try generateMnemonic(from: entropyData, wordlist: wordlist)
    }

    /// Generate a determenistic  seed
    /// - Parameters:
    ///   - mnemonic: The mnemonic to use
    ///   - passphrase: The passphrase to use. Default is no passphrase (empty).
    /// - Returns: The generated seed
    func generateSeed(from mnemonicComponents: [String], passphrase: String = "") throws -> Data {
        try validate(mnemonicComponents: mnemonicComponents)

        let mnemonicString = convertToMnemonicString(mnemonicComponents)
        let normalizedMnemonic = try normalizedData(from: mnemonicString)
        let normalizedSalt = try normalizedData(from: Constants.seedSaltPrefix + passphrase)
        let seed = try normalizedMnemonic.pbkdf2sha512(salt: normalizedSalt, rounds: 2048)
        return seed
    }

    func convertToMnemonicString(_ mnemonicComponents: [String]) -> String {
        return mnemonicComponents.joined(separator: " ")
    }

    func parse(mnemonicString: String) throws -> [String] {
        let regex = try NSRegularExpression(pattern: "[a-zA-Z]+")
        let range = NSRange(location: 0, length: mnemonicString.count)
        let matches = regex.matches(in: mnemonicString, range: range)
        let components = matches.compactMap { result -> String? in
            guard result.numberOfRanges > 0,
                  let stringRange = Range(result.range(at: 0), in: mnemonicString) else {
                return nil
            }

            return String(mnemonicString[stringRange]).trim().lowercased()
        }

        try validate(mnemonicComponents: components)
        return components
    }

    func validate(mnemonicComponents: [String]) throws {
        // Validate words count
        guard !mnemonicComponents.isEmpty else {
            throw MnemonicError.wrongWordCount
        }

        guard let entropyLength = EntropyLength.allCases.first(where: { $0.wordsCount == mnemonicComponents.count }) else {
            throw MnemonicError.wrongWordCount
        }

        // Validate wordlist by the first word
        let wordlist = try getWordlist(by: mnemonicComponents[0]).1

        // Validate all the words
        var invalidWords = Set<String>()

        // Generate an indices array inplace
        var concatenatedBits = ""

        for word in mnemonicComponents {
            guard let wordIndex = wordlist.firstIndex(of: word) else {
                invalidWords.insert(word)
                continue
            }

            let indexBits = String(wordIndex, radix: 2).zeroPadding(toLength: 11)
            concatenatedBits.append(contentsOf: indexBits)
        }

        guard invalidWords.isEmpty else {
            throw MnemonicError.invalidWords(words: Array(invalidWords))
        }

        // Validate checksum

        let checksumBitsCount = mnemonicComponents.count / 3
        guard checksumBitsCount == entropyLength.cheksumBitsCount else {
            throw MnemonicError.invalidCheksum
        }

        let entropyBitsCount = concatenatedBits.count - checksumBitsCount
        let entropyBits = String(concatenatedBits.prefix(entropyBitsCount))
        let checksumBits = String(concatenatedBits.suffix(checksumBitsCount))

        guard let entropyData = Data(bitsString: entropyBits) else {
            throw MnemonicError.invalidCheksum
        }

        let calculatedChecksumBits = entropyData
            .getSha256()
            .toBits()
            .prefix(entropyLength.cheksumBitsCount)
            .joined()

        guard calculatedChecksumBits == checksumBits else {
            throw MnemonicError.invalidCheksum
        }
    }

    // Validate wordlist by the first word
    func parseWordlist(from mnemonicComponents: [String]) throws -> Wordlist {
        return try getWordlist(by: mnemonicComponents[0]).0
    }

    /// Generate a mnemonic from data. Useful for testing purposes.
    /// - Parameters:
    ///   - data: The entropy data in hex format
    ///   - wordlist: The wordlist to use.
    /// - Returns: The generated mnemonic
    func generateMnemonic(from entropyData: Data, wordlist: Wordlist) throws -> [String] {
        guard let entropyLength = EntropyLength(rawValue: entropyData.count * 8) else {
            throw MnemonicError.invalidEntropyLength
        }

        let entropyHashBits = entropyData.getSha256().toBits()
        let entropyChecksumBits = entropyHashBits.prefix(entropyLength.cheksumBitsCount)

        let entropyBits = entropyData.toBits()
        let concatenatedBits = entropyBits + entropyChecksumBits
        let bitIndexes = concatenatedBits.chunked(into: 11)
        let indexes = bitIndexes.compactMap { Int($0.joined(), radix: 2) }

        guard indexes.count == entropyLength.wordsCount else {
            throw MnemonicError.mnenmonicCreationFailed
        }

        let allWords = wordlist.words
        let maxWordIndex = allWords.count

        let words = try indexes.map { index in
            guard index < maxWordIndex else {
                throw MnemonicError.mnenmonicCreationFailed
            }

            return allWords[index]

        }

        return words
    }

    private func normalizedData(from string: String) throws -> Data {
        let normalizedString = string.decomposedStringWithCompatibilityMapping

        guard let data = normalizedString.data(using: .utf8) else {
            throw MnemonicError.normalizationFailed
        }

        return data
    }

    private func getWordlist(by word: String) throws -> (Wordlist, [String]) {
        for list in Wordlist.allCases {
            let words = list.words

            if words.contains(word) {
                return (list, words)
            }
        }

        throw MnemonicError.unsupportedLanguage
    }
}

// MARK: - Constants

@available(iOS 13.0, *)
private extension BIP39 {
    enum Constants {
        static let seedSaltPrefix = "mnemonic"
    }
}
