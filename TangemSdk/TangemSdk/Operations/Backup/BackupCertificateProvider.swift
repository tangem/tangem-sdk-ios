//
//  BackupCertificateProvider.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 27.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class BackupCertificateProvider {
    private let cardPublicKey: Data
    private let onlineAttestationService: OnlineAttestationService

    init(cardPublicKey: Data, onlineAttestationService: OnlineAttestationService) {
        self.cardPublicKey = cardPublicKey
        self.onlineAttestationService = onlineAttestationService
    }

    func getCertificate(completion: @escaping CompletionResult<Data>) {
        Task {
            do {
                let response = try await self.loadAttestationData()
                let certificate = try self.generateBackupCertificate(
                    issuerSignature: response.issuerSignature
                )
                completion(.success(certificate))
            } catch {
                completion(.failure(error.toTangemSdkError()))
            }
        }
    }

    private func loadAttestationData() async throws(TangemSdkError) -> OnlineAttestationResponse {
        do {
            return try await onlineAttestationService.attestCard()
        } catch {
            throw TangemSdkError.issuerSignatureLoadingFailed
        }
    }

    private func generateBackupCertificate(issuerSignature: Data) throws -> Data {
        return try TlvBuilder()
            .append(.cardPublicKey, value: cardPublicKey)
            .append(.issuerDataSignature, value: issuerSignature)
            .serialize()
    }
}
