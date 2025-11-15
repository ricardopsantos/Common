//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

public extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }

    var stringAsIntegerOrDecimal: String {
        truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", self)
            : String(self)
    }

    var localeDecimalString: String {
        Double.decimalFormatter.string(from: self as NSNumber) ?? "\(self)"
    }

    func localeCurrencyString(currencyCode: String? = nil) -> String {
        let formatter: NumberFormatter = if let code = currencyCode {
            // Create a per-code cached formatter
            Double.currencyFormatter(for: code)
        } else {
            Double.currencyFormatterDefault
        }

        return formatter.string(from: self as NSNumber) ?? "\(self)"
    }
}

// MARK: - Cached Formatters (Huge performance improvement)

private extension Double {
    /// Cached decimal formatter
    static let decimalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = .current
        f.numberStyle = .decimal
        f.isLenient = true
        return f
    }()

    /// Cached default currency formatter
    static let currencyFormatterDefault: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = .current
        f.numberStyle = .currency
        f.isLenient = true
        return f
    }()

    /// Cached currency formatter per-code
    static var currencyCodeFormatters: [String: NumberFormatter] = [:]

    static func currencyFormatter(for code: String) -> NumberFormatter {
        if let existing = currencyCodeFormatters[code] {
            return existing
        }
        let f = NumberFormatter()
        f.locale = .current
        f.numberStyle = .currency
        f.currencyCode = code
        f.isLenient = true
        currencyCodeFormatters[code] = f
        return f
    }
}
