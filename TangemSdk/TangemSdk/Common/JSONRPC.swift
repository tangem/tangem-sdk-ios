//
//  JSONRPCRequest.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 14.05.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public class JSONRPCCore {
    public private(set) var runnables: [String: JSONRPCConvertible.Type] = [:]
    
    public func register(_ object: JSONRPCConvertible.Type) {
        let methodName = String(describing: object).camelCaseToSnakeCase().uppercased()
        runnables[methodName] = object
    }
    
    public func createRunnable(from request: JSONRPCRequest) throws -> AnyRunnable {
        guard let method = runnables[request.method] else {
            throw JSONRPCError(.methodNotFound, data: request.method)
        }
        
        return try method.makeRunnable(from: request.params)
    }
}

public protocol JSONRPCConvertible {
    init(from parameters: [String: String]) throws
    static func makeRunnable(from parameters: [String: String]) throws -> AnyRunnable
}

public extension JSONRPCConvertible where Self: CardSessionRunnable {
    static func makeRunnable(from parameters: [String: String]) throws -> AnyRunnable {
        return try Self.init(from: parameters).eraseToAnyRunnable()
    }
}

// MARK: - JSONRPC Specification

public struct JSONRPCRequest: Decodable {
    public let jsonrpc: String
    public let id: String?
    public let method: String
    public let params: [String: String]
    
    public init(id: String?, method: String, params: [String : String]) {
        self.jsonrpc = "2.0"
        self.id = id
        self.method = method
        self.params = params
    }
    
    public init(string: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw JSONRPCError(.parseError)
        }
        
        do {
            self = try JSONDecoder().decode(JSONRPCRequest.self, from: data)
        } catch {
            throw JSONRPCError(.invalidRequest, data: error.localizedDescription)
        }
    }
}

public struct JSONRPCResponse: JSONStringConvertible {
    public let jsonrpc: String
    public let id: String?
    public let result: String
    public let error: JSONRPCError?
    
    public init(id: String?, result: String, error: JSONRPCError?) {
        self.jsonrpc = "2.0"
        self.id = id
        self.result = result
        self.error = error
    }
}

public struct JSONRPCError: Error, JSONStringConvertible {
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
    func toJsonResponse() -> JSONRPCResponse {
        switch self {
        case .success(let response):
            return JSONRPCResponse(id: nil, result: response.json, error: nil)
        case .failure(let error):
            return error.toJsonResponse()
        }
    }
}

extension Error {
    func toJsonResponse() -> JSONRPCResponse {
        return JSONRPCResponse(id: nil, result: "", error: toJsonError())
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

extension Dictionary where Key == String, Value == String {
    func value<T: Decodable>(for key: String) throws -> Optional<T> {
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
    
    func value<T>(for key: String) throws -> T where T: Equatable, T: Decodable{
        let value = self[key]
        if value == nil || value == "<null>" {
            throw JSONRPCError(.invalidParams, data: key)
        }
        
        return try decode(value!, for: key)
    }
    
    private func decode<T: Decodable>(_ value: String, for key: String) throws -> T { //todo decode
            do {
                if let jsonData = value.data(using: .utf8) {
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

// MARK: - Commands implemetation

extension SignCommand: JSONRPCConvertible {
    public convenience init(from parameters: [String : String]) throws {
        let pubKey: Data = try parameters.value(for: "walletIndex") //TODO: rename
        self.init(hashes: try parameters.value(for: "hashes"), walletIndex: .publicKey(pubKey))
    }
}

extension ScanTask: JSONRPCConvertible {
    public convenience init(from parameters: [String : String]) throws {
        self.init(cardVerification: try parameters.value(for: "cardVerification"))
    }
}
