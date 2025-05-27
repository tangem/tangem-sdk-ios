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
    private let newAttestationService: Bool

    public init(networkService: NetworkService, newAttestationService: Bool) {
        self.networkService = networkService
        self.newAttestationService = newAttestationService
    }

    func makeBackupCertificateProvider(
        cardId: String,
        cardPublicKey: Data,
        issuerPublicKey: Data,
        firmwareVersion: FirmwareVersion
    ) -> BackupCertificateProvider {
        let factory = OnlineAttestationServiceFactory(networkService: networkService, newAttestationService: newAttestationService)
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
