//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2019–2024 Ricardo Santos. All rights reserved.
//

import Foundation
import os

/**
 Mastering thread safety in Swift using os_unfair_lock.
 
 On Apple platforms, `os_unfair_lock` is the most performance-efficient lock available.
 It provides low-latency mutual exclusion, ideal for high-contention code paths.
 
 Reference:
 https://betterprogramming.pub/mastering-thread-safety-in-swift-with-one-runtime-trick-260c358a7515
 */

public typealias ThreadingManager = Common.UnfairLockThreadingManager
public typealias ThreadingManagerWithKey = Common.UnfairLockThreadingManagerWithKey

public extension Common {

    // MARK: - Single Lock Manager

    /// A class that provides thread synchronization using `os_unfair_lock`.
    final class UnfairLockThreadingManager {
        // MARK: Private storage
        private let pointer: os_unfair_lock_t

        // MARK: Init / Deinit
        public init() {
            self.pointer = .allocate(capacity: 1)
            self.pointer.initialize(to: os_unfair_lock())
        }

        deinit {
            self.pointer.deinitialize(count: 1)
            self.pointer.deallocate()
        }

        // MARK: Locking API

        /// Locks the unfair lock (blocking).
        public func lock() {
            os_unfair_lock_lock(pointer)
        }

        /// Unlocks the unfair lock.
        public func unlock() {
            os_unfair_lock_unlock(pointer)
        }

        /// Tries to acquire the lock (non-blocking).
        /// - Returns: `true` if lock acquired successfully, otherwise `false`.
        @discardableResult
        public func tryLock() -> Bool {
            os_unfair_lock_trylock(pointer)
        }

        /// Executes the provided closure within a lock.
        /// - Parameter action: The closure to execute.
        /// - Returns: The result of the closure.
        @discardableResult
        @inlinable
        public func execute<T>(_ action: () -> T) -> T {
            lock()
            defer { unlock() }
            return action()
        }

        /// Executes the provided throwing closure within a lock.
        /// - Parameter action: The closure to execute.
        /// - Returns: The result of the closure.
        /// - Throws: Any error thrown by `action`.
        @discardableResult
        @inlinable
        public func tryExecute<T>(_ action: () throws -> T) throws -> T {
            lock()
            defer { unlock() }
            return try action()
        }

    }
}

public extension Common {

    // MARK: - Multi-key Lock Manager

    /// A wrapper for managing multiple unfair locks identified by string keys.
    /// Thread-safe and high-performance.
    final class UnfairLockThreadingManagerWithKey {
        // MARK: Private Storage

        /// Protects access to the internal dictionary.
        private var dictionaryLock = os_unfair_lock_s()

        /// The map of locks for each unique key.
        private var locks: [String: UnsafeMutablePointer<os_unfair_lock>] = [:]

        // MARK: Init / Deinit

        public init() {}

        deinit {
            os_unfair_lock_lock(&dictionaryLock)
            for (_, lockPointer) in locks {
                lockPointer.deinitialize(count: 1)
                lockPointer.deallocate()
            }
            locks.removeAll()
            os_unfair_lock_unlock(&dictionaryLock)
        }

        // MARK: Lock Retrieval

        /// Retrieves or creates a lock for the given key (thread-safe).
        private func lockPointer(for key: String) -> UnsafeMutablePointer<os_unfair_lock> {
            os_unfair_lock_lock(&dictionaryLock)
            defer { os_unfair_lock_unlock(&dictionaryLock) }

            if let lock = locks[key] {
                return lock
            } else {
                let newLockPointer = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
                newLockPointer.initialize(to: os_unfair_lock())
                locks[key] = newLockPointer
                return newLockPointer
            }
        }

        // MARK: Locking API

        /// Locks the unfair lock associated with a key (blocking).
        public func lock(key: String) {
            os_unfair_lock_lock(lockPointer(for: key))
        }

        /// Unlocks the unfair lock associated with a key.
        public func unlock(key: String) {
            os_unfair_lock_unlock(lockPointer(for: key))
        }

        /// Attempts to acquire the lock for the given key (non-blocking).
        /// - Returns: `true` if lock acquired successfully, otherwise `false`.
        @discardableResult
        public func tryLock(key: String) -> Bool {
            os_unfair_lock_trylock(lockPointer(for: key))
        }

        // MARK: Execute Wrappers

        /// Executes a closure within a lock identified by the given key.
        /// - Parameter key: The key of the lock to be used.
        /// - Parameter action: The closure to execute within the lock.
        /// - Returns: The result of the closure.
        @discardableResult
        public func execute<T>(with key: String, _ action: () -> T) -> T {
            lock(key: key)
            defer { unlock(key: key) }
            return action()
        }

        /// Tries to execute a closure within a lock identified by the given key.
        /// - Parameter key: The key of the lock to be used.
        /// - Parameter action: The closure to execute within the lock.
        /// - Returns: The result of the closure if the lock was successfully acquired.
        /// - Throws: `LockError.lockNotAcquired` if the lock was not acquired.
        @discardableResult
        public func tryExecute<T>(with key: String, _ action: () throws -> T) throws -> T {
            guard tryLock(key: key) else {
                throw LockError.lockNotAcquired
            }
            defer { unlock(key: key) }
            return try action()
        }

        // MARK: Error Type

        public enum LockError: Error {
            case lockNotAcquired
        }
    }
}
