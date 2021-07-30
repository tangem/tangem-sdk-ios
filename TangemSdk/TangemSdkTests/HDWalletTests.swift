//
//  HDWalletTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 30.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

@available(iOS 13.0, *)
class HDWalletTests: XCTestCase {
    func testDerivation1() {
        let masterKey = ExtendedPublicKey(compressedPublicKey: Data(hexString: "0339a36013301597daef41fbe593a02cc513d0b55527ec2df1050e2e8ff49c85c2"),
                                      chainCode: Data(hexString: "873dff81c02f525623fd1fe5167eac3a55a049de3d314bb42ee227ffed37d508"))
        
        let derived = masterKey.derivePublicKey(with: 1)
        XCTAssertNotNil(derived)
        
        let key = derived!.compressedPublicKey.hexString.lowercased()
        let chainCode = derived!.chainCode.hexString.lowercased()
        XCTAssertEqual(key, "037c2098fd2235660734667ff8821dbbe0e6592d43cfd86b5dde9ea7c839b93a50")
        XCTAssertEqual(chainCode, "8dd96414ff4d5b4750be3af7fecce207173f86d6b5f58f9366297180de8e109b")
    }
    
    func testDerivation0() {
        let masterKey = ExtendedPublicKey(compressedPublicKey: Data(hexString: "03cbcaa9c98c877a26977d00825c956a238e8dddfbd322cce4f74b0b5bd6ace4a7"),
                                      chainCode: Data(hexString: "60499f801b896d83179a4374aeb7822aaeaceaa0db1f85ee3e904c4defbd9689"))
        
        let derived = masterKey.derivePublicKey(with: 0)
        XCTAssertNotNil(derived)
        
        let key = derived!.compressedPublicKey.hexString.lowercased()
        let chainCode = derived!.chainCode.hexString.lowercased()
        XCTAssertEqual(key, "02fc9e5af0ac8d9b3cecfe2a888e2117ba3d089d8585886c9c826b6b22a98d12ea")
        XCTAssertEqual(chainCode, "f0909affaa7ee7abe5dd4e100598d4dc53cd709d5a5c2cac40e7412f232f7c9c")
    }
}