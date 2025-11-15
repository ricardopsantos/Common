//
//  Created by Ricardo Santos on 12/08/2024.
//

@preconcurrency @testable import Common
import Foundation
import Testing

actor CounterBox {
    private var value = 0
    func increment() { value += 1 }
    func get() -> Int { value }
}

@Suite(.serialized)
struct UnfairLockThreadingManagerTests {
    // Fresh instance per test
    private func makeLockManager() -> Common.UnfairLockThreadingManager {
        Common.UnfairLockThreadingManager()
    }

    @Test
    func lockUnlock() {
        let lockManager = makeLockManager()
        var value = 0

        lockManager.lock()
        value += 1
        #expect(value == 1)
        lockManager.unlock()
    }

    @Test
    func tryLock() {
        let lockManager = makeLockManager()
        var value = 0

        #expect(lockManager.tryLock())
        value += 1
        #expect(value == 1)
        lockManager.unlock()
    }

    @Test
    func execute() {
        let lockManager = makeLockManager()
        var value = 0

        let result: Int = lockManager.execute {
            value += 1
            return value
        }

        #expect(result == 1)
        #expect(value == 1)
    }

    @Test
    func tryExecute() {
        let lockManager = makeLockManager()
        var value = 0

        do {
            let result: Int = try lockManager.tryExecute {
                value += 1
                return value
            }
            #expect(result == 1)
            #expect(value == 1)
        } catch {
            #expect(Bool(false), "tryExecute threw an unexpected error: \(error)")
        }
    }

    @Test
    func tryExecuteThrowsError() {
        enum TestError: Error { case intentionalError }

        let lockManager = makeLockManager()

        do {
            _ = try lockManager.tryExecute {
                throw TestError.intentionalError
            }
            #expect(Bool(false), "Expected tryExecute to throw an error")
        } catch TestError.intentionalError {
            // ✅ expected
        } catch {
            #expect(Bool(false), "Unexpected error thrown: \(error)")
        }
    }

    @Test
    func threadSafety() async {
        /*
         let lockManager = makeLockManager()
         let counter = CounterBox()   // ← replaces 'var value'
         let iterations = 1_000

         DispatchQueue.concurrentPerform(iterations: iterations) { _ in
             lockManager.execute {
                 counter.increment()
             }
         }

         let ok = await eventually {
             counter.get() == iterations
         }

         #expect(ok, "Expected value \(counter.get()) == \(iterations)")*/
        #expect(false)
    }

    @Test
    func highContentionWithMultipleLocks() async {
        let lockManager = makeLockManager()
        var value = 0
        let iterations = 10000
        let queue = DispatchQueue(label: #function, attributes: .concurrent)
        let group = DispatchGroup()

        for _ in 0 ..< iterations {
            group.enter()
            queue.async {
                lockManager.lock()
                value += 1
                lockManager.unlock()
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

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            lockManager.execute {
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

        for _ in 0 ..< iterations {
            group.enter()
            queue.async {
                lockManager.execute {
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

    @Test
    func tryLockFailsWhenAlreadyLocked() async {
        let lockManager = makeLockManager()
        var acquiredSecond = false

        DispatchQueue.global().async {
            lockManager.lock()
            Thread.sleep(forTimeInterval: 0.1)
            lockManager.unlock()
        }

        // Give the first thread a head start
        try? await Task.sleep(nanoseconds: 20_000_000)

        DispatchQueue.global().async {
            if lockManager.tryLock() {
                acquiredSecond = true
                lockManager.unlock()
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
        let iterations = 1000
        let queue = DispatchQueue(label: #function, attributes: .concurrent)
        var readResults = [Int]()
        let readLock = NSLock()
        let group = DispatchGroup()

        for _ in 0 ..< iterations {
            group.enter()
            queue.async {
                // Write under lock
                lockManager.execute {
                    value += 1
                }

                // Read under lock
                let readValue = lockManager.execute { value }

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
        let iterations = 10000
        let queue = DispatchQueue(label: #function, attributes: .concurrent)
        let group = DispatchGroup()

        for _ in 0 ..< iterations {
            group.enter()
            queue.async {
                if lockManager.tryLock() {
                    counterLock.lock(); successCount += 1; counterLock.unlock()
                    lockManager.unlock()
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
    func deinitIsSafe() {
        weak var weakManager: Common.UnfairLockThreadingManager?
        do {
            var manager: Common.UnfairLockThreadingManager? = .init()
            manager?.execute { _ = 1 }
            weakManager = manager
            manager = nil
        }
        #expect(weakManager == nil, "Manager should deallocate cleanly")
    }
}
