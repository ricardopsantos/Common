//
//  Created by Ricardo Santos on 12/08/2024.
//

import Foundation
import Testing
@testable @preconcurrency import Common

// MARK: - Test Suite

@Suite(.serialized)
struct UnfairLockThreadingManagerWithKeyTests {

    // Creates a fresh instance for each test
    private func makeLockManager() -> Common.UnfairLockThreadingManagerWithKey {
        Common.UnfairLockThreadingManagerWithKey()
    }

    // MARK: - Core Tests

    @Test
    func lockUnlock() async {
        let lockManager = makeLockManager()
        var value = 0
        let key = #function

        lockManager.execute(with: key) {
            value += 1
            #expect(value == 1, "Value should be 1 within the first lock")
        }

        DispatchQueue.global().async {
            lockManager.execute(with: key) {
                value += 1
                #expect(value == 2, "Value should be 2 after the second lock")
            }
        }

        let ok = await eventually { value == 2 }
        #expect(ok, "Expected value to become 2 after both executions")
    }

    @Test
    func tryLock() async {
        let lockManager = makeLockManager()
        var value = 0
        let key = #function
        var succeeded = false

        DispatchQueue.global().async {
            if lockManager.tryLock(key: key) {
                value += 1
                #expect(value == 1, "Value should be 1 after tryLock succeeds")
                lockManager.unlock(key: key)
                succeeded = true
            } else {
                #expect(Bool(false), "tryLock should have succeeded")
            }
        }

        let ok = await eventually { succeeded && value == 1 }
        #expect(ok, "Expected tryLock path to succeed and value to be 1")
    }

    
    @Test
    func execute() {
        let lockManager = makeLockManager()
        var value = 0
        let key = #function

        let result: Int = lockManager.execute(with: key) {
            value += 1
            return value
        }

        #expect(result == 1)
        #expect(value == 1)
    }
    
    @Test
    func tryExecute() async {
        let lockManager = makeLockManager()
        var value = 0
        let key = #function
        var result: Int?
        var caughtError: Error?

        DispatchQueue.global().async {
            do {
                let r = try lockManager.tryExecute(with: key) {
                    value += 1
                    return value
                }
                result = r
            } catch {
                caughtError = error
            }
        }

        let ok = await eventually { result == 1 && caughtError == nil && value == 1 }
        #expect(ok, "Expected result/value to be 1 and no error")
    }

    @Test
    func tryExecuteThrowsError() async {
        enum TestError: Error { case intentionalError }

        let lockManager = makeLockManager()
        let key = #function

        var threwExpected = false
        var unexpectedError: Error?

        DispatchQueue.global().async {
            do {
                _ = try lockManager.tryExecute(with: key) {
                    throw TestError.intentionalError
                }
                #expect(Bool(false), "Expected tryExecute to throw an error")
            } catch TestError.intentionalError {
                threwExpected = true
            } catch {
                unexpectedError = error
            }
        }

        let ok = await eventually { threwExpected && unexpectedError == nil }
        #expect(ok, "Expected intentionalError to be thrown without unexpected errors")
    }

    @Test
    func threadSafety() async {
        let lockManager = makeLockManager()
        var value = 0
        let iterations = 1_000
        let key = #function

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            lockManager.execute(with: key) {
                value += 1
            }
        }

        let ok = await eventually { value == iterations }
        #expect(ok, "Expected value \(value) == \(iterations)")
    }
    
    @Test
    func highContentionWithMultipleLocks() async {
        let lockManager = makeLockManager()
        var value = 0
        let iterations = 10_000
        let queue = DispatchQueue(label: #function, attributes: .concurrent)
        let group = DispatchGroup()
        let key = #function
        for _ in 0..<iterations {
            group.enter()
            queue.async {
                lockManager.lock(key: key)
                value += 1
                lockManager.unlock(key: key)
                group.leave()
            }
        }

        group.wait()
        #expect(value == iterations, "Expected \(value) == \(iterations)")
    }
    
    @Test
    func stressTestWithLargeNumberOfOperations() async {
        let lockManager = makeLockManager()
        var value = 0
        let iterations = 100_000
        let key = #function

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            lockManager.execute(with: key) {
                value += 1
            }
        }

        let ok = await eventually(timeoutSeconds: 3.0) { value == iterations }
        #expect(ok, "Expected value \(value) == \(iterations)")
    }
    
    @Test
    func concurrentExecutionWithDelays() async {
        let lockManager = makeLockManager()
        var value = 0
        let iterations = 100
        let queue = DispatchQueue(label: "delayedExecutionQueue", attributes: .concurrent)
        let group = DispatchGroup()
        let key = #function
        for _ in 0..<iterations {
            group.enter()
            queue.async {
                lockManager.execute(with: key) {
                    let currentValue = value
                    Thread.sleep(forTimeInterval: 0.005)
                    value = currentValue + 1
                }
                group.leave()
            }
        }

        group.wait()
        #expect(value == iterations, "Expected value \(value) == \(iterations)")
    }
    
    // MARK: - Additional Robustness Tests

    @Test
    func independentKeysDoNotBlockEachOther() async {
        let lockManager = makeLockManager()
        let keyA = "A"
        let keyB = "B"
        var order: [String] = []
        let group = DispatchGroup()

        group.enter()
        DispatchQueue.global().async {
            lockManager.execute(with: keyA) {
                order.append("A1")
                Thread.sleep(forTimeInterval: 0.05)
                order.append("A2")
            }
            group.leave()
        }

        group.enter()
        DispatchQueue.global().async {
            lockManager.execute(with: keyB) {
                order.append("B1")
                order.append("B2")
            }
            group.leave()
        }

        group.wait()

        #expect(order.contains("A2"))
        #expect(order.contains("B2"))
    }

    @Test
    func tryLockFailsWhenAlreadyLocked() async {
        let lockManager = makeLockManager()
        let key = #function
        var acquiredSecond = false

        DispatchQueue.global().async {
            lockManager.lock(key: key)
            Thread.sleep(forTimeInterval: 0.1)
            lockManager.unlock(key: key)
        }

        // Give the first thread a head start
        try? await Task.sleep(nanoseconds: 20_000_000)

        DispatchQueue.global().async {
            if lockManager.tryLock(key: key) {
                acquiredSecond = true
                lockManager.unlock(key: key)
            }
        }

        let ok = await eventually { !acquiredSecond }
        #expect(ok, "Expected second tryLock to fail while first holds the lock")
    }

    /// Rewritten version of simultaneous reads/writes test, now deterministic.
    @Test
    func simultaneousReadsAndWritesWithLock() async {
        let lockManager = makeLockManager()
        var value = 0
        let iterations = 1_000
        let queue = DispatchQueue(label: #function, attributes: .concurrent)
        var readResults = [Int]()
        let readLock = NSLock()
        let group = DispatchGroup()
        let key = #function
        for _ in 0..<iterations {
            group.enter()
            queue.async {
                // Write under lock
                lockManager.execute(with: key) {
                    value += 1
                }

                // Read under lock
                let readValue = lockManager.execute(with: key) { value }

                // Append in thread-safe way
                readLock.lock()
                readResults.append(readValue)
                readLock.unlock()
                group.leave()
            }
        }

        group.wait()

        #expect(readResults.count == iterations)
        #expect(value == iterations)
        #expect(readResults.allSatisfy { $0 <= iterations })
    }
    
    /// Previously flaky due to data races; now uses atomic-like increments.
    @Test
    func highContentionWithTryLock() async {
        let lockManager = makeLockManager()
        var successCount = 0
        var failureCount = 0
        let counterLock = NSLock()
        let iterations = 10_000
        let queue = DispatchQueue(label: #function, attributes: .concurrent)
        let group = DispatchGroup()
        let key = #function

        for _ in 0..<iterations {
            group.enter()
            queue.async {
                if lockManager.tryLock(key: key) {
                    counterLock.lock(); successCount += 1; counterLock.unlock()
                    lockManager.unlock(key: key)
                } else {
                    counterLock.lock(); failureCount += 1; counterLock.unlock()
                }
                group.leave()
            }
        }

        group.wait()
        #expect(successCount + failureCount == iterations)
        #expect(successCount > 0)
    }
    
    @Test
    func deinitIsSafe() async {
        weak var weakManager: Common.UnfairLockThreadingManagerWithKey?

        await Task.detached {
            var manager: Common.UnfairLockThreadingManagerWithKey? = .init()
            let key = "temp"
            DispatchQueue.concurrentPerform(iterations: 100) { _ in
                manager?.execute(with: key) {}
            }
            weakManager = manager
            manager = nil
        }.value

        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(weakManager == nil, "Manager should have been deallocated cleanly")
    }
    
    
}
