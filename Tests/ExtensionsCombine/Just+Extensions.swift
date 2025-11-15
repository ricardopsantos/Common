//
//  JustWithErrorTypeTests.swift
//  Common
//
//  Created by Ricardo Santos on 15/11/2025.
//


import Testing
import Combine
@testable import Common

@Suite
struct JustWithErrorTypeTests {

    // MARK: - Helpers

    /// Simple sink helper to extract the value from AnyPublisher synchronously.
    private func getValue<T, E: Error>(
        from publisher: AnyPublisher<T, E>
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            publisher.sink(
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
    }

    // MARK: - Tests

    @Test
    func testWithErrorTypeValueOutput() async throws {
        let publisher = Just.withErrorType(123, TestError.self)

        let value = try await getValue(from: publisher)

        #expect(value == 123)
    }

    @Test
    func testWithErrorTypeVoidOutput() async throws {
        let publisher = Just<Void>.withErrorType(TestError.self)

        let value = try await getValue(from: publisher)

        #expect(value == ())
    }

    @Test
    func testFailureTypeIsCorrect() {
        let pub = Just.withErrorType(99, TestError.self)

        typealias PubType = AnyPublisher<Int, TestError>
        #expect(pub is PubType)
    }

    @Test
    func testVoidFailureTypeIsCorrect() {
        let pub = Just<Void>.withErrorType(TestError.self)

        typealias PubType = AnyPublisher<Void, TestError>
        #expect(pub is PubType)
    }

    @Test
    func testPublisherNeverFails() async throws {
        // Even though it has an error type, Just never fails.
        let pub = Just.withErrorType("Hello", TestError.self)

        let value = try await getValue(from: pub)

        #expect(value == "Hello")
    }
}

// MARK: - Local Combine cancellables for tests

private final class Cancellables {
    static var shared = Set<AnyCancellable>()
}
