//
//  CardCertificateProvider.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 27.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CardCertificateProvider {
    private let onlineAttestationService = OnlineAttestationService()
    private var cancellable: AnyCancellable? = nil
    private let developmentMode: Bool

    init(developmentMode: Bool) {
        self.developmentMode = developmentMode
    }

    private func loadAttestationData(for cardId: String, cardPublicKey: Data, _ completion: @escaping CompletionResult<OnlineAttestationResponse>) {
        if developmentMode {
            do {
                let developmentResponse = try makeDevelopmentResponse(cardPublicKey: cardPublicKey)
                completion(.success(developmentResponse))
            } catch {
                completion(.failure(error.toTangemSdkError()))
            }
            return
        }

        cancellable = onlineAttestationService
            .getAttestationData(cardId: cardId, cardPublicKey: cardPublicKey)
            .sink(receiveCompletion: { receivedCompletion in
                if case .failure = receivedCompletion {
                    completion(.failure(.issuerSignatureLoadingFailed))
                }
            }, receiveValue: {
                completion(.success($0))
            })
    }
}

// MARK: - Backup certificate

extension CardCertificateProvider {
    func getBackupCertificate(for cardId: String, cardPublicKey: Data, _ completion: @escaping CompletionResult<Data>) {
        loadAttestationData(for: cardId, cardPublicKey: cardPublicKey) { loadCompletion in
            switch loadCompletion {
            case .success(let response):
                do {
                    let certificate = try CardCertificateProvider.generateBackupCertificate(
                        cardPublicKey: cardPublicKey,
                        issuerSignature: response.issuerSignature
                    )
                    completion(.success(certificate))
                } catch {
                    completion(.failure(error.toTangemSdkError()))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private static func generateBackupCertificate(cardPublicKey: Data, issuerSignature: Data) throws -> Data {
        return try TlvBuilder()
            .append(.cardPublicKey, value: cardPublicKey)
            .append(.issuerDataSignature, value: issuerSignature)
            .serialize()
    }
}

// MARK: - Development mode

private extension CardCertificateProvider {
    func makeDevelopmentResponse(cardPublicKey: Data) throws -> OnlineAttestationResponse {
        let sdkIssuerSignature = try cardPublicKey.sign(privateKey: Constants.sdkIssuerPrivateKey)
        let manufacturerSignature = Data() // not used

        return OnlineAttestationResponse(
            manufacturerSignature: manufacturerSignature,
            issuerSignature: sdkIssuerSignature
        )
    }
}


// MARK: - Constants

private extension CardCertificateProvider {
    enum Constants {
        static let sdkIssuerPrivateKey = Data(hexString: "11121314151617184771ED81F2BACF57479E4735EB1405083927372D40DA9E92")
    }
}
