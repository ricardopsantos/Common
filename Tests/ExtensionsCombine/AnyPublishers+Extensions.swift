//
//  AnyPublishers+Extensions.swift
//  Common
//
//  Created by Ricardo Santos on 15/11/2025.
//

import Combine
@testable import Common
import Foundation
import Testing

@Suite(.serialized)
struct AnyPublisherExtensionsTests {
    // MARK: - Cancellable Store (for Testing framework)

    let cancelBag: CancelBag = .init()

    // MARK: - Helper: collect all values from a publisher

    private func collect<T, E: Error>(_ pub: AnyPublisher<T, E>) async -> Result<[T], E> {
        await withCheckedContinuation { cont in
            var values: [T] = []
            pub.sink(
                receiveCompletion: { c in
                    switch c {
                    case .finished:
                        cont.resume(returning: .success(values))
                    case let .failure(error):
                        cont.resume(returning: .failure(error))
                    }
                },
                receiveValue: { v in values.append(v) }
            )
            .store(in: cancelBag)
        }
    }

    // MARK: - Just

    @Test
    func testJust() async {
        let pub = AnyPublisher<Int, TestError>.just(5)
        let result = await collect(pub)
        #expect(result == .success([5]))
    }

    // MARK: - Empty

    @Test
    func testEmpty() async {
        let pub = AnyPublisher<Int, TestError>.empty()
        let result = await collect(pub)
        #expect(result == .success([]))
    }

    // MARK: - Error

    @Test
    func testError() async {
        let e = TestError()
        let pub = AnyPublisher<Int, TestError>.error(e)
        let result = await collect(pub)
        #expect(result == .failure(e))
    }

    // MARK: - Never

    @Test
    func testNeverDoesNotEmit() async {
        let pub = AnyPublisher<Int, TestError>.never()
        // We expect it to not finish — so we check "no values in short time".
        var received = false

        pub.sink(receiveCompletion: { _ in }, receiveValue: { _ in received = true })
            .store(in: cancelBag)

        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        #expect(!received)
    }

    // MARK: - runBlockAndContinue

    @Test
    func testRunBlockAndContinue() async {
        var tapped: Int?
        let pub = Just(10)
            .setFailureType(to: TestError.self)
            .runBlockAndContinue { tapped = $0 }
            .eraseToAnyPublisher()

        let result = await collect(pub)
        #expect(result == .success([10]))
        #expect(tapped == 10)
    }

    // MARK: - Delay

    @Test
    func testDelay() async {
        let start = Date()
        let pub = AnyPublisher<Int, TestError>.just(1).delay(seconds: 0.05)
        let result = await collect(pub)

        let dt = Date().timeIntervalSince(start)
        #expect(result == .success([1]))
        #expect(dt >= 0.045) // approx threshold
    }

    // MARK: - trackError

    @Test
    func testTrackError() async {
        let tracker = PassthroughSubject<Error, Never>()
        var tracked: Error?
        tracker.sink { tracked = $0 }.store(in: cancelBag)

        let pub = AnyPublisher<Int, TestError>.error(TestError()).trackError(tracker)
        let result = await collect(pub)

        #expect(tracked is TestError)
        #expect(result == .failure(TestError()))
    }

    // MARK: - ZipMany

    @Test
    func testZipMany() async {
        let p1 = Just(1).setFailureType(to: TestError.self)
        let p2 = Just(2).setFailureType(to: TestError.self)

        let zipped = Publishers.ZipMany([p1, p2])
        let result = await collect(zipped)

        #expect(result == .success([[1, 2]]))
    }

    // MARK: - RetryIf

    @Test
    func testRetryIf() async {
        var attempts = 0

        let failing = Deferred {
            Future<Int, TestError> { promise in
                attempts += 1
                promise(.failure(TestError()))
            }
        }
        .eraseToAnyPublisher()

        let retried = failing.retry(times: 3, if: { _ in true }, delay: 0)

        let result = await collect(retried.eraseToAnyPublisher())

        #expect(result == .failure(TestError()))
        #expect(attempts == 4) // 1 + 3 retries
    }

    // MARK: - RetryWithClosure

    @Test
    func testRetryWithClosure() async {
        var closureCount = 0
        var attempts = 0

        let pub = Deferred {
            Future<Int, TestError> { promise in
                attempts += 1
                promise(.failure(TestError()))
            }
        }
        .eraseToAnyPublisher()
        .retry(
            withClosure: { closureCount += 1 },
            if: { _ in true },
            delay: 0,
            times: 2
        )
        .eraseToAnyPublisher() // ← REQUIRED FIX

        let result = await collect(pub)

        #expect(result == .failure(TestError()))
        #expect(attempts == 3) // 1 initial + 2 retries
        #expect(closureCount == 2) // closure runs before each retry
    }

    // MARK: - RetryWithPublisher

    @Test
    func testRetryWithPublisher() async {
        var auth = false
        var attempts = 0

        // Retry helper: emits Bool
        let p = { Just(true).eraseToAnyPublisher() }

        let pub = Deferred {
            Future<Int, TestError> { promise in
                attempts += 1
                if auth {
                    promise(.success(7))
                } else {
                    promise(.failure(TestError()))
                }
            }
        }
        .eraseToAnyPublisher()
        .retry(
            withPublisher: p(),
            if: { _ in true },
            delay: 0.01,
            times: 3
        )
        .eraseToAnyPublisher() // ← REQUIRED FIX

        // Flip auth after a tiny delay so retry will eventually succeed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
            auth = true
        }

        let result = await collect(pub)

        #expect(result == .success([7]))
        #expect(attempts >= 2) // first fails, retry succeeds
    }
}
