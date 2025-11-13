//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Combine
import Foundation

public extension Swift.Result {
    var isSuccess: Bool {
        switch self {
        case .success: true
        case .failure: false
        }
    }

    var successUnWrappedValue: Any? {
        switch self {
        case let .success(unWrappedValue): return unWrappedValue
        case .failure: return nil
        }
    }

    var failureUnWrappedValue: Error? {
        switch self {
        case .success: return nil
        case let .failure(error): return error
        }
    }

    var failureUnWrappedStringValue: String {
        if let failureUnWrappedValue {
            "\(failureUnWrappedValue)"
        } else {
            ""
        }
    }
}
