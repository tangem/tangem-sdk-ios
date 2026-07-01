//
//  DevCardArtworksProvider.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct DevCardArtworksProvider: CardArtworksProvider {
    func loadArtworks() async throws -> Artworks {
        return Artworks(large: Data(), small: Data())
    }
}
