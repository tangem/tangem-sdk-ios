//
//  MaskBuilder.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
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