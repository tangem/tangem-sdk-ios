//
//  StorageService.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 06.07.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public class StorageService {
    static let prefix = "tng_"
    
    enum Keys: String {
        case hasSuccessfulTapIn
        case cardValues
    }
    
    func bool(forKey: StorageService.Keys) -> Bool {
        UserDefaults.standard.bool(forKey: rawKey(forKey))
    }
    
    func set(boolValue: Bool, forKey: StorageService.Keys) {
        UserDefaults.standard.set(boolValue, forKey: rawKey(forKey))
    }
    
    func string(forKey: StorageService.Keys) -> String? {
        UserDefaults.standard.string(forKey: rawKey(forKey))
    }
    
    func set(stringValue: String, forKey: StorageService.Keys) {
        UserDefaults.standard.set(stringValue, forKey: rawKey(forKey))
    }
    
    func object<T: Decodable>(forKey: StorageService.Keys) -> T? {
        if let data =  UserDefaults.standard.data(forKey: rawKey(forKey)) {
            let decoder = JSONDecoder()
            return try? decoder.decode(T.self, from: data)
        }
        return nil
    }
    
    func set<T: Encodable>(object: T, forKey: StorageService.Keys) {
        let encoder = JSONEncoder()
        let data = try? encoder.encode(object)
        UserDefaults.standard.set(data, forKey: rawKey(forKey))
    }
    
    private func rawKey(_ forKey: StorageService.Keys) -> String {
        return "\(StorageService.prefix)\(forKey.rawValue)"
    }
}
