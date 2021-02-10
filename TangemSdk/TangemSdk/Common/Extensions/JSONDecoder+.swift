//
//  JSONDecoder+.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

extension JSONDecoder {
    public static var tangemSdkDecoder: JSONDecoder  {
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let hex = try container.decode(String.self)
            return Data(hexString: hex)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "YYYY-MM-DD"
        decoder.dateDecodingStrategy  = .formatted(dateFormatter)
        return decoder
    }
}
