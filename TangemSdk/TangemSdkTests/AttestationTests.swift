//
//  AttestationTests.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 27/05/2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
@testable import TangemSdk

class AttestationTests: XCTestCase {
    var mapper: OnlineAttestationResponseMapper?

    override func setUp() {
        let json = try? Bundle.readFileAsString(name: "Card", in: .root)
        let data = json?.data(using: .utf8)
        let card = try? JSONDecoder.tangemSdkDecoder.decode(Card.self, from: data!)
        mapper = card.map { OnlineAttestationResponseMapper(card: $0) }
    }

    func testErrorMapping() throws {
        let mapper = try XCTUnwrap(mapper)

        XCTAssertEqual(mapper.mapError(NetworkServiceError.emptyResponse), Attestation.Status.verifiedOffline)
        XCTAssertEqual(mapper.mapError(NetworkServiceError.emptyResponseData), Attestation.Status.verifiedOffline)
        XCTAssertEqual(mapper.mapError(NetworkServiceError.urlSessionError(MockError.anyError)), Attestation.Status.verifiedOffline)

        XCTAssertEqual(mapper.mapError(NetworkServiceError.statusCode(100, "")), Attestation.Status.verifiedOffline)
        XCTAssertEqual(mapper.mapError(NetworkServiceError.statusCode(210, "")), Attestation.Status.verifiedOffline)
        XCTAssertEqual(mapper.mapError(NetworkServiceError.statusCode(310, "")), Attestation.Status.verifiedOffline)
        XCTAssertEqual(mapper.mapError(NetworkServiceError.statusCode(410, "")), Attestation.Status.verifiedOffline)
        XCTAssertEqual(mapper.mapError(NetworkServiceError.statusCode(500, "")), Attestation.Status.verifiedOffline)
        XCTAssertEqual(mapper.mapError(NetworkServiceError.ctDisabled), Attestation.Status.verifiedOffline)


        XCTAssertEqual(mapper.mapError(TangemSdkError.cardVerificationFailed), Attestation.Status.failed)
        XCTAssertEqual(mapper.mapError(NetworkServiceError.statusCode(403, "")), Attestation.Status.failed)
        XCTAssertEqual(mapper.mapError(NetworkServiceError.statusCode(404, "")), Attestation.Status.failed)
        XCTAssertEqual(mapper.mapError(NetworkServiceError.mappingError(MockError.anyError)), Attestation.Status.failed)
        XCTAssertEqual(mapper.mapError(NetworkServiceError.failedToMakeRequest), Attestation.Status.failed)
        XCTAssertEqual(mapper.mapError(MockError.anyError), Attestation.Status.failed)
        XCTAssertEqual(mapper.mapError(TangemSdkError.userCancelled), Attestation.Status.failed)

        let networkError = NetworkServiceError.emptyResponse
        switch networkError {
        case .emptyResponse,
                .emptyResponseData,
                .failedToMakeRequest,
                .mappingError,
                .statusCode,
                .urlSessionError,
                .ctDisabled:
            break
            /// All network errors should be covered in this test
        }
    }
}

fileprivate extension AttestationTests {
    enum MockError: Error {
        case anyError
    }
}
