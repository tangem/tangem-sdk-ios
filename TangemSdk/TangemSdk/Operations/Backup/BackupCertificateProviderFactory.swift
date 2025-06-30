//
//  BackupCertificateProviderFactory.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24/03/2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct BackupCertificateProviderFactory {
    private let networkService: NetworkService

    public init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func makeBackupCertificateProvider(
        cardId: String,
        cardPublicKey: Data,
        issuerPublicKey: Data,
        firmwareVersion: FirmwareVersion
    ) -> BackupCertificateProvider {
        let factory = OnlineAttestationServiceFactory(networkService: networkService)
        let onlineAttestationService = factory.makeService(
            cardId: cardId,
            cardPublicKey: cardPublicKey,
            issuerPublicKey: issuerPublicKey,
            firmwareVersion: firmwareVersion
        )

        return BackupCertificateProvider(
            cardPublicKey: cardPublicKey,
            onlineAttestationService: onlineAttestationService
        )
    }
}
