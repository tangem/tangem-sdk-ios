//
//  BackupCredentialsHelper.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 10/07/2026.
//

import Foundation

/// Saves user credentials obtained during backup: access tokens for v8+ cards and access codes for older ones.
/// If the biometrics permission hasn't been granted yet, credentials are kept in memory
/// until `savePendingCredentials` or `deletePendingCredentials` is called.
final class BackupCredentialsHelper {
    private lazy var accessCodeRepository = AccessCodeRepository()
    private lazy var cardAccessTokensRepository = CardAccessTokensRepository()
    private var pendingCredentials: [String: PendingCredentials] = [:]

    init() {}

    deinit {
        deletePendingCredentials()
    }

    func addPendingCredentials(cardId: String, credentials: PendingCredentials) {
        // Resume paths can re-add credentials for the same card; wipe the replaced
        // value so the old secret doesn't linger in memory until deallocation.
        pendingCredentials[cardId]?.zeroOut()
        pendingCredentials[cardId] = credentials
    }

    func savePendingCredentials() {
        for (cardId, credentials) in pendingCredentials {
            do {
                switch credentials {
                case .accessCode(let accessCode):
                    try accessCodeRepository.save(accessCode, for: cardId, firmwareVersion: .backupAvailable)
                case .accessTokens(let accessTokens):
                    try cardAccessTokensRepository.save(accessTokens, for: cardId)
                }
            } catch {
                Log.error("Failure while saving pending credentials: \(error)")
            }
        }

        deletePendingCredentials()
    }

    func deletePendingCredentials() {
        for cardId in Array(pendingCredentials.keys) {
            // `removeValue` hands us the dictionary's own reference to the value, so `zeroOut`
            // wipes the bytes in place unless an external copy still shares the buffer.
            var credentials = pendingCredentials.removeValue(forKey: cardId)
            credentials?.zeroOut()
        }
    }
}

extension BackupCredentialsHelper {
    enum PendingCredentials {
        case accessCode(Data)
        case accessTokens(CardAccessTokens)

        /// Best-effort wipe of the underlying bytes. `self` is replaced with an empty payload
        /// first, so the extracted copy becomes the unique buffer owner and `zeroOut`
        /// doesn't trigger a copy-on-write.
        mutating func zeroOut() {
            switch self {
            case .accessCode(var accessCode):
                self = .accessCode(Data())
                accessCode.zeroOut()
            case .accessTokens(var accessTokens):
                self = .accessTokens(CardAccessTokens(accessToken: Data(), identifyToken: Data()))
                accessTokens.zeroOut()
            }
        }
    }
}
