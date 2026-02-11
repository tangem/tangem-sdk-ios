//
//  MaskBuilder.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 10/02/2026.
//


class MaskBuilder<T: OptionSet> where T.RawValue: FixedWidthInteger {
    private var rawValue: T.RawValue = 0

    func add(_ mask: T) {
        rawValue |= mask.rawValue
    }
    
    func build() -> T {
        return .init(rawValue: rawValue)
    }
}