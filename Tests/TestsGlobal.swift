//
//  Created by Ricardo Santos on 23/07/2024.
//

import Combine
import Common
import Foundation
import Nimble
import XCTest

class CommonBundleFinder {}

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

func withTimeout<T>(seconds: Double, _ operation: @escaping () async -> T) async -> TimeoutResult<T> {
    await withTaskGroup(of: TimeoutResult<T>.self) { group in
        group.addTask {
            return await Task.detached {
                return await .value(operation())
            }.value
        }
        group.addTask {
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            return .timedOut
        }
        return await group.next()!
    }
}

extension TimeoutResult: Equatable {
    static func == (lhs: TimeoutResult<T>, rhs: TimeoutResult<T>) -> Bool {
        switch (lhs, rhs) {
        case (.timedOut, .timedOut): return true
        case (.value, .value): return true // treat all Void values as equal
        default: return false
        }
    }
}

enum TimeoutResult<T> {
    case value(T)
    case timedOut
}

/// Checks a synchronous condition periodically until it becomes true or times out.
/// This overload simply wraps the sync closure into an async closure and forwards
/// the work to the async variant below.
@discardableResult
func eventually(
    timeoutSeconds: Double = Double(TestsGlobal.timeout),
    pollIntervalSeconds: Double = 0.025,
    _ condition: @Sendable () -> Bool
) async -> Bool {
    // Forward to the async version by wrapping the sync condition
    await eventuallyAsync(timeoutSeconds: timeoutSeconds,
                          pollIntervalSeconds: pollIntervalSeconds)
    {
        condition() // no await needed
    }
}

/// Checks an asynchronous condition periodically until it becomes true or times out.
/// This is the actual implementation used by both overloads.
@discardableResult
func eventuallyAsync(
    timeoutSeconds: Double = Double(TestsGlobal.timeout),
    pollIntervalSeconds: Double = 0.025,
    _ condition: @Sendable () async -> Bool
) async -> Bool {
    let start = Date()
    let timeout = timeoutSeconds
    // Convert seconds to nanoseconds for Task.sleep
    let pollNS = UInt64(pollIntervalSeconds * 1_000_000_000)
    // Main polling loop
    while Date().timeIntervalSince(start) < timeout {
        // If the async condition succeeds, exit early
        if await condition() { return true }
        // Sleep briefly before checking again
        try? await Task.sleep(nanoseconds: pollNS)
    }
    // Final check after the timeout window
    return await condition()
}

func averageOperationTime(
    iterations: Int,
    precondition: () -> Void,
    operation: () -> Void,
    onComplete: (Double) -> Void
) {
    var timeElapsed: Double = 0
    for _ in 1 ... iterations {
        precondition()
        timeElapsed += Common_CronometerManager.measure {
            operation()
        }
    }
    let average = timeElapsed / Double(iterations)
    onComplete(average)
}
