//
//  MnemonicTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 06.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

@available(iOS 13.0, *)
class MnemonicTests: XCTestCase {
    func testReadWords() {
        let langs: [Wordlist] = [.en]

        for lang in langs {
            XCTAssertTrue(lang.words.count > 0)
        }
    }

    func testMnemonicGenerationBase() throws  {
        let entropyLengthArray: [EntropyLength] = [.bits128, .bits160, .bits192, .bits224, .bits256]
        let wordLists: [Wordlist] = [.en]

        let bip39 = BIP39()

        for entropyLength in entropyLengthArray {
            for wordlist in wordLists {
                let mnemonic = try bip39.generateMnemonic(entropyLength: entropyLength, wordlist: wordlist)
                XCTAssertEqual(mnemonic.count, entropyLength.wordsCount)
            }
        }
    }

    func testMnemonicGenerationByEnVectors() throws  {
        guard let allVectors = try getTestVectors(),
              let vectors = allVectors[Constants.englishTestVectors] as? [[String]] else {
            XCTFail("Failed to parse test vectors file.")
            return
        }

        let bip39 = BIP39()
        
        for vector in vectors {
            let entropy = vector[0]
            let expectedMnemonic = vector[1]
            let mnemonic = (try bip39.generateMnemonic(from: Data(hexString: entropy), wordlist: .en)).joined(separator: " ")
            XCTAssertEqual(mnemonic, expectedMnemonic)
        }
    }

    private func getTestVectors() throws -> [String: Any]? {
        guard let url = Bundle(for: MnemonicTests.self).url(forResource: "seed_test_vectors", withExtension: "json") else {
            return nil
        }

        let data = try Data(contentsOf: url)
        let options: JSONSerialization.ReadingOptions = [.allowFragments, .mutableContainers, .mutableLeaves]

        guard let dictionary =
                try JSONSerialization.jsonObject(with: data, options: options) as? [String: Any] else {
            return nil
        }

        return dictionary
    }
}

@available(iOS 13.0, *)
private extension MnemonicTests {
    enum Constants {
        static let englishTestVectors = "english"
    }
}
