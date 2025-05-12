//
//  CommonCardArtworksProvider.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 28/03/2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation

/// Only for production cards
struct CommonCardArtworksProvider: CardArtworksProvider {
    private let cardId: String
    private let cardPublicKey: Data
    private let verifier: CardArtworksVerifier
    private let networkService: NetworkService

    init(
        cardId: String,
        cardPublicKey: Data,
        verifier: CardArtworksVerifier,
        networkService: NetworkService
    ) {
        self.cardId = cardId
        self.cardPublicKey = cardPublicKey
        self.verifier = verifier
        self.networkService = networkService
    }

    public func loadArtworks() async throws -> Artworks {
        let endpoint = TangemEndpoint.artworks(cardId: cardId, cardPublicKey: cardPublicKey)
        let jsonResponse = try await networkService.request(endpoint)
        let response = try JSONDecoder.tangemSdkDecoder.decode(ArtworksResponse.self, from: jsonResponse)

        let imageLargeRequest = URLRequest(url: response.imageLargeUrl)
        let imageSmallRequest = response.imageSmallUrl.map { URLRequest(url: $0) }

        async let imageLargeResponse = networkService.requestData(request: imageLargeRequest)
        async let imageSmallResponse = imageSmallRequest !=  nil ? networkService.requestData(request: imageSmallRequest!) : nil

        let (imageLargeData, imageSmallData) = try await (imageLargeResponse, imageSmallResponse)

        let isImageLargeSignatureValid = try verifier.verify(
            imageData: imageLargeData,
            imagePrefix: SignaturePrefixBuilder.largeImage.prefix(for: response.imageLargeUrl),
            signature: response.imageLargeSignature
        )

        let isImageSmallSignatureValid: Bool

        if let imageSmallSignature = response.imageSmallSignature,
           let imageSmallURL = response.imageSmallUrl,
           let imageSmallData {
            isImageSmallSignatureValid = try verifier.verify(
                imageData: imageSmallData,
                imagePrefix: SignaturePrefixBuilder.smallImage.prefix(for: imageSmallURL),
                signature: imageSmallSignature
            )
        } else {
            isImageSmallSignatureValid = true
        }

        guard isImageLargeSignatureValid && isImageSmallSignatureValid else {
            throw TangemSdkError.cardVerificationFailed
        }

        let artworks = Artworks(large: imageLargeData, small: imageSmallData)
        return artworks
    }
}

extension CommonCardArtworksProvider {
    enum SignaturePrefixBuilder {
        case smallImage
        case largeImage

        fileprivate func prefix(for url: URL) -> Data {
            let artworkId = getArtworkID(from: url)
            return prefixString(artworkId: artworkId).data(using: .utf8)!
        }

        private func getArtworkID(from url: URL) -> String {
            NSString(string: url.lastPathComponent).deletingPathExtension
        }

        private func prefixString(artworkId: String) -> String {
            switch self {
            case .smallImage:
                return "artwork|small|\(artworkId)|"
            case .largeImage:
                return "artwork|large|\(artworkId)|"
            }
        }

    }
}
