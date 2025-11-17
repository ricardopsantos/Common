//
//  Created by Ricardo Santos on 12/08/2024.
//

@testable import Common
import Foundation
import Testing

@Suite(.serialized)
struct CronometerAverageMetricsTests {
    // MARK: - Setup helper (replaces setUp/tearDown)

    private func resetState() {
        // Reset the shared instance before each test to ensure a clean state.
        CronometerAverageMetrics.shared.reset()
    }

    // MARK: - Tests

    @Test
    func basicUsageSingleOperation() {
        resetState()

        let key = #function

        CronometerAverageMetrics.shared.start(key: key)
        usleep(useconds_t(1 * 1_000_000)) // Sleep for ~1 second

        let elapsed = CronometerAverageMetrics.shared.end(key: key)
        #expect(timeInOnRange(value: elapsed, refValue: 1))
    }

    @Test
    func basicUsageMultipleOperationsT1() {
        resetState()

        let key = #function

        let t1 = Double(Int.random(in: 1 ... 3))
        let t2 = Double(Int.random(in: 1 ... 3))
        let t3 = Double(Int.random(in: 1 ... 3))

        _ = performOperation(key: key, timeInSeconds: t1)
        _ = performOperation(key: key, timeInSeconds: t2)
        _ = performOperation(key: key, timeInSeconds: t3)

        let avgReceived = CronometerAverageMetrics.shared.averageTimeFor(key: key)
        let avgExpected = (t1 + t2 + t3) / 3.0

        #expect(timeInOnRange(value: avgReceived, refValue: avgExpected))
    }

    @Test
    func report() {
        resetState()

        let key1 = "\(#function)_1"
        let key2 = "\(#function)_2"

        let t1 = Double(Int.random(in: 1 ... 3))
        let t2 = Double(Int.random(in: 1 ... 3))
        let t3 = Double(Int.random(in: 1 ... 3))

        _ = performOperation(key: key1, timeInSeconds: t1)
        _ = performOperation(key: key1, timeInSeconds: t2)
        _ = performOperation(key: key1, timeInSeconds: t3)

        _ = performOperation(key: key2, timeInSeconds: t1)
        _ = performOperation(key: key2, timeInSeconds: t2)
        _ = performOperation(key: key2, timeInSeconds: t3)

        let report = CronometerAverageMetrics.shared.reportV1

        let key1Metrics = report[key1] as? [String: String]
        let key2Metrics = report[key2] as? [String: String]

        let key1Avg: Double = key1Metrics?["avg"]?.doubleValue ?? 0
        let key2Avg: Double = key2Metrics?["avg"]?.doubleValue ?? 0

        let avgExpected = (t1 + t2 + t3) / 3.0

        #expect(key1Metrics?["total"]?.intValue == 3)
        #expect(key2Metrics?["total"]?.intValue == 3)
        #expect(timeInOnRange(value: key1Avg, refValue: avgExpected))
        #expect(timeInOnRange(value: key2Avg, refValue: avgExpected))
    }
}

// MARK: - Helpers

extension CronometerAverageMetricsTests {
    @discardableResult
    private func performOperation(key: String, timeInSeconds: Double) -> Double {
        CronometerAverageMetrics.shared.start(key: key)
        usleep(useconds_t(timeInSeconds * 1_000_000))
        return CronometerAverageMetrics.shared.end(key: key)
    }

    /// Returns true if `value` is within ±1% of `refValue`.
    private func timeInOnRange(value: Double, refValue: Double) -> Bool {
        let k = 0.01 // 1% deviation
        if refValue > value * (1 + k) { return false }
        if refValue < value * (1 - k) { return false }
        return true
    }
}
