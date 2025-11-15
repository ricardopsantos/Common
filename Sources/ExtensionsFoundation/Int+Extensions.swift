//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

public extension Int {
    /// Returns `true` if the integer is non-zero.
    var boolValue: Bool { self != 0 }

    /// Returns the integer formatted using the user's current locale.
    /// Example: "1,234" or "1.234" depending on region settings.
    var localeString: String {
        NumberFormatter.localizedDecimal.string(from: self as NSNumber) ?? "\(self)"
    }
}

private extension NumberFormatter {
    /// Cached NumberFormatter to avoid constant re-allocation.
    /// NumberFormatter is expensive — caching improves performance dramatically.
    static let localizedDecimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        formatter.isLenient = true
        return formatter
    }()
}
