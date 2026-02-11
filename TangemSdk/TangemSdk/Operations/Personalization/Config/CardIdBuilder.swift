//
//  CardIdBuilder.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 10/02/2026.
//
import Foundation

enum CardIdBuilder {
    private static let Alf = "ABCDEF0123456789"

    static func createCardId(config: CardConfig) -> String? {
        guard let series = config.series else {
            return nil
        }

        return createCardId(series: series, startNumber: config.startNumber)
    }

    static func createCardId(config: CardConfigV8) -> String? {
        guard let series = config.series else {
            return nil
        }

        return createCardId(series: series, startNumber: config.startNumber)
    }

    private static func createCardId(series: String, startNumber: Int64) -> String? {
        if startNumber <= 0 || (series.count != 2 && series.count != 4) {
            return nil
        }

        if !checkSeries(series) {
            return nil
        }

        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = series.count == 2 ? 13 : 11
        guard let tail = formatter.string(from: NSNumber(value: startNumber)) else {
            return nil
        }

        var cardId = (series + tail).replacingOccurrences(of: " ", with: "")

        guard let firstCidCharacter = cardId.first, let secondCidCharacter = cardId.dropFirst().first else {
            return nil
        }

        if cardId.count != 15 || !Self.Alf.contains(firstCidCharacter) || !Self.Alf.contains(secondCidCharacter) {
            return nil
        }

        cardId += "0"
        var sum: UInt32 = 0
        for i in 0..<cardId.count {
            // get digits in reverse order
            let index = cardId.index(cardId.endIndex, offsetBy: -i-1)
            let cDigit = cardId[index]
            let cDigitInt = cDigit.unicodeScalars.first!.value
            var digit = ("0"..."9").contains(cDigit) ?
            cDigitInt - UnicodeScalar("0").value
            : cDigitInt - UnicodeScalar("A").value

            // every 2nd number multiply with 2
            if i % 2 == 1 {
                digit *= 2
            }

            sum += digit > 9 ? digit - 9 : digit
        }
        let luhn = (10 - sum % 10) % 10
        return cardId[..<cardId.index(cardId.startIndex, offsetBy: 15)] + String(format: "%d", luhn)
    }

    private static func checkSeries(_ series: String) -> Bool {
        let containsList = series.filter { Self.Alf.contains($0) }
        return containsList.count == series.count
    }
}
