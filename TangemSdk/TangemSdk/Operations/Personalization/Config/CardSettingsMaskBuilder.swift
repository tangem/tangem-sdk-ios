//
//  CardSettingsMaskBuilder.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 10/02/2026.
//

enum CardSettingsMaskBuilder {
    static func createSettingsMask(config: CardConfig) -> CardSettingsMask {
        let builder = MaskBuilder<CardSettingsMask>()

        if config.allowSetPIN1 {
            builder.add(.allowSetPIN1)
        }
        if config.allowSetPIN2 {
            builder.add(.allowSetPIN2)
        }
        if config.useCvc {
            builder.add(.useCvc)
        }

        if config.isReusable ?? true {
            builder.add(.isReusable)
        }

        if config.useOneCommandAtTime ?? false {
            builder.add(.useOneCommandAtTime)
        }

        if config.useNDEF {
            builder.add(.useNDEF)
        }

        if config.useDynamicNDEF ?? false {
            builder.add(.useDynamicNDEF)
        }

        if config.disablePrecomputedNDEF ?? false {
            builder.add(.disablePrecomputedNDEF)
        }

        if config.allowUnencrypted {
            builder.add(.allowUnencrypted)
        }

        if config.allowFastEncryption {
            builder.add(.allowFastEncryption)
        }

        if config.prohibitDefaultPIN1 {
            builder.add(.prohibitDefaultPIN1)
        }

        if config.useActivation {
            builder.add(.useActivation)
        }

        if config.useBlock {
            builder.add(.useBlock)
        }

        if config.smartSecurityDelay {
            builder.add(.smartSecurityDelay)
        }

        if config.protectIssuerDataAgainstReplay ?? false {
            builder.add(.protectIssuerDataAgainstReplay)
        }

        if config.prohibitPurgeWallet {
            builder.add(.permanentWallet)
        }

        if config.allowSelectBlockchain {
            builder.add(.allowSelectBlockchain)
        }

        if config.skipCheckPIN2CVCIfValidatedByIssuer {
            builder.add(.skipCheckPIN2CVCIfValidatedByIssuer)
        }

        if config.skipSecurityDelayIfValidatedByIssuer {
            builder.add(.skipSecurityDelayIfValidatedByIssuer)
        }

        if config.skipSecurityDelayIfValidatedByLinkedTerminal {
            builder.add(.skipSecurityDelayIfValidatedByLinkedTerminal)
        }

        if config.restrictOverwriteIssuerExtraData ?? false {
            builder.add(.restrictOverwriteIssuerExtraData)
        }

        if config.disableIssuerData ?? false {
            builder.add(.disableIssuerData)
        }

        if config.disableUserData ?? false  {
            builder.add(.disableUserData)
        }

        if config.disableFiles ?? false {
            builder.add(.disableFiles)
        }

        if config.allowHDWallets ?? false {
            builder.add(.allowHDWallets)
        }

        if config.allowBackup ?? false {
            builder.add(.allowBackup)
        }

        if config.allowKeysImport ?? false {
            builder.add(.allowKeysImport)
        }

        return builder.build()
    }
}
