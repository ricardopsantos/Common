//
//  AnyPublisher+Async.swift
//  Common
//
//  Created by Ricardo Santos on 16/11/2025.
//

import Combine
@testable import Common
import Testing

@Suite(.serialized)
struct AsyncPublisherAttachedDetachedTests {
    // MARK: - Test Helpers

    struct DummyError: Error {}

    /// emits a value then completes
    func goodPublisher(_ value: Int) -> AnyPublisher<Int, Error> {
        Just(value)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    /// A publisher that emits specific values then finishes.
    func goodPublisher(_ values: [Int]) -> AnyPublisher<Int, Never> {
        values.publisher.eraseToAnyPublisher()
    }

    /// immediately fails
    func failingPublisher() -> AnyPublisher<Int, Error> {
        Fail(outputType: Int.self, failure: DummyError())
            .eraseToAnyPublisher()
    }

    /// completes without emitting values
    func emptyPublisher() -> AnyPublisher<Int, Error> {
        Empty<Int, Error>().eraseToAnyPublisher()
    }

    // MARK: - asyncAttached

    @Test
    func testAsyncAttachedSuccess() async throws {
        let pub = goodPublisher(999)
        let value = try await pub.asyncAttached(sender: "testAsyncAttachedSuccess")
        #expect(value == 999)
    }

    @Test
    func testAsyncAttachedFailure() async {
        let pub = failingPublisher()

        do {
            _ = try await pub.asyncAttached(sender: "testAsyncAttachedFailure")
            #expect(false, "Should throw")
        } catch {
            #expect(error is DummyError)
        }
    }

    @Test
    func testAsyncAttachedFinishedWithoutValue() async {
        let pub = emptyPublisher()

        do {
            _ = try await pub.asyncAttached(sender: "testAsyncAttachedFinishedWithoutValue")
            #expect(false, "Should have thrown AsyncError.finishedWithoutValue")
        } catch {
            #expect(error.finishedWithoutValue)
        }
    }

    // MARK: - asyncDetached

    /// Detached tasks should run independently and return the correct value.
    @Test
    func testAsyncDetachedSuccess() async throws {
        let pub = goodPublisher(1234)

        let value = try await pub.asyncDetached(sender: "testAsyncDetachedSuccess")
        #expect(value == 1234)
    }

    /// Detached tasks also propagate errors.
    @Test
    func testAsyncDetachedFailure() async {
        let pub = failingPublisher()

        do {
            _ = try await pub.asyncDetached(sender: "testAsyncDetachedFailure")
            #expect(false, "Should throw")
        } catch {
            #expect(error is DummyError)
        }
    }

    /// Detached tasks also throw finishedWithoutValue.
    @Test
    func testAsyncDetachedFinishedWithoutValue() async {
        let pub = emptyPublisher()

        do {
            _ = try await pub.asyncDetached(sender: "testAsyncDetachedFinishedWithoutValue")
            #expect(false, "Should throw AsyncError.finishedWithoutValue")
        } catch {
            #expect(error.finishedWithoutValue)
        }
    }

    // MARK: - Detached independence test (for dummies)

    /// “For dummies”: detached tasks do NOT block the parent.
    /// They run independently.
    @Test
    func testAsyncDetachedDoesNotBlock() async throws {
        // We measure the order of events:
        //   1. parent started
        //   2. detached task returns
        //   3. parent continues

        let pub = goodPublisher(1)

        var log: [String] = []

        // Parent started
        log.append("parent_start")

        async let detachedRequest: Int = pub.asyncDetached(sender: "testAsyncDetachedDoesNotBlock")

        // Parent continues immediately (this is what a detached task means)
        log.append("parent_continues")

        // Wait for detached task to finish
        let value = try await detachedRequest
        log.append("detached_finished_\(value)")

        #expect(log == [
            "parent_start",
            "parent_continues",
            "detached_finished_1",
        ])
    }

    //

    // MARK: - StreamTests

    //

    @Test
    func testStreamValuesArriveCorrectly() async {
        let pub = goodPublisher([1, 2, 3]).eraseToAnyPublisher()

        var collected = [Int]()

        for await v in pub.stream() {
            collected.append(v)
        }

        #expect(collected == [1, 2, 3])
    }

    @Test
    func testStreamOrderPreserved() async {
        let pub = goodPublisher([7, 8, 9])

        var order = [Int]()

        for await v in pub.stream() {
            order.append(v)
        }

        #expect(order == [7, 8, 9])
    }
}
