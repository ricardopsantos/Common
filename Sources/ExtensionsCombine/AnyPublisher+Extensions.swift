//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

//

// MARK: - Utils

//

// swiftlint:disable logs_rule_1

public extension Publisher {
    /// Will run the block, and continue with the flow passing the received value on input to output
    func runBlockAndContinue(_ command: @escaping (Output) -> Void) -> Publishers.HandleEvents<Self> {
        handleEvents(receiveOutput: { value in
            command(value)
        })
    }
}

public extension AnyPublisher {
    static func just(_ o: Output) -> Self {
        Just<Output>(o).setFailureType(to: Failure.self).eraseToAnyPublisher()
    }

    static func error(_ f: Failure) -> Self {
        Fail<Output, Failure>(error: f).eraseToAnyPublisher()
    }

    static func empty() -> Self {
        Empty<Output, Failure>().eraseToAnyPublisher()
    }

    static func never() -> Self {
        Empty<Output, Failure>(completeImmediately: false).eraseToAnyPublisher()
    }

    func delay(seconds: TimeInterval) -> AnyPublisher<Output, Failure> {
        delay(milliseconds: seconds * 1000)
    }

    func delay(milliseconds: TimeInterval) -> AnyPublisher<Output, Failure> {
        let timer = Just<Void>(())
            .delay(for: .milliseconds(Int(milliseconds)), scheduler: RunLoop.main)
            .setFailureType(to: Failure.self)
        return zip(timer)
            .map(\.0)
            .eraseToAnyPublisher()
    }
}

//
// MARK: - Retry
//

public extension AnyPublisher {

    // MARK: - Public retry APIs

    typealias RetryPublisherType = Driver<Bool>

    func retry(
        withPublisher: @autoclosure @escaping () -> RetryPublisherType,
        if condition: @escaping (Failure) -> Bool,
        delay: TimeInterval = 1,
        times: Int = 1
    ) -> AnyPublisher<Output, Failure> {
        RetryWithPublisherIf(
            upstream: self,
            condition: condition,
            withPublisher: withPublisher,
            times: times,
            delay: delay
        )
        .eraseToAnyPublisher()
    }

    func retry(
        withClosure: @escaping () -> Void,
        if condition: @escaping (Failure) -> Bool,
        delay: TimeInterval = 1,
        times: Int = 1
    ) -> AnyPublisher<Output, Failure> {
        RetryWithClosureIf(
            upstream: self,
            condition: condition,
            withClosure: withClosure,
            delay: delay,
            times: times
        )
        .eraseToAnyPublisher()
    }

    func retry(
        times: Int = 1,
        if condition: @escaping (Failure) -> Bool,
        delay: TimeInterval = 1
    ) -> AnyPublisher<Output, Failure> {
        RetryIf(
            upstream: self,
            times: times,
            condition: condition,
            delay: delay
        )
        .eraseToAnyPublisher()
    }

    // MARK: - Internal Utility

    private static func makeDelay(_ seconds: TimeInterval)
        -> Publishers.Delay<Just<Void>, RunLoop>
    {
        Just(())
            .delay(
                for: .milliseconds(Int(seconds * 1000)),
                scheduler: RunLoop.main
            )
    }


    // MARK: - RetryWithPublisherIf

    struct RetryWithPublisherIf<P: Publisher>: Publisher {

        public typealias Output = P.Output
        public typealias Failure = P.Failure

        let upstream: P
        let condition: (Failure) -> Bool
        let withPublisher: () -> RetryPublisherType
        let times: Int
        let delay: TimeInterval

        public func receive<S>(subscriber: S)
        where S: Subscriber, Failure == S.Failure, Output == S.Input {
            attempt(times: times)
                .receive(subscriber: subscriber)
        }

        private func attempt(times: Int) -> AnyPublisher<Output, Failure> {
            upstream.catch { error -> AnyPublisher<Output, Failure> in

                // No more retries → fail properly
                guard times > 0, condition(error) else {
                    return Fail(error: error).eraseToAnyPublisher()
                }

                // Retry after delay + side publisher
                return AnyPublisher.makeDelay(delay)
                    .setFailureType(to: Failure.self)
                    .flatMap { withPublisher() }
                    .flatMap { _ in
                        attempt(times: times - 1)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        }
    }

    // MARK: - RetryWithClosureIf

    struct RetryWithClosureIf<P: Publisher>: Publisher {

        public typealias Output = P.Output
        public typealias Failure = P.Failure

        let upstream: P
        let condition: (Failure) -> Bool
        let withClosure: () -> Void
        let delay: TimeInterval
        let times: Int

        public func receive<S>(subscriber: S)
        where S: Subscriber, Failure == S.Failure, Output == S.Input {
            attempt(times: times)
                .receive(subscriber: subscriber)
        }

        private func attempt(times: Int) -> AnyPublisher<Output, Failure> {
            upstream.catch { error -> AnyPublisher<Output, Failure> in

                guard times > 0, condition(error) else {
                    return Fail(error: error).eraseToAnyPublisher()
                }

                // run the closure before retry
                withClosure()

                return AnyPublisher.makeDelay(delay)
                    .setFailureType(to: Failure.self)
                    .flatMap { attempt(times: times - 1) }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        }
    }

    // MARK: - RetryIf

    struct RetryIf<P: Publisher>: Publisher {

        public typealias Output = P.Output
        public typealias Failure = P.Failure

        let upstream: P
        let times: Int
        let condition: (Failure) -> Bool
        let delay: TimeInterval

        public func receive<S>(subscriber: S)
        where S: Subscriber, Failure == S.Failure, Output == S.Input {
            attempt(times: times)
                .receive(subscriber: subscriber)
        }

        private func attempt(times: Int) -> AnyPublisher<Output, Failure> {
            upstream.catch { error -> AnyPublisher<Output, Failure> in

                guard times > 0, condition(error) else {
                    return Fail(error: error).eraseToAnyPublisher()
                }

                return AnyPublisher.makeDelay(delay)
                    .setFailureType(to: Failure.self)
                    .flatMap { attempt(times: times - 1) }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        }
    }
}

public extension Publisher {
    /// This method subscribes to the publisher on the main dispatch queue and receives events on the main dispatch
    /// queue.
    /// It ensures that both the subscription and the event processing happen on the main thread, which is useful for
    /// updating UI elements since
    /// UI updates should always occur on the main thread.
    func subscribeStrategieMainToMain() -> Publishers
        .ReceiveOn<Publishers.SubscribeOn<Self, DispatchQueue>, DispatchQueue>
    {
        subscribe(on: DispatchQueue.main).receive(on: DispatchQueue.main)
    }

    /// This method subscribes to the publisher on a global (background) dispatch queue and receives events on the same
    /// global queue.
    /// It's useful for offloading heavy or time-consuming tasks from the main thread to a background queue for
    /// processing.
    func subscribeStrategieGlobalToGlobal() -> Publishers
        .ReceiveOn<Publishers.SubscribeOn<Self, DispatchQueue>, DispatchQueue>
    {
        subscribe(on: DispatchQueue.global()).receive(on: DispatchQueue.global())
    }

    /// This method subscribes to the publisher on a global (background) dispatch queue and receives events on the main
    /// dispatch queue.
    /// This strategy is useful when you want to perform a task in the background but update the UI with the results on
    /// the main thread.
    func subscribeStrategieGlobalToMain() -> Publishers
        .ReceiveOn<Publishers.SubscribeOn<Self, DispatchQueue>, DispatchQueue>
    {
        subscribe(on: DispatchQueue.global()).receive(on: DispatchQueue.main)
    }

    /// This method subscribes to the publisher on a global (background) dispatch queue with a specified quality of
    /// service (QoS) of .background.
    /// It then receives events on the main dispatch queue.
    /// It's similar to the previous strategy, but it explicitly specifies a lower QoS for the background queue,
    /// indicating that it's
    /// suitable for less critical or less time-sensitive background tasks.
    func subscribeStrategieGlobalBackgroundToMain() -> Publishers
        .ReceiveOn<Publishers.SubscribeOn<Self, DispatchQueue>, DispatchQueue>
    {
        subscribe(on: DispatchQueue.global(), options: .init(qos: .background)).receive(on: DispatchQueue.main)
    }

    /// This method subscribes to the publisher on a global (background) dispatch queue with .background QoS and
    /// receives events on the same global queue.
    /// This strategy is suitable for performing background tasks without the need to switch to the main thread
    /// afterward.
    func subscribeStrategieGlobalBackgroundToGlobal() -> Publishers.ReceiveOn<Publishers.SubscribeOn<
        Self,
        DispatchQueue
    >, DispatchQueue> {
        subscribe(on: DispatchQueue.global(), options: .init(qos: .background)).receive(on: DispatchQueue.global())
    }

    var genericError: AnyPublisher<Self.Output, Error> {
        mapError { (error: Self.Failure) -> Error in error }.eraseToAnyPublisher()
    }

    var underlyingError: Publishers.MapError<Self, Failure> {
        mapError {
            ($0.underlyingError as? Failure) ?? $0
        }
    }

    func errorToNever() -> AnyPublisher<Output, Never> {
        onErrorCompleteV2()
    }

    func onErrorCompleteV1(_ onError: ((Error) -> Void)? = nil) -> AnyPublisher<Output, Never> {
        self
            .catch { error -> AnyPublisher<Output, Never> in
                Common_Logs.error("\(error)", "\(Self.self)")
                onError?(error)
                return .empty()
            }
            .eraseToAnyPublisher()
    }

    func onErrorCompleteV2(withClosure: @escaping () -> Void = {}) -> AnyPublisher<Output, Never> {
        self
            .catch { error -> AnyPublisher<Output, Never> in
                Common_Logs.error("\(error)", "\(Self.self)")
                withClosure()
                return .empty()
            }.eraseToAnyPublisher()
    }
}

//

// MARK: - Debug

//

public extension Publisher {
    func sampleOperator<T>(source: T) -> AnyPublisher<Self.Output, Self.Failure> where T: Publisher,
        T.Output: Equatable,
        T.Failure == Self.Failure
    {
        combineLatest(source)
            .removeDuplicates(by: { first, second -> Bool in first.1 == second.1 })
            .map { first in first.0 }
            .eraseToAnyPublisher()
    }

    func sinkToReceiveValue(_ result: @escaping (Result<Output, Failure>) -> Void) -> AnyCancellable {
        sink(receiveCompletion: { completion in
            switch completion {
            case let .failure(error): result(.failure(error))
            case .finished: _ = ()
            }
        }, receiveValue: { value in
            result(.success(value))
        })
    }
}

//

// MARK: - Driver

//

public typealias Driver<T> = AnyPublisher<T, Never>
public typealias BoolDriver = Driver<Bool>

public extension Publishers {
    static func ZipMany<T, Output, Failure>(_ publishers: [T]) -> AnyPublisher<[Output], Failure>
        where T: Publisher, T.Output == Output, T.Failure == Failure
    {
        if publishers.isEmpty {
            return Just([]).setFailureType(to: Failure.self).eraseToAnyPublisher()
        }

        return publishers
            .map { $0.map { [$0] }.eraseToAnyPublisher() }
            .reduce(Just([]).setFailureType(to: Failure.self).eraseToAnyPublisher()) { combined, next in
                combined.zip(next) { $0 + $1 }
                    .eraseToAnyPublisher()
            }
    }
}

public extension Publisher {
    static func just(_ output: Output) -> Driver<Output> {
        Just(output).eraseToAnyPublisher()
    }

    static func empty() -> Driver<Output> {
        Empty().eraseToAnyPublisher()
    }
}

//

// MARK: - ErrorTracker

//

public typealias ErrorTracker = PassthroughSubject<Error, Never>

public extension Publisher /* where Failure: Error */ {
    func trackError(_ errorTracker: ErrorTracker) -> AnyPublisher<Output, Failure> {
        handleEvents(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                errorTracker.send(error)
            }
        })
        .eraseToAnyPublisher()
    }
}

//

// MARK: - AnyPublisherSampleUsage

//

public enum AnyPublisherSampleUsageAux {
    enum DemoAppErrors: Error, Equatable, Hashable {
        case userIsNotAuthenticated
    }

    static var userIsAuthenticated: Bool = false

    static func sayHelloIfAuthenticated() -> AnyPublisher<String, DemoAppErrors> {
        guard userIsAuthenticated else {
            print("# \(Date()): !! User is not authenticated !!")
            return Fail(error: .userIsNotAuthenticated).eraseToAnyPublisher()
        }
        return Just("# \(Date()): Hello Joe").setFailureType(to: DemoAppErrors.self).eraseToAnyPublisher()
    }

    static func authenticateUserV1() {
        userIsAuthenticated = true
        print("# \(Date()): User was authenticated")
    }

    static func authenticateUserV2() -> AnyPublisher<Void, Never> {
        authenticateUserV1()
        return Just(()).eraseToAnyPublisher()
    }
}

public enum AnyPublisherSampleUsage {
    static var cancelBag = CancelBag()
    static var delay: TimeInterval = 3
    static func exampleRetryWithClosure() -> AnyPublisher<String, AnyPublisherSampleUsageAux.DemoAppErrors> {
        Deferred {
            AnyPublisherSampleUsageAux.sayHelloIfAuthenticated()
        }.eraseToAnyPublisher().retry(
            withClosure: {
                AnyPublisherSampleUsageAux.authenticateUserV1()
            },
            if: { $0 == .userIsNotAuthenticated },
            delay: delay
        ).eraseToAnyPublisher()
    }

    static func exampleRetryWithPublisher() -> AnyPublisher<String, AnyPublisherSampleUsageAux.DemoAppErrors> {
        Deferred {
            AnyPublisherSampleUsageAux.sayHelloIfAuthenticated()
        }.eraseToAnyPublisher()
            .retry(
                withPublisher: AnyPublisherSampleUsageAux.authenticateUserV2()
                    .flatMap { _ in
                        Just(true).eraseToAnyPublisher()
                    }.eraseToAnyPublisher()
                ,
                if: { $0 == .userIsNotAuthenticated },
                delay: delay,
                times: 5
            )
            .eraseToAnyPublisher()
    }

    public static func sampleUsageRetry() {
        // cacheString = "allala"
        if Bool.false {
            exampleRetryWithClosure().sinkToReceiveValue { some in
                print("### RESULT: \(some)")
            }.store(in: cancelBag)
        }

        if Bool.true {
            exampleRetryWithPublisher().sinkToReceiveValue { some in
                print("### RESULT: \(some)")
            }.store(in: cancelBag)
        }
    }
}

// swiftlint:enable logs_rule_1
