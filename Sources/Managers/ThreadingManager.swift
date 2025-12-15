//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2019–2024 Ricardo Santos. All rights reserved.
//

import Foundation
import os

public extension Common {
    static func synced<T>(_ lock: Any, closure: () -> T) -> T {
        if let nsLock = lock as? NSLock {
            return syncedNSLock(nsLock, closure: closure)
        } else {
            return syncObjc(lock, closure: closure)
        }
    }

    // MARK: - Objective-C sync implementation

    // ----------------------------------------------------------

    /// Synchronizes access to a critical section using Objective-C runtime
    /// (`objc_sync_enter` / `objc_sync_exit`).
    ///
    /// ### When to use this
    /// Use **only when you must lock on an arbitrary class instance**, especially legacy
    /// Objective-C code or APIs expecting `AnyObject`.
    ///
    /// ### When *not* to use this
    /// - Do NOT use with value types (structs / enums) — it will crash at runtime.
    /// - Do NOT use this for new Swift code — prefer `NSLock`.
    ///
    /// It works by using the *identity* of the reference type as a lock token.
    ///
    /// - Parameters:
    ///   - lock: A reference-type object. Must NOT be a value type.
    ///   - closure: Critical section.
    /// - Returns: Result of the closure.
    static func syncObjc<T>(_ lock: Any, closure: () -> T) -> T {
        objc_sync_enter(lock)
        let result = closure()
        objc_sync_exit(lock)
        return result
    }

    // MARK: - NSLock implementation

    // ----------------------------------------------------------

    /// Synchronizes access to a critical section using a Swift-native `NSLock`.
    ///
    /// ### When to use this (recommended)
    /// - **Preferred for Swift code.**
    /// - Best choice for high-performance locking.
    /// - Suitable for frequently accessed shared state.
    /// - Safe, predictable, and works well under contention.
    ///
    /// ### When *not* to use this
    /// - Do not use when you need reentrant locking (the same thread locking twice),
    ///   use `NSRecursiveLock` instead.
    /// - Do not use when locking on arbitrary objects (use `syncedV1` then).
    ///
    /// This implementation is straightforward and avoids heuristics or warnings.
    ///
    /// - Parameters:
    ///   - lock: An `NSLock` instance.
    ///   - closure: Critical section.
    /// - Returns: Result of the closure.
    static func syncedNSLock<T>(_ lock: NSLock, closure: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return closure()
    }

    /// NSLock cannot be locked again by the same thread.
    /// NSRecursiveLock can
    static func syncedReEntrantNSLock<T>(_ lock: NSRecursiveLock, closure: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return closure()
    }
}

//

// MARK: - Lock Manager : os_unfair_lock_lock

//

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
    /// A class that provides thread synchronization using `os_unfair_lock`.
    final class UnfairLockThreadingManager {
        private let pointer: os_unfair_lock_t

        public init() {
            pointer = .allocate(capacity: 1)
            pointer.initialize(to: os_unfair_lock())
        }

        deinit {
            self.pointer.deinitialize(count: 1)
            self.pointer.deallocate()
        }

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

// MARK: - Multi-key Lock Manager

public extension Common {
    /// A wrapper for managing multiple unfair locks identified by string keys.
    /// Thread-safe and high-performance.
    final class UnfairLockThreadingManagerWithKey {
        /// Protects access to the internal dictionary.
        private var dictionaryLock = os_unfair_lock_s()

        /// The map of locks for each unique key.
        private var locks: [String: UnsafeMutablePointer<os_unfair_lock>] = [:]

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
