//
//  AccessCodeRepository.swift
//  TangemSdk
//
//  Created by Andrey Chukavin on 13.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import LocalAuthentication
import Security
@available(iOS 13.0, *)
public class AccessCodeRepository {
    private let secureStorage = SecureStorage()
    
    private let cardIdListKey = "card-id-list"
    private let accessCodeListKey = "access-code-list1234567"
    
    public init() {
        
    }
    
    public func hasAccessCode(for cardId: String) -> Bool {
        cardId == "AC01000000000189"
        
    }
//    static func getBioSecAccessControl() -> SecAccessControl {
//        var access: SecAccessControl?
//        var error: Unmanaged<CFError>?
//
//        //          if #available(iOS 11.3, *) {
//        //              access = SecAccessControlCreateWithFlags(nil,
//        //                  kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
//        //                  .biometryCurrentSet,
//        //                  &error)
//        //          } else {
//        //              access = SecAccessControlCreateWithFlags(nil,
//        //                  kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
//        //                  .touchIDCurrentSet,
//        //                  &error)
//        //          }
//
//        access = SecAccessControlCreateWithFlags(
//            nil,
//            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
//            .userPresence,
//            nil)!
//
//        precondition(access != nil, "SecAccessControlCreateWithFlags failed")
//        return access!
//    }
//
//    static func createBioProtectedEntry(key: String, data: Data) -> OSStatus {
//        let query = [
//            kSecClass as String       : kSecClassGenericPassword as String,
//            kSecAttrAccount as String : key,
//            kSecAttrAccessControl as String: getBioSecAccessControl(),
//            kSecValueData as String   : data ] as CFDictionary
//
//        return SecItemAdd(query as CFDictionary, nil)
//    }
//
//    static func loadBioProtected(key: String, context: LAContext? = nil,
//                                 prompt: String? = nil) -> Data? {
//        var query: [String: Any] = [
//            kSecClass as String       : kSecClassGenericPassword,
//            kSecAttrAccount as String : key,
//            kSecReturnData as String  : kCFBooleanTrue,
//            kSecAttrAccessControl as String: getBioSecAccessControl(),
//            kSecMatchLimit as String  : kSecMatchLimitOne ]
//
//        if let context = context {
//            query[kSecUseAuthenticationContext as String] = context
//
//            // Prevent system UI from automatically requesting Touc ID/Face ID authentication
//            // just in case someone passes here an LAContext instance without
//            // a prior evaluateAccessControl call
//            query[kSecUseAuthenticationUI as String] = kSecUseAuthenticationUISkip
//        }
//
//        if let prompt = prompt {
//            query[kSecUseOperationPrompt as String] = prompt
//        }
//
//        var dataTypeRef: AnyObject? = nil
//
//        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
//
//        if status == noErr {
//            return (dataTypeRef! as! Data)
//        } else {
//            return nil
//        }
//    }
    
    public func fetchAccessCode(for cardId: String, completion: @escaping (Result<String, Error>) -> Void) {
//        let context = LAContext()
//
//        print(context.biometryType.rawValue)
//        var error: NSError?
//        let policy: LAPolicy = .deviceOwnerAuthentication
//
//        guard context.canEvaluatePolicy(policy, error: &error) else {
//            print("NO BIOMETRY", error)
//            return
//        }
////
////        let zz = Self.loadBioProtected(key: "key")
////        print("BEFORE")
////        print(zz)
////        print(String(data: zz ?? Data(), encoding: .utf8))
//
//
//        let reason = "Touch ID is needed BECAUSE"
//
////        context.evaluatePolicy(policy, localizedReason: reason) {
////            success, authenticationError in
//
//
////
////
////
//            let value = "hello auth34"
//            let data = value.data(using: .utf8)!
//
//            do {
//                if let recovered = try self.secureStorage.get(account: self.accessCodeListKey) {
//                    print("BEFORE SETTING", String(data: recovered, encoding: .utf8))
//                }
//
//                try self.secureStorage.store(object: data, account: self.accessCodeListKey, overwrite: true
//                                             , authenticationContext: context
//                )
//
//                let recovered = try self.secureStorage.get(account: self.accessCodeListKey)
//                print("AFTER SETTING", String(data: recovered ?? Data(), encoding: .utf8))
//
//            } catch {
//                print("FAILED \(error)")
//            }
//
//
//
//
////
////            let accessControl = SecAccessControlCreateWithFlags(
////              nil,
////              kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
////              .userPresence,
////              nil)!
////
////            let account = "andyibanez2"
////            let server = "pullipstyle.com2"
////
////            let query = [
////              kSecClass: kSecClassInternetPassword,
////              kSecAttrAccount: account,
////              kSecAttrServer: server,
////              kSecValueData: "Pullip2020".data(using: .utf8)!,
////              kSecAttrAccessControl: accessControl,
////              kSecReturnData: true
////            ] as CFDictionary
////
////            var result: AnyObject?
////
////            let status = SecItemAdd(query, &result)
////            print("PUT")
////            print(result)
////            print(String(data: (result as? Data) ?? Data(), encoding: .utf8))
////            print(status, status.message)
////
////
////            let searchQuery = [
////              kSecClass: kSecClassInternetPassword,
////              kSecAttrAccount: account,
////              kSecAttrServer: server,
////              kSecMatchLimit: kSecMatchLimitOne,
////              kSecReturnData: true,
////              kSecReturnAttributes: true,
////              kSecUseOperationPrompt: "Access your data"
////            ] as CFDictionary
////
////            var item: AnyObject?
////
////            let status2 = SecItemCopyMatching(searchQuery, &item)
////            print("GOT")
////            print(item)
////            print(String(data: (item as? Data) ?? Data(), encoding: .utf8))
////            print(status2, status2.message)
//
//
////
////
////        Self.createBioProtectedEntry(key: "key", data: "AAA".data(using: .utf8)!)
////        let x = Self.loadBioProtected(key: "key")
////        print(x)
////        print(String(data: x ?? Data(), encoding: .utf8))
//
//
//            fatalError()
//
//
//
//
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                completion(.success("1234"))
//            }
////        }
        
        
        
        
        do {
            let data = try secureStorage.get(account: cardIdListKey)
            let list = String(data: data ?? Data(), encoding: .utf8) ?? ""
            print("LIST:", list)
        } catch {
            print("FAILED TO READ LIST:", error)
        }
        
        
        
        let context = LAContext()
        
        print(context.biometryType.rawValue)
        var error: NSError?
        let policy: LAPolicy = .deviceOwnerAuthentication
        
        guard context.canEvaluatePolicy(policy, error: &error) else {
            print("NO BIOMETRY", error)
            completion(.failure(HDWalletError.hardenedNotSupported)) // TODO
            return
        }
        
        
        
        let reason = "Touch ID is needed BECAUSE"
        
        context.evaluatePolicy(policy, localizedReason: reason) {
            success, authenticationError in
            
        
        
            do {
                let data = try self.secureStorage.get(account: self.accessCodeListKey, context: context)
                let code = String(data: data ?? Data(), encoding: .utf8) ?? ""
                completion(.success(code))
            } catch {
                completion(.failure(error))
            }
        }
        
    }

    public func saveAccessCode(_ accessCode: String, for cardId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        
        do {
            let list = "my list of cards \(accessCode)".data(using: .utf8) ?? Data()
            try secureStorage.store(object: list, account: cardIdListKey)
        } catch {
            print("FAILED TO WRITE LIST:", error)
        }
        
        
        let context = LAContext()
        
        print(context.biometryType.rawValue)
        var error: NSError?
        let policy: LAPolicy = .deviceOwnerAuthentication
        
        guard context.canEvaluatePolicy(policy, error: &error) else {
            print("NO BIOMETRY", error)
            completion(.failure(HDWalletError.hardenedNotSupported)) // TODO
            return
        }
        
        let reason = "Touch ID is needed BECAUSE"
        
        context.evaluatePolicy(policy, localizedReason: reason) {
            success, authenticationError in
            
            do {
                let codeData = accessCode.data(using: .utf8)!
                try self.secureStorage.store2(object: codeData, account: self.accessCodeListKey, overwrite: true, context: context)
                completion(.success(true))
            } catch {
                completion(.failure(error))
            }
            
            
        }
    }
}
