//
//  Created by Ricardo Santos on 12/08/2024.
//

import Foundation
import Testing
@testable import Common

@Suite(.serialized)
struct ExecutionControlManagerTests {

    // MARK: - Per-test reset (replaces setUp)
    private func resetState() {
        TestsGlobal.loadedAny = nil
        TestsGlobal.cancelBag.cancel()
        Common.ExecutionControlManager.reset()
    }


    // MARK: - Tests

    @Test
    func throttle() async {
        resetState()
        var executionCount = 0
        let operationId = #function
        let timeInterval: Double = 1

        Common.ExecutionControlManager.throttle(timeInterval, operationId: operationId) {
            executionCount += 1 // Should execute
        }

        Common.ExecutionControlManager.throttle(timeInterval - 0.1, operationId: operationId) {
            executionCount += 1 // Should NOT execute
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval + 0.1) {
            Common.ExecutionControlManager.throttle(1, operationId: operationId) {
                executionCount += 1 // Should execute
            }
        }

        let ok = await eventually(timeoutSeconds: timeInterval * 2.0) {
            executionCount == 2
        }
        #expect(ok, "Expected executionCount to reach 2 after throttling")
    }

    @Test
    func throttleWIgnoredClosure() async {
        resetState()
        var executionCount = 0
        var ignoredCount = 0
        let operationId = #function
        let timeInterval: Double = 1

        Common.ExecutionControlManager.throttle(
            timeInterval,
            operationId: operationId,
            closure: { executionCount += 1 },
            onIgnoredClosure: { ignoredCount += 1 }
        )

        Common.ExecutionControlManager.throttle(
            timeInterval,
            operationId: operationId,
            closure: { executionCount += 1 },
            onIgnoredClosure: { ignoredCount += 1 }
        )

        let ok1 = await eventually(timeoutSeconds: timeInterval * 2.0) {
            executionCount == 1
        }
        #expect(ok1, "Expected one execution")

        let ok2 = await eventually(timeoutSeconds: timeInterval * 2.0) {
            ignoredCount == 1
        }
        #expect(ok2, "Expected one ignored callback")
    }

    @Test
    func debounce() async {
        resetState()
        var executionCount = 0
        let operationId = #function
        let timeInterval: Double = 1

        Common.ExecutionControlManager.debounce(timeInterval, operationId: operationId) {
            executionCount += 1 // first rapid call
        }
        Common.ExecutionControlManager.debounce(timeInterval, operationId: operationId) {
            executionCount += 1 // second rapid call
        }
        Common.ExecutionControlManager.debounce(timeInterval, operationId: operationId) {
            executionCount += 1 // last (wins)
        }

        let firstOk = await eventually(timeoutSeconds: timeInterval + 1.0) {
            executionCount == 1
        }
        #expect(firstOk, "Expected exactly one execution after debounce")

        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval + 0.1) {
            Common.ExecutionControlManager.debounce(1, operationId: operationId) {
                executionCount += 1 // Should execute
            }
        }

        let secondOk = await eventually(timeoutSeconds: timeInterval + 2.0) {
            executionCount == 2
        }
        #expect(secondOk, "Expected a second execution after delayed debounce")
    }

    @Test
    func testDropFirstNegative() async {
        resetState()
        var executionCount = 0
        let operationId = #function
        let timeInterval: Double = 1
        let drops = -1

        Common.ExecutionControlManager.dropFirst(n: drops, operationId: operationId) {
            executionCount += 1
        }
        Common.ExecutionControlManager.dropFirst(n: drops, operationId: operationId) {
            executionCount += 1
        }

        let ok = await eventually(timeoutSeconds: timeInterval) {
            executionCount == 2
        }
        #expect(ok, "Expected both closures to run when drops is negative")
    }

    @Test
    func dropFirstT0() async {
        resetState()
        var executionCount = 0
        let operationId = #function
        let timeInterval: Double = 1
        let drops = 0

        Common.ExecutionControlManager.dropFirst(n: drops, operationId: operationId) {
            executionCount += 1
        }
        Common.ExecutionControlManager.dropFirst(n: drops, operationId: operationId) {
            executionCount += 1
        }

        let ok = await eventually(timeoutSeconds: timeInterval) {
            executionCount == 2
        }
        #expect(ok, "Expected both closures to run when drops == 0")
    }

    @Test
    func dropFirstT1() async {
        resetState()
        var executed = false
        let operationId = #function
        let timeInterval: Double = 1
        let drops = 1

        Common.ExecutionControlManager.dropFirst(n: drops, operationId: operationId) {
            #expect(Bool(false), "First call should be dropped")
        }
        Common.ExecutionControlManager.dropFirst(n: drops, operationId: operationId) {
            executed = true
        }

        let ok = await eventually(timeoutSeconds: timeInterval) {
            executed
        }
        #expect(ok, "Expected only the second call to execute when drops == 1")
    }

    @Test
    func dropFirstT2() async {
        resetState()
        var executed = false
        let operationId = #function
        let timeInterval: Double = 1
        let drops = 2

        Common.ExecutionControlManager.dropFirst(n: drops, operationId: operationId) {
            #expect(Bool(false), "First call should be dropped")
        }
        Common.ExecutionControlManager.dropFirst(n: drops, operationId: operationId) {
            #expect(Bool(false), "Second call should be dropped")
        }
        Common.ExecutionControlManager.dropFirst(n: drops, operationId: operationId) {
            executed = true
        }

        let ok = await eventually(timeoutSeconds: timeInterval) {
            executed
        }
        #expect(ok, "Expected only the third call to execute when drops == 2")
    }
}
