//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

public extension Result {
    /// Returns `true` if the result is `.success`.
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    /// Returns `true` if the result is `.failure`.
    var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }

    /// Strongly typed accessor for the success value (if present).
    var value: Success? {
        switch self {
        case let .success(value): return value
        case .failure: return nil
        }
    }

    /// Strongly typed accessor for the failure error (if present).
    var error: Failure? {
        switch self {
        case let .failure(error): return error
        case .success: return nil
        }
    }

    /// String representation of the error (or empty string).
    var errorMessage: String {
        error.map { "\($0)" } ?? ""
    }
}
