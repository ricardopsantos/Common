//
//  Future+Extensions.swift
//  Common
//

import Combine
@testable import Common
import Foundation
import Testing

@Suite(.serialized)
struct FutureAsyncTests {
    /// Async function that succeeds after a short delay
    func asyncSuccess(_ value: Int) async throws -> Int {
        try await Task.sleep(nanoseconds: 5_000_000)
        return value
    }

    /// Async function that fails after a short delay
    func asyncFailure() async throws -> Int {
        try await Task.sleep(nanoseconds: 5_000_000)
        throw TestError()
    }

    // MARK: - Tests

    @Test
    func testFutureAsyncSuccess() async throws {
        let future = Future { try await asyncSuccess(10) }

        let value = try await withCheckedThrowingContinuation { continuation in
            future.sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        continuation.resume(throwing: error)
                    }
                },
                receiveValue: { output in
                    continuation.resume(returning: output)
                }
            )
            .store(in: &Cancellables.shared)
        }

        #expect(value == 10)
    }

    @Test
    func testFutureAsyncFailure() async {
        let future = Future { try await asyncFailure() }

        do {
            _ = try await withCheckedThrowingContinuation { continuation in
                future.sink(
                    receiveCompletion: { completion in
                        if case let .failure(error) = completion {
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { output in
                        continuation.resume(returning: output)
                    }
                )
                .store(in: &Cancellables.shared)
            }

            #expect(false, "Should throw")
        } catch {
            #expect(error is TestError)
        }
    }

    @Test
    func testFutureRunsOnlyOnce() async throws {
        var executionCount = 0

        let future = Future { () async throws -> Int in
            executionCount += 1
            return 1
        }

        // Two subscriptions — Future must run only once.
        _ = try await subscribe(future)
        _ = try await subscribe(future)

        #expect(executionCount == 1)
    }

    @Test
    func testFutureIsAsynchronous() async throws {
        let future = Future { try await asyncSuccess(5) }

        let start = Date()
        _ = try await subscribe(future)
        let elapsed = Date().timeIntervalSince(start)

        // Should take at least ~5ms due to the async delay
        #expect(elapsed >= 0.004)
    }

    // MARK: - Minimal Combine subscription helper (not testing anything else)

    private func subscribe(
        _ future: Future<Int, Error>
    ) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            future.sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        continuation.resume(throwing: error)
                    }
                },
                receiveValue: { value in
                    continuation.resume(returning: value)
                }
            )
            .store(in: &Cancellables.shared)
        }
    }
}

// MARK: - Local cancellable store

/// Minimal shared storage for Combine subscriptions during tests.
private enum Cancellables {
    static var shared = Set<AnyCancellable>()
}
