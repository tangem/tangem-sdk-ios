//
//  Mnemonic.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 01.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public struct Mnemonic {
    public let mnemonicComponents: [String]
    public let wordlist: Wordlist

    public var mnemonic: String { bip39.convertToMnemonicString(mnemonicComponents) }

    private let bip39 = BIP39()

    public init(with entropy: EntropyLength = .bits128, wordList: Wordlist = .en) throws {
        mnemonicComponents = try bip39.generateMnemonic(entropyLength: entropy, wordlist: wordList)
        self.wordlist = wordList
    }

    public init(with mnemonic: String) throws {
        mnemonicComponents = try bip39.parse(mnemonicString: mnemonic)
        self.wordlist = try bip39.parseWordlist(from: mnemonicComponents)
    }
}
