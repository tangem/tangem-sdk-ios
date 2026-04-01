//
//  CardIdBuilder.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 10/02/2026.
//
import Foundation

enum CardIdBuilder {
    private static let Alf = "ABCDEF0123456789"

    // MARK: - Convenience entry points

    static func createCardId(config: CardConfig, cardNumber: Int64 = 0) -> String? {
        createCardId(
            series: config.series,
            startNumber: config.startNumber,
            cardNumber: cardNumber,
            numberFormat: config.numberFormat
        )
    }

    static func createCardId(config: CardConfigV8, cardNumber: Int64 = 0) -> String? {
        createCardId(
            series: config.series,
            startNumber: config.startNumber,
            cardNumber: cardNumber,
            numberFormat: config.numberFormat
        )
    }

    // MARK: - Main method

    static func createCardId(
        series: String?,
        startNumber: Int64,
        cardNumber: Int64 = 0,
        numberFormat: String = ""
    ) -> String? {
        guard let series,
              startNumber >= 0,
              cardNumber >= 0,
              checkSeries(series) else {
            return nil
        }

        if numberFormat.isEmpty {
            return createSimpleCardId(
                series: series,
                startNumber: startNumber + cardNumber
            )
        } else {
            return createFormattedCardId(
                series: series,
                startNumber: startNumber,
                cardNumber: cardNumber,
                numberFormat: numberFormat
            )
        }
    }

    // MARK: - Private

    private static func createSimpleCardId(series: String, startNumber: Int64) -> String? {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.usesGroupingSeparator = false
        formatter.minimumIntegerDigits = series.count == 2 ? 13 : 11
        guard let tail = formatter.string(from: NSNumber(value: startNumber)) else {
            return nil
        }

        let cardId = series + tail
        return completeCardId(cardId)
    }

    private static func createFormattedCardId(
        series: String,
        startNumber: Int64,
        cardNumber: Int64,
        numberFormat: String
    ) -> String? {
        guard numberFormat.isEmpty || numberFormat.allSatisfy({ $0 == "N" || $0 == "R" || Alf.contains($0) }) else {
            return nil
        }

        let tailLength = 15 - series.count

        guard numberFormat.count == tailLength else {
            return nil
        }

        let actualNumber = startNumber + cardNumber

        guard String(actualNumber).count <= tailLength else {
            return nil
        }

        let paddedNumber = String(String(repeating: "0", count: tailLength) + String(actualNumber)).suffix(tailLength)
        var numberIterator = paddedNumber.reversed().makeIterator()
        var randomIterator = numberFormat.filter { $0 == "R" }.map { _ in
            Character(String(Int.random(in: 0 ... 9)))
        }.reversed().makeIterator()

        let tail = String(numberFormat.reversed().map { char -> Character in
            switch char {
            case "N": return numberIterator.next() ?? "0"
            case "R": return randomIterator.next() ?? "0"
            default: return char
            }
        }.reversed())

        return completeCardId(series + tail)
    }

    private static func completeCardId(_ cardId: String) -> String? {
        guard cardId.count == 15,
              cardId.prefix(2).allSatisfy({ Alf.contains($0) }) else {
            return nil
        }

        let sum = (cardId + "0").reversed().enumerated().reduce(UInt32(0)) { sum, pair in
            let (i, char) = pair
            var digit = char.isNumber
                ? char.wholeNumberValue.map(UInt32.init) ?? 0
                : char.unicodeScalars.first!.value - UnicodeScalar("A").value

            if i % 2 == 1 { digit *= 2 }

            return sum + (digit > 9 ? digit - 9 : digit)
        }

        let luhn = (10 - sum % 10) % 10
        return cardId + String(luhn)
    }

    private static func checkSeries(_ series: String) -> Bool {
        guard series.count == 2 || series.count == 4 else {
            return false
        }

        let containsList = series.filter { Self.Alf.contains($0) }
        return containsList.count == series.count
    }
}
