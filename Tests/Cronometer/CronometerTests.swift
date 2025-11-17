//
//  Created by Ricardo Santos on 12/08/2024.
//

@testable import Common
import Foundation
import Testing

@Suite(.serialized)
struct CronometerTests {
    let maxDeviation: Double = 1.01 // 1% error

    private func bounds(for seconds: UInt32) -> (min: Double, max: Double) {
        let s = Double(seconds)
        // min = 0.99 * s, max = 1.01 * s (for maxDeviation = 1.01)
        let minB = s * (1 - (maxDeviation - 1))
        let maxB = s * maxDeviation
        return (minB, maxB)
    }

    @Test
    func measure() {
        let operationTime: UInt32 = 1
        let measured = Common_CronometerManager.measure {
            sleep(operationTime)
        }
        let (minB, maxB) = bounds(for: operationTime)
        #expect(measured > minB && measured < maxB, "Measured \(measured)s not in [\(minB)s, \(maxB)s]")
    }

    @Test
    func timeElapsed() {
        let operationTime: UInt32 = 1
        Common_CronometerManager.startTimerWith()
        sleep(operationTime)
        let measured = Common_CronometerManager.timeElapsed() ?? 0
        let (minB, maxB) = bounds(for: operationTime)
        #expect(measured > minB && measured < maxB, "Elapsed \(measured)s not in [\(minB)s, \(maxB)s]")
    }
}
