//
//  Created by Ricardo Santos on 12/08/2024.
//

import Combine
import Foundation
import Testing
//
@testable import Common

/// Serialised: every test drives the same `ExecutionControlManager` global state.
@Suite(.serialized)
struct ExecutionControlManager_Tests {
    init() {
        TestsGlobal.loadedAny = nil
        TestsGlobal.cancelBag.cancel()
        Common.ExecutionControlManager.reset()
    }

    @Test
    func testThrottle() async {
        var executionCount = 0
        let operationId = #function
        let timeInterval: Double = 1
        // Call throttle function and expect closure to be executed
        Common.ExecutionControlManager.throttle(timeInterval, operationId: operationId) {
            executionCount += 1 // Should execute
        }

        // Call throttle function again within the throttle interval, expect closure not to be executed
        Common.ExecutionControlManager.throttle(timeInterval - 0.1, operationId: operationId) {
            executionCount += 1 // Should not execute
        }

        // After waiting for the throttle interval, call throttle again and expect closure to be executed
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval + 0.1) {
            Common.ExecutionControlManager.throttle(1, operationId: operationId) {
                executionCount += 1 // Should execute
            }
        }

        // Test assertions
        let timeout = timeInterval * 2
        #expect(await eventually(timeoutSeconds: timeout) { executionCount == 2 })
    }

    @Test
    func testThrottleWithIgnoredClosure() async {
        var executionCount = 0
        var ignoredCount = 0
        let operationId = #function
        let timeInterval: Double = 1

        // Call throttle with an ignored closure
        Common.ExecutionControlManager.throttle(timeInterval, operationId: operationId, closure: {
            executionCount += 1
        }, onIgnoredClosure: {
            ignoredCount += 1
        })

        // Call throttle again within the throttle interval, expect the ignored closure to be executed
        Common.ExecutionControlManager.throttle(timeInterval, operationId: operationId, closure: {
            executionCount += 1
        }, onIgnoredClosure: {
            ignoredCount += 1
        })

        // Test assertions
        let timeout = timeInterval * 2
        #expect(await eventually(timeoutSeconds: timeout) { executionCount == 1 })
        #expect(await eventually(timeoutSeconds: timeout) { ignoredCount == 1 })
    }

    @Test
    func testDebounce() async {
        var executionCount = 0
        let operationId = #function
        let timeInterval: Double = 1

        // Call debounce function multiple times in quick succession
        Common.ExecutionControlManager.debounce(timeInterval, operationId: operationId) {
            executionCount += 1 // Should not execute
        }
        Common.ExecutionControlManager.debounce(timeInterval, operationId: operationId) {
            executionCount += 1 // Should not execute
        }
        Common.ExecutionControlManager.debounce(timeInterval, operationId: operationId) {
            executionCount += 1 // Should execute
        }

        // Expect only one closure execution after debounce interval
        let timeoutT1 = timeInterval + 1
        #expect(await eventually(timeoutSeconds: timeoutT1) { executionCount == 1 })

        // Call debounce again after a delay and expect another execution
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval + 0.1) {
            Common.ExecutionControlManager.debounce(1, operationId: operationId) {
                executionCount += 1 // Should execute
            }
        }

        // Test assertions
        let timeoutT2 = timeInterval + 2
        #expect(await eventually(timeoutSeconds: timeoutT2) { executionCount == 2 })
    }

    @Test
    func testDropFirstNegative() async {
        var executionCount = 0
        let operationId = #function
        let timeInterval: Double = 1
        let drops: Int = -1

        Common.ExecutionControlManager.dropFirst(n: drops, operationId: operationId) {
            executionCount += 1 // Should execute
        }
        Common.ExecutionControlManager.dropFirst(n: drops, operationId: operationId) {
            executionCount += 1 // Should execute
        }

        // Test assertions
        let timeout = timeInterval
        #expect(await eventually(timeoutSeconds: timeout) { executionCount == 2 })
    }

    @Test
    func testDropFirst0() async {
        var executionCount = 0
        let operationId = #function
        let timeInterval: Double = 1
        let drops: Int = 0

        Common.ExecutionControlManager.dropFirst(n: drops, operationId: operationId) {
            executionCount += 1 // Should execute
        }
        Common.ExecutionControlManager.dropFirst(n: drops, operationId: operationId) {
            executionCount += 1 // Should execute
        }

        // Test assertions
        let timeout = timeInterval
        #expect(await eventually(timeoutSeconds: timeout) { executionCount == 2 })
    }

    @Test
    func testDropFirst1() async {
        var executionCount = 0
        let operationId = #function
        let timeInterval: Double = 1
        let drops: Int = 1

        Common.ExecutionControlManager.dropFirst(n: drops, operationId: operationId) {
            Issue.record("Should not execute")
        }
        Common.ExecutionControlManager.dropFirst(n: drops, operationId: operationId) {
            executionCount += 1 // Should execute
        }

        // Test assertions
        let timeout = timeInterval
        #expect(await eventually(timeoutSeconds: timeout) { executionCount == 1 })
    }

    @Test
    func testDropFirst2() async {
        var executionCount = 0
        let operationId = #function
        let timeInterval: Double = 1
        let drops: Int = 2

        Common.ExecutionControlManager.dropFirst(n: drops, operationId: operationId) {
            Issue.record("Should not execute")
        }
        Common.ExecutionControlManager.dropFirst(n: drops, operationId: operationId) {
            Issue.record("Should not execute")
        }
        Common.ExecutionControlManager.dropFirst(n: drops, operationId: operationId) {
            executionCount += 1 // Should execute
        }

        // Test assertions
        let timeout = timeInterval
        #expect(await eventually(timeoutSeconds: timeout) { executionCount == 1 })
    }
}
