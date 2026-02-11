//
//  CardConfigData.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 10/02/2026.
//

import Foundation

struct CardConfigData: Decodable {
    let date: Date?
    let batch: String
    let blockchain: String
    let productNote: Bool?
    let productTag: Bool?
    let productIdCard: Bool?
    let productIdIssuer: Bool?
    let productAuthentication: Bool?
    let productTwin: Bool?
    let tokenSymbol: String?
    let tokenContractAddress: String?
    let tokenDecimal: Int?

    func createPersonalizationCardData() -> CardData {
        return CardData(batchId: batch,
                        manufactureDateTime: date ?? Date(),
                        blockchainName: blockchain,
                        productMask: createProductMask(),
                        tokenSymbol: tokenSymbol,
                        tokenContractAddress: tokenContractAddress,
                        tokenDecimal: tokenDecimal)
    }

    func createProductMask() -> ProductMask {
        let builder = MaskBuilder<ProductMask>()

        if productNote ?? false {
            builder.add(.note)
        }

        if productTag ?? false {
            builder.add(.tag)
        }

        if productIdCard ?? false {
            builder.add(.idCard)
        }

        if productIdIssuer ?? false {
            builder.add(.idIssuer)
        }

        if productTwin ?? false {
            builder.add(.twinCard)
        }

        if productAuthentication ?? false {
            builder.add(.authentication)
        }

        return builder.build()
    }
}
