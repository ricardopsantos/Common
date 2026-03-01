//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import UIKit

public extension CGFloat {
    var localeString: String {
        Double(self).localeDecimalString
    }

    func localeCurrencyString(currencyCode: String? = nil) -> String {
        Double(self).localeCurrencyString(currencyCode: currencyCode)
    }
}

public extension FloatingPoint {
    /// Converts degrees to radians.
    var degreesToRadians: Self {
        self * .pi / 180
    }
}
