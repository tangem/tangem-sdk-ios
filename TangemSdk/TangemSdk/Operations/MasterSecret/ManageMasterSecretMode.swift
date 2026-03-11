//
//  ManageMasterSecretMode.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 06/03/26.
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Available modes for manage master secret
enum ManageMasterSecretMode: Byte, InteractionMode {
    case create = 0x00
    case purge = 0x01
}
