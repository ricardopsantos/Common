//
//  Just+Extensions.swift
//  Common
//
//  Created by Ricardo Santos on 15/11/2025.
//

import Combine
@testable import Common
import Testing

@Suite
struct JustWithErrorTypeTests {
    // MARK: - Tests

    @Test
    func testWithErrorTypeValueOutput() async throws {
        let publisher = Just.withErrorType(123, TestError.self)
        let value = try await publisher.async()
        #expect(value == 123)
    }

    @Test
    func testWithErrorTypeVoidOutput() async throws {
        let publisher = Just<Void>.withErrorType(TestError.self)
        let value: Void = try await publisher.async()
        #expect(value == ())
    }

    @Test
    func testFailureTypeIsCorrect() {
        // If this compiles, the type is correct.
        let pub = Just.withErrorType(99, TestError.self)
        typealias Expected = AnyPublisher<Int, TestError>
        let _: Expected = pub // compile-time assertion
        #expect(true) // always true (success = compiles)
    }

    @Test
    func testVoidFailureTypeIsCorrect() {
        let pub = Just<Void>.withErrorType(TestError.self)

        // compile-time type check
        typealias Expected = AnyPublisher<Void, TestError>
        let _: Expected = pub

        #expect(true)
    }

    @Test
    func testPublisherNeverFails() async throws {
        // Just never fails, even with a Failure type.
        let publisher = Just.withErrorType("Hello", TestError.self)

        let value = try await publisher.async()
        #expect(value == "Hello")
    }
}
