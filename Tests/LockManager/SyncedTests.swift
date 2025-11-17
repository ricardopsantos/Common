//
//  SyncedTests.swift
//  Common
//
//  Created by Ricardo Santos on 17/11/2025.
//

// MARK: - Tests

@testable @preconcurrency import Common
import Foundation
import Testing

@Suite(.serialized)
struct SyncedTests {
    @Test
    func synced_dispatchesCorrectImplementation() {
        var value = 0
        let lock1 = NSLock() // Should use syncedV2
        let lock2 = NSObject() // Should use syncedV1
        Common.synced(lock1) { value += 1 }
        Common.synced(lock2) { value += 1 }
        #expect(value == 2)
    }

    @Test
    func syncObjc_protectsCriticalSection() async {
        let lock = NSObject()
        var value = 0
        let iterations = 2000
        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< iterations {
                group.addTask {
                    Common.syncObjc(lock) { value += 1 }
                }
            }
        }
        #expect(value == iterations)
    }

    @Test
    func syncedNSLock_protectsCriticalSection() async {
        let lock = NSLock()
        var value = 0
        let iterations = 2000
        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< iterations {
                group.addTask {
                    Common.syncedNSLock(lock) { value += 1 }
                }
            }
        }
        #expect(value == iterations)
    }

    @Test
    func syncObjc_rejectsValueTypes() {
        let lock = 123 // Int → NOT allowed by objc_sync_enter
        var executed = false
        let result = Common.syncObjc(lock) {
            executed = true
            return 99
        }
        #expect(executed)
        #expect(result == 99)
    }

    @Test
    func syncedReEntrantNSLock_allowsNestedLockAttemptSafely() {
        let lock = NSRecursiveLock()
        var didRunInner = false
        Common.syncedReEntrantNSLock(lock) {
            Common.syncedReEntrantNSLock(lock) {
                didRunInner = true
            }
        }
        #expect(didRunInner)
    }

    @Test(.disabled())
    func syncedNSLock_nestedLockShouldDeadlock() async {
        let lock = NSLock()
        await withTimeout(seconds: 1) {
            Common.syncedNSLock(lock) {
                // DEAD-LOCK!
                Common.syncedNSLock(lock) {}
            }
        }
    }
}
