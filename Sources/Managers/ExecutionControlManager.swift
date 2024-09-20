import Foundation
import UIKit

public extension Common {
    enum ExecutionControlManager {
        public static func reset() {
            throttleTimestamps.removeAll()
            debounceTimers.forEach { $0.value.invalidate() }
            debounceTimers.removeAll()
            blockReferenceCount.removeAll()
        }

        // Thread-safe storage for throttle timestamps
        @PWThreadSafe private static var throttleTimestamps: [String: TimeInterval] = [:]
        // Thread-safe storage for debounce timers
        @PWThreadSafe private static var debounceTimers: [String: Timer] = [:]
        @PWThreadSafe private static var blockReferenceCount: [String: Int] = [:]
        
        @discardableResult
        public static func executeOnce(token: String, block: @escaping () -> Void, onIgnoredClosure: () -> Void = {}) -> Bool {
            if !takeFirst(n: 1, operationId: #function, block: block) {
                onIgnoredClosure()
                return false
            }
            return true
        }
        
        /**
         Throttles the execution of a closure. The closure will only be executed if the specified time interval has elapsed since the last execution with the same operation ID.

         - Parameters:
            - timeInterval: The minimum time interval between successive executions.
            - operationId: A unique identifier for the operation being throttled.
            - closure: The closure to be executed.
            - onIgnoredClosure: An optional closure to be executed if the main closure is throttled.
         */
        public static func throttle(
            _ timeInterval: TimeInterval = Common.Constants.defaultThrottle,
            operationId: String,
            closure: () -> Void,
            onIgnoredClosure: () -> Void = {}
        ) {
            let currentTime = Date().timeIntervalSince1970
            if let lastTimestamp = throttleTimestamps[operationId], currentTime - lastTimestamp < timeInterval {
                onIgnoredClosure()
                return
            }
            closure()
            throttleTimestamps[operationId] = currentTime
        }

        /**
         Debounces the execution of a closure. The closure will only be executed after the specified time interval has elapsed since the last call with the same operation ID.

         - Parameters:
            - timeInterval: The time interval to wait before executing the closure.
            - operationId: A unique identifier for the operation being debounced.
            - closure: The closure to be executed.
         */
        public static func debounce(
            _ timeInterval: TimeInterval = Common.Constants.defaultDebounce,
            operationId: String,
            closure: @escaping () -> Void
        ) {
            if let scheduledTimer = debounceTimers[operationId] {
                // Invalidate any existing timer for the given operation ID
                scheduledTimer.invalidate()
            }

            // Schedule a new timer to execute the closure after the specified time interval
            let timer = Timer.scheduledTimer(
                withTimeInterval: timeInterval,
                repeats: false
            ) { _ in
                closure()
                if let scheduledTimer = debounceTimers[operationId] {
                    scheduledTimer.invalidate()
                    debounceTimers[operationId] = nil
                }
            }

            // Store the new timer
            debounceTimers[operationId] = timer
        }

        public static func dropFirst(
            n: Int,
            operationId: String,
            block: @escaping () -> Void
        ) {
            guard n > 0 else {
                block()
                return
            }
            var refCount = blockReferenceCount[operationId] ?? 0
            if refCount >= n {
                // Executed
                block()
            } else {
                // Dropped...
            }
            refCount += 1
            blockReferenceCount[operationId] = refCount
        }
        
        public static func takeFirst(
            n: Int,
            operationId: String,
            block: @escaping () -> Void
        ) -> Bool {
            guard n > 0 else {
                return false
            }
            var refCount = blockReferenceCount[operationId] ?? 0
            if refCount >= n {
                // Executed
                block()
                refCount += 1
                blockReferenceCount[operationId] = refCount
                return true
            } else {
                refCount += 1
                blockReferenceCount[operationId] = refCount
                return false
            }
        }
    }
}

extension Common.ExecutionControlManager {
    /**
     Sample usage of the throttle and debounce functions.
     */
    static func sampleUsage() {
        // Throttle usage: the closure will only be executed if at least 1 second has passed since the last execution
        Common.ExecutionControlManager.throttle(1, operationId: "myClosure") {
            // "Executing closure..."
        }

        // Debounce usage: the closure will only be executed 1 second after the last call to debounce with this operation ID
        Common.ExecutionControlManager.debounce(1.0, operationId: "myDebouncedClosure") {
            // "Executing debounced closure..."
        }
    }
}
