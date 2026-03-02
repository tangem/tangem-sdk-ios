//
//  CardSettingsMaskBuilderV8.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//

enum CardSettingsMaskBuilderV8 {
    static func createSettingsMask(config: CardConfigV8) -> CardSettingsMask {
        let builder = MaskBuilder<CardSettingsMask>()
        builder.add(.isReusable)

        if config.allowSetPIN {
            builder.add(.allowSetPIN1)
        }

        if config.useNDEF {
            builder.add(.useNDEF)
        }

        if config.prohibitDefaultPIN {
            builder.add(.prohibitDefaultPIN1)
        }

        if config.useActivation {
            builder.add(.useActivation)
        }

        if config.useBlock {
            builder.add(.useBlock)
        }

        if config.prohibitPurgeWallet {
            builder.add(.permanentWallet)
        }

        if config.disableFiles ?? false {
            builder.add(.disableFiles)
        }

        if config.allowHDWallets ?? false  {
            builder.add(.allowHDWallets)
        }

        if config.allowBackup ?? false {
            builder.add(.allowBackup)
        }

        if config.allowKeysImport ?? false {
            builder.add(.allowKeysImport)
        }

        if config.requireBackup ?? false {
            builder.add(.requireBackup)
        }

        return builder.build()
    }
}
