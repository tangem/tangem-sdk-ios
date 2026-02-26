//
//  Untitled.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct ArtworksResponse: Decodable {
    let imageSmallUrl: URL?
    let imageSmallSignature: Data?
    let imageLargeUrl: URL
    let imageLargeSignature: Data
}
