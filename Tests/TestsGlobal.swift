//
//  Created by Ricardo Santos on 23/07/2024.
//

import Foundation
import Combine
import Nimble
import Common
import XCTest

internal class CommonBundleFinder {}

public struct ResponseDto {
    private init() {}
}

public struct RequestDto {
    private init() {}
}

struct TestError: Error, Equatable {}

public enum TestsGlobal {
    static let cancelBag = CancelBag()
    static var timeout: Int = 5
    static var loadedAny: Any?
    static var bundleIdentifier: String {
        Bundle(for: CommonBundleFinder.self).bundleIdentifier ?? ""
    }
}

// MARK: - Helper

//Nimble-like eventually (no Duration/Clock)
@discardableResult
func eventually(
    timeoutSeconds: Double = Double(TestsGlobal.timeout),
    pollIntervalSeconds: Double = 0.025,
    _ condition: @Sendable () -> Bool
) async -> Bool {
    let start = Date()
    let timeout = timeoutSeconds
    let pollNS = UInt64(pollIntervalSeconds * 1_000_000_000)
    while Date().timeIntervalSince(start) < timeout {
        if condition() { return true }
        try? await Task.sleep(nanoseconds: pollNS)
    }
    return condition()
}

func averageOperationTime(
    iterations: Int,
    precondition: () -> Void,
    operation: () -> Void,
    onComplete: (Double) -> Void
) {
    var timeElapsed: Double = 0
    for _ in 1...iterations {
        precondition()
        timeElapsed += Common_CronometerManager.measure {
            operation()
        }
    }
    let average = timeElapsed / Double(iterations)
    onComplete(average)
}
