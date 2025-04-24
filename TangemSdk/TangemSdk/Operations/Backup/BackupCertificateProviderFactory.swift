//
//  BackupCertificateProviderFactory.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24/03/2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct BackupCertificateProviderFactory {
    func makeBackupCertificateProvider(
        cardId: String,
        cardPublicKey: Data,
        issuerPublicKey: Data,
        firmwareVersion: FirmwareVersion
    ) -> BackupCertificateProvider {
        let factory = OnlineAttestationServiceFactory()
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
