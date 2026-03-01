//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

public extension Error {
    /// Extracts the underlying error from `NSError.userInfo`,
    /// but preserves special handling for "offline" errors.
    var underlyingError: Error? {
        let nsError = self as NSError

        // Preserve semantic meaning for no-internet errors.
        if nsError.domain == NSURLErrorDomain, nsError.code == -1009 {
            // "The Internet connection appears to be offline."
            return self
        }

        return nsError.userInfo[NSUnderlyingErrorKey] as? Error
    }
}

public extension Error {
    /// Reflective string of the error, useful for comparing two unrelated error types.
    var reflectedString: String {
        String(reflecting: self)
    }

    /// Compares two errors by their reflected content.
    /// This avoids relying on LocalizedDescription or NSError domain/code only.
    func isEqual(to other: Self) -> Bool {
        reflectedString == other.reflectedString
    }
}

public extension NSError {
    /// Compares two `NSError` instances via:
    /// - domain
    /// - code
    /// - reflected Swift `Error` representation
    ///
    /// Prevents recursion by using `NSObject`'s `isEqual(_:)` instead of calling itself.
    func isEqual(to other: NSError) -> Bool {
        // Compare native NSError fields first.
        guard domain == other.domain, code == other.code else {
            return false
        }

        // Then compare reflected Swift error info for extra detail.
        let lhsError = self as Error
        let rhsError = other as Error

        return lhsError.reflectedString == rhsError.reflectedString
    }
}
