//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Combine
import Foundation

public extension Just where Output == Void {
    /// Returns a `Just<Void>` publisher with the specified failure type.
    /// Example: `Just.withErrorType(MyError.self)`
    static func withErrorType<E>(_: E.Type) -> AnyPublisher<Void, E> where E: Error {
        Just(())
            .setFailureType(to: E.self)
            .eraseToAnyPublisher()
    }
}

public extension Just {
    /// Returns a `Just<Output>` publisher with the specified failure type.
    /// Example: `Just.withErrorType(123, MyError.self)`
    static func withErrorType<E>(_ value: Output, _: E.Type) -> AnyPublisher<Output, E> where E: Error {
        Just(value)
            .setFailureType(to: E.self)
            .eraseToAnyPublisher()
    }
}
