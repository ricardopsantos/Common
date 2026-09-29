//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

//
// https://betterprogramming.pub/mastering-thread-safety-in-swift-with-one-runtime-trick-260c358a7515
//
public extension Common_PropertyWrappers {
    /**
     The property wrapper ensures that access to its internal value is synchronized.
     It uses an instance of Common.UnfairLockManager to provide mutual exclusion, preventing data races and ensuring thread safety.
     */
    @propertyWrapper
    final class ThreadSafeUnfairLock<T> {
        private let lock = Common.UnfairLockThreadingManager()
        private var value: T

        public init(wrappedValue: T) {
            value = wrappedValue
        }

        public var projectedValue: ThreadSafeUnfairLock<T> { self }

        // swiftlint:disable implicit_getter
        public var wrappedValue: T {
            get {
                lock.lock(); defer { self.lock.unlock() }
                return value
            }
            _modify {
                lock.lock(); defer { self.lock.unlock() }
                yield &value
            }
        }

        // swiftlint:enable implicit_getter

        public func read<V>(_ f: (T) -> V) -> V {
            lock.lock(); defer { self.lock.unlock() }
            return f(value)
        }

        @discardableResult
        public func write<V>(_ f: (inout T) -> V) -> V {
            lock.lock(); defer { self.lock.unlock() }
            return f(&value)
        }
    }
}

public extension Common_PropertyWrappers {
    /**
     The property wrapper ensures that access to its underlying value is synchronized,
     preventing concurrent read and write operations from causing data races or inconsistent states.
     It uses a DispatchQueue configured for concurrent access to manage thread safety.

     Like any lock-backed wrapper, individual `get`/`set` are atomic, but a compound
     operation performed externally (e.g. `wrapper.value += 1`) is NOT atomic — it is a
     separate get followed by a separate set, so concurrent writers can still lose
     updates in between. Use `read(_:)`/`write(_:)` (via the `$` projection) to perform
     an atomic read-modify-write.
     */
    @propertyWrapper
    struct ThreadSafeDispatchQueue<T> {
        /// Reference box so the value is shared (not duplicated) across any copies of
        /// this struct — copies of `ThreadSafeDispatchQueue` still synchronize on the
        /// same underlying storage.
        private final class Box {
            var value: T
            init(_ value: T) { self.value = value }
        }

        private let synchronizedQueue = DispatchQueue
            .synchronizedQueue(label: "\(Common.self)_\(T.self)_\(UUID().uuidString)")
        private let box: Box

        public init(wrappedValue value: T) {
            box = Box(value)
        }

        /// The underlying value wrapped by the bindable state.
        /// The property that stores the wrapped value of the property. It is the value that is accessed when the
        /// property is read or written.
        public var wrappedValue: T {
            get { synchronizedQueue.sync { box.value } }
            set { synchronizedQueue.sync(flags: .barrier) { box.value = newValue } }
        }

        public var projectedValue: ThreadSafeDispatchQueue<T> { self }

        /// Atomic read.
        public func read<V>(_ f: (T) -> V) -> V {
            synchronizedQueue.sync { f(box.value) }
        }

        /// Atomic read-modify-write — use this instead of `wrapper.value += 1`, which
        /// is two separate (individually-atomic, but not jointly-atomic) operations.
        @discardableResult
        public func write<V>(_ f: (inout T) -> V) -> V {
            synchronizedQueue.sync(flags: .barrier) { f(&box.value) }
        }
    }
}
