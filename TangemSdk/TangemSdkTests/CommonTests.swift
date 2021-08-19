//
//  IntUtilsTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 01.11.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

@available(iOS 13.0, *)
class CommonTests: XCTestCase {
    func testAtetstModeCompare() {
        XCTAssertTrue(AttestationTask.Mode.normal < AttestationTask.Mode.full)
        XCTAssertTrue(AttestationTask.Mode.normal <= AttestationTask.Mode.full)
        XCTAssertFalse(AttestationTask.Mode.normal > AttestationTask.Mode.full)
        XCTAssertFalse(AttestationTask.Mode.full < AttestationTask.Mode.normal)
        XCTAssertTrue(AttestationTask.Mode.full >= AttestationTask.Mode.normal)
        XCTAssertTrue(AttestationTask.Mode.full == AttestationTask.Mode.full)
        XCTAssertTrue(AttestationTask.Mode.normal == AttestationTask.Mode.normal)
        XCTAssertFalse(AttestationTask.Mode.full == AttestationTask.Mode.normal)
    }
    
    func testAttestationRawRepresentation() {
        let attestaion = Attestation(cardKeyAttestation: .verifiedOffline,
                                     walletKeysAttestation: .verified,
                                     firmwareAttestation: .skipped,
                                     cardUniquenessAttestation: .failed)
        
        let fromRepresentation = Attestation(rawRepresentation: attestaion.rawRepresentation)
        XCTAssertNotNil(fromRepresentation)
        XCTAssertEqual(attestaion, fromRepresentation)
    }
    
    func testCardIdFormatter() {
        var formatter = CardIdFormatter()
        let cardIdString = "CB79000000018201"
        XCTAssertEqual(formatter.string(from: cardIdString), "CB79 0000 0001 8201")
        formatter.style = .lastLunh(4)
        XCTAssertEqual(formatter.string(from: cardIdString), "Card #1820")
        formatter.style = .last(1)
        XCTAssertEqual(formatter.string(from: cardIdString), "Card #1")
        formatter.style = .last(2)
        XCTAssertEqual(formatter.string(from: cardIdString), "Card #01")
        formatter.style = .last(4)
        XCTAssertEqual(formatter.string(from: cardIdString), "Card #8201")
        formatter.style = .last(6)
        XCTAssertEqual(formatter.string(from: cardIdString), "Card #01 8201")
        formatter.style = .last(20)
        XCTAssertEqual(formatter.string(from: cardIdString), "Card #CB79 0000 0001 8201")
        formatter.style = .last(16)
        XCTAssertEqual(formatter.string(from: cardIdString), "Card #CB79 0000 0001 8201")
    }
}
