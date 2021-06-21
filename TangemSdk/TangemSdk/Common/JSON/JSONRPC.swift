//
//  JSONRPCRequest.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 14.05.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public final class JSONRPCConverter {
    public static let shared: JSONRPCConverter = {
        let converter = JSONRPCConverter()
        converter.register(SignCommand.self)
        converter.register(ScanTask.self)
        return converter
    }()
    
    public private(set) var runnables: [String: JSONRPCConvertible.Type] = [:]
    
    private init() {}

    public func register(_ object: JSONRPCConvertible.Type) {
        runnables[object.method.lowercased()] = object
    }
    
    public func convert(request: JSONRPCRequest) throws -> AnyJSONRPCRunnable {
        guard let method = runnables[request.method.lowercased()] else {
            throw JSONRPCError(.methodNotFound, data: request.method)
        }
        
        return try method.makeRunnable(from: request.params)
    }
}

public protocol JSONRPCConvertible {
    static var method: String { get }
    init(from parameters: [String: Any]) throws
    static func makeRunnable(from parameters: [String: Any]) throws -> AnyJSONRPCRunnable
}

public extension JSONRPCConvertible where Self: CardSessionRunnable, Self.Response: JSONStringConvertible {
    static func makeRunnable(from parameters: [String: Any]) throws -> AnyJSONRPCRunnable {
        return try Self.init(from: parameters).eraseToAnyRunnable()
    }
}

// MARK: - JSONRPC Specification

public struct JSONRPCRequest {
    public let jsonrpc: String
    public let id: Int?
    public let method: String
    public let params: [String: Any]
    
    public init(id: Int?, method: String, params: [String : Any]) {
        self.jsonrpc = "2.0"
        self.id = id
        self.method = method
        self.params = params
    }
    
    public init(jsonString: String) throws {
        guard let data = jsonString.data(using: .utf8) else {
            throw JSONRPCError(.parseError)
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let jsonrpcValue = json["jsonrpc"] as? String {
                    jsonrpc = jsonrpcValue
                } else {
                    throw JSONRPCError(.invalidRequest, data: "jsonrpc")
                }
                if let idValue = json["id"] as? Int {
                    id = idValue
                } else {
                    throw JSONRPCError(.invalidRequest, data: "id")
                }
                if let methodValue = json["method"] as? String {
                    method = methodValue
                } else {
                    throw JSONRPCError(.invalidRequest, data: "method")
                }
                if let paramsValue = json["params"] as? [String:Any] {
                    params = paramsValue
                } else {
                    throw JSONRPCError(.invalidRequest, data: "params")
                }
            } else {
                throw JSONRPCError(.parseError)
            }
        } catch {
            throw JSONRPCError(.parseError, data: error.localizedDescription)
        }
    }
}

public struct JSONRPCResponse: JSONStringConvertible {
    public let jsonrpc: String
    public let result: AnyJSONRPCResponse?
    public let error: JSONRPCError?
    public let id: Int?
    
    public init(id: Int?, result: AnyJSONRPCResponse?, error: JSONRPCError?) {
        self.jsonrpc = "2.0"
        self.result = result
        self.error = error
        self.id = id
    }
}

public struct JSONRPCError: Error, JSONStringConvertible, Equatable {
    public let code: Int
    public let message: String
    public let data: String?
    
    public init(code: Int, message: String, data: String?) {
        self.code = code
        self.message = message
        self.data = data
    }
    
    public init(_ code: JSONRPCError.Code, data: String? = nil) {
        self.code = code.rawValue
        self.message = code.message
        self.data = data
    }
}

extension JSONRPCError {
    public enum Code: Int {
        case parseError = -32700
        case invalidRequest = -32600
        case methodNotFound = -32601
        case invalidParams = -32602
        case internalError = -32603
        case serverError = -32000
        
        var message: String { //TODO: localize
            switch self {
            case .internalError:
                return "Internal error"
            case .invalidParams:
                return "Invalid parameters"
            case .invalidRequest:
                return "Invalid request"
            case .methodNotFound:
                return "Method not found"
            case .parseError:
                return "Parse error"
            case .serverError:
                return "Server error"
            }
        }
    }
}

// MARK: - JSONRPC Helper extensions

extension Result where Success: JSONStringConvertible, Failure == TangemSdkError {
    func toJsonResponse(id: Int? = nil) -> JSONRPCResponse {
        switch self {
        case .success(let response):
            return JSONRPCResponse(id: id, result: response.eraseToAnyResponse(), error: nil)
        case .failure(let error):
            return error.toJsonResponse(id: id)
        }
    }
}

extension Error {
    func toJsonResponse(id: Int? = nil) -> JSONRPCResponse {
        return JSONRPCResponse(id: id, result: nil, error: toJsonError())
    }
    
    func toJsonError() -> JSONRPCError {
        if let jsonError = self as? JSONRPCError {
            return jsonError
        } else {
            let sdkError = toTangemSdkError()
            return JSONRPCError(.serverError, data: sdkError.localizedDescription)
        }
    }
}

extension Dictionary where Key == String, Value == Any {
    func value<T: Decodable>(for key: String) throws -> T where T: ExpressibleByNilLiteral {
        do {
            return try value(for: key)
        } catch {
            if let error = error as? JSONRPCError,
               error.code == JSONRPCError.Code.invalidParams.rawValue {
                return nil
            }
            
            throw error
        }
    }
    
    func value<T: Decodable>(for key: String) throws -> T {
        let value = self[key]
        if value == nil || String(describing: value) == "<null>" {
            throw JSONRPCError(.invalidParams, data: key)
        }
        
        return try decode(value!, for: key)
    }
    
    private func decode<T: Decodable>(_ value: Any, for key: String) throws -> T {
        if T.self == Data.self || T.self == Data?.self {
            if let hex = value as? String {
                return (Data(hexString: hex) as! T)
            } else {
                throw JSONRPCError(.parseError, data: key)
            }
        } else if T.self == [Data].self || T.self == [Data]?.self {
            if let hex = value as? [String] {
                return hex.compactMap { Data(hexString: $0) } as! T
            } else {
                throw JSONRPCError(.parseError, data: key)
            }
        } else {
            do {
                if let jsonData = String(describing: value).data(using: .utf8) {
                    return try JSONDecoder.tangemSdkDecoder.decode(T.self, from: jsonData)
                } else {
                    throw JSONRPCError(.parseError, data: key)
                }
            } catch {
                if let converted = value as? T {
                    return converted
                } else {
                    throw error
                }
            }
        }
    }
}

// MARK: - Commands implemetation

extension SignCommand: JSONRPCConvertible {
    public static var method: String { "sign_hashes" }
    
    public convenience init(from parameters: [String : Any]) throws {
        let walletPublicKey: Data = try parameters.value(for: "walletPublicKey")
        self.init(hashes: try parameters.value(for: "hashes"), walletPublicKey: walletPublicKey)
    }
}

extension ScanTask: JSONRPCConvertible {
    public static var method: String { "SCAN" }
    
    public convenience init(from parameters: [String : Any]) throws {
        self.init()
    }
}

//class SignHash: JSONRPCConvertible {
//    public static var method: String { "sign_hash" }
//
//    required init(from parameters: [String : Any]) throws {
//
//    }
//
//    static func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
//        let hash: Data = try parameters.value(for: "hash")
//        let walletPublicKey: Data = try parameters.value(for: "walletPublicKey")
//        let cardId: String = try parameters.value(for: "cardId")
//        let signCommand = SignCommand(hashes: <#T##[Data]#>, walletPublicKey: <#T##Data#>)
//    }
//}
