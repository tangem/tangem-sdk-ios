//
//  OmitCodingWrappers.swift
//
//
//  Created by PJ Fechner on 7/7/20.
//

import Foundation

//MARK: - OmitWrappers


/// Add this to an Optional Property to not included it when Encoding or Decoding
@propertyWrapper
public struct OmitEncoding<WrappedType: Codable>: OmitableFromEncoding {
    public var wrappedValue: WrappedType
    public init(wrappedValue: WrappedType) {
        self.wrappedValue = wrappedValue
    }
}

/// Add this to an Optional Property to not included it when Encoding or Decoding
@propertyWrapper
public struct OmitDecoding<WrappedType: Decodable>: OmitableFromDecoding {

    public var wrappedValue: WrappedType?
    public init(wrappedValue: WrappedType?) {
        self.wrappedValue = wrappedValue
    }
}

/// Add this to an Optional Property to not included it when Encoding or Decoding
@propertyWrapper
public struct OmitCoding<WrappedType: Codable>: OmitableFromCoding {

    public var wrappedValue: WrappedType?
    public init(wrappedValue: WrappedType?) {
        self.wrappedValue = wrappedValue
    }
}


//MARK: - OmitCoding protocols

/// Protocol to indicate instances should be skipped when encoding
public protocol OmitableFromEncoding: Codable {
    associatedtype WrappedType: Decodable
    init(wrappedValue: WrappedType)
}

extension KeyedDecodingContainer {
    // This is used to override the default decoding behavior for OptionalCodingWrapper to allow a value to avoid a missing key Error
    public func decode<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T where T: OmitableFromDecoding {
        return try decodeIfPresent(T.self, forKey: key) ?? T(wrappedValue: nil)
    }
}

extension KeyedEncodingContainer {
    // Used to make make sure OmitableFromEncoding never encodes a value
    public mutating func encode<T>(_ value: T, forKey key: KeyedEncodingContainer<K>.Key) throws where  T: OmitableFromEncoding {
        return
    }
}

extension OmitableFromEncoding {
    // This shouldn't ever be called since KeyedEncodingContainer should skip it due to the included extension
    public func encode(to encoder: Encoder) throws { return }
    
    public init(from decoder: Decoder) throws {
        let value = try WrappedType(from: decoder)
        self.init(wrappedValue: value)
    }
}

/// Protocol to indicate instances should be skipped when decoding
public protocol OmitableFromDecoding: Decodable {
    associatedtype WrappedType: ExpressibleByNilLiteral
    init(wrappedValue: WrappedType)
}

extension OmitableFromDecoding {
    /// Inits the value with nil
    public init(from decoder: Decoder) throws {
        self.init(wrappedValue: nil)
    }
}

/// Combination of OmitableFromEncoding and OmitableFromDecoding
typealias OmitableFromCoding = OmitableFromEncoding & OmitableFromDecoding

//MARK: - Conditional Equatable Conformance

extension OmitEncoding: Equatable where WrappedType: Equatable { }
extension OmitDecoding: Equatable where WrappedType: Equatable { }
extension OmitCoding: Equatable where WrappedType: Equatable { }

//MARK: - Conditional Hashable Conformance

extension OmitEncoding: Hashable where WrappedType: Hashable { }
extension OmitDecoding: Hashable where WrappedType: Hashable { }
extension OmitCoding: Hashable where WrappedType: Hashable { }
