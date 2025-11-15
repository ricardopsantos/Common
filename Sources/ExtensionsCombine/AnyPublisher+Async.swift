//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos.
//  Improved with safety, clarity, and documentation.
//

import Combine
import Foundation

// MARK: - Error Helpers

public extension Error {
    /// Returns true if the async publisher finished with no value.
    /// Useful when converting Combine → async/await.
    var finishedWithoutValue: Bool {
        (self as? AsyncError) == .finishedWithoutValue
    }
}

/// Represents a Combine publisher that completed without emitting a value.
public enum AsyncError: Error {
    case finishedWithoutValue
}

// MARK: - AnyPublisher → async/await helper

public extension AnyPublisher {
    /// Convert publisher to a value using async/await.
    @discardableResult
    func async(sender: String = #function) async throws -> Output {
        try await asyncAttached(sender: sender)
    }

    /// Same as `.async()` but:
    ///
    /// - Runs on the same async context (NOT detached)
    /// - Parent tasks will *wait* for this publisher to finish
    ///
    /// This wraps Combine `sink` inside a checked continuation.
    @discardableResult
    func asyncAttached(sender: String) async throws -> Output {
        try await asyncJust(sender: sender, firstEmission: true)
    }

    /// Runs the publisher in a detached child task (completely independent).
    /// parent code does NOT wait for this to finish.
    @discardableResult
    func asyncDetached(sender: String = #function) async throws -> Output {
        try await Task.detached {
            try await self.asyncAttached(sender: sender)
        }.value
    }

    /// Convert a publisher into a single async value.
    ///
    /// - firstEmission = true → take `.first()`
    /// - firstEmission = false → take `.last()`
    ///
    /// This is where the actual Combine → async bridge happens.
    @discardableResult
    func asyncJust(sender: String, firstEmission: Bool = true) async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in

            var cancellable: AnyCancellable?
            var finishedWithoutValue = true

            // Choose first or last value
            let source = firstEmission
                ? self.first().eraseToAnyPublisher()
                : self.last().eraseToAnyPublisher()

            cancellable = source.sink { completion in

                switch completion {
                case .finished:
                    if finishedWithoutValue {
                        Common_Logs.error("\(sender) : Finished without value.", "\(Self.self)")
                        continuation.resume(throwing: AsyncError.finishedWithoutValue)
                    }
                case let .failure(error):
                    continuation.resume(throwing: error)
                }

                cancellable?.cancel()
                cancellable = nil

            } receiveValue: { value in
                finishedWithoutValue = false
                continuation.resume(returning: value)
                cancellable?.cancel()
                cancellable = nil
            }
        }
    }
}

// MARK: - AsyncStream for Never-Failure Publishers

public extension AnyPublisher where Failure == Never {
    /// Convert a Combine publisher into AsyncStream.
    /// Works like an async `for await` loop.
    func stream(canFail: Bool = false) -> AsyncStream<Output> {
        AsyncStream { continuation in

            let cancellable = self.sink { completion in

                switch completion {
                case .finished:
                    continuation.finish()
                case .failure:
                    if canFail {
                        // This will never happen, but included for completeness
                        continuation.finish()
                    } else {
                        continuation.finish()
                    }
                }

            } receiveValue: { value in
                continuation.yield(value)
            }

            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}

// MARK: - AsyncThrowingStream

public extension AnyPublisher where Failure == Error {
    /// Convert Combine publisher into AsyncThrowingStream.
    /// a stream that can produce values OR throw errors.
    var throwingStream: AsyncThrowingStream<Output, Failure> {
        AsyncThrowingStream { continuation in

            let cancellable = self.sink { completion in
                switch completion {
                case .finished:
                    continuation.finish()
                case let .failure(error):
                    continuation.finish(throwing: error)
                }
            } receiveValue: { value in
                continuation.yield(value)
            }

            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}
