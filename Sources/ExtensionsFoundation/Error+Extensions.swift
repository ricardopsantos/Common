//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

public extension Error {
    var underlyingError: Error? {
        let nsError = self as NSError
        if nsError.domain == NSURLErrorDomain, nsError.code == -1009 {
            // "The Internet connection appears to be offline."
            return self
        }
        return nsError.userInfo[NSUnderlyingErrorKey] as? Error
    }
}

public extension Error {
    var reflectedString: String {
        String(reflecting: self)
    }

    func isEqual(to: Self) -> Bool {
        reflectedString == to.reflectedString
    }
}

public extension NSError {
    func isEqual(to: NSError) -> Bool {
        let lhs = self as Error
        let rhs = to as Error
        return isEqual(to) && lhs.reflectedString == rhs.reflectedString
    }
}
