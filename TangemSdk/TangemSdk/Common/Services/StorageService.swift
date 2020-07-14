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
    
    func object(forKey: StorageService.Keys) -> Any? {
        if let data =  UserDefaults.standard.data(forKey: rawKey(forKey)) {
            return NSKeyedUnarchiver.unarchiveObject(with: data)
        }
        return nil
    }
    
    func set(object: Any, forKey: StorageService.Keys) {
        let data = NSKeyedArchiver.archivedData(withRootObject: object)
        UserDefaults.standard.set(data, forKey: rawKey(forKey))
    }
    
    private func rawKey(_ forKey: StorageService.Keys) -> String {
        return "\(StorageService.prefix)\(forKey.rawValue)"
    }
}
