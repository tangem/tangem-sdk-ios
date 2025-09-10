//
//  BackupCertificateProvider.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class BackupCertificateProvider {
    private let cardPublicKey: Data
    private let onlineAttestationService: OnlineAttestationService
    private var cancellable: AnyCancellable? = nil

    init(cardPublicKey: Data, onlineAttestationService: OnlineAttestationService) {
        self.cardPublicKey = cardPublicKey
        self.onlineAttestationService = onlineAttestationService
    }

    func getCertificate(completion: @escaping CompletionResult<Data>) {
        loadAttestationData() { [weak self] loadCompletion in
            guard let self else {
                completion(.failure(.unknownError))
                return
            }

            switch loadCompletion {
            case .success(let response):
                do {
                    let certificate = try self.generateBackupCertificate(
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

    private func loadAttestationData(completion: @escaping CompletionResult<OnlineAttestationResponse>) {
        cancellable = onlineAttestationService
            .attestCard()
            .sink(receiveCompletion: { receivedCompletion in
                if case .failure = receivedCompletion {
                    completion(.failure(.issuerSignatureLoadingFailed))
                }
            }, receiveValue: {
                completion(.success($0))
            })
    }

    private func generateBackupCertificate(issuerSignature: Data) throws -> Data {
        return try TlvBuilder()
            .append(.cardPublicKey, value: cardPublicKey)
            .append(.issuerDataSignature, value: issuerSignature)
            .serialize()
    }
}
