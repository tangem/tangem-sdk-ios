//
//  CardArtworksProvider.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public protocol CardArtworksProvider {
    func loadArtworks() async throws -> Artworks 
}

public struct Artworks {
    public let large: Data
    public let small: Data?
}
