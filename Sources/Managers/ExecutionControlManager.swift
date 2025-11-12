import Foundation
import UIKit

public extension Common {
    enum ExecutionControlManager {

        // MARK: - Types

        public enum ThrottlePolicy {
            case leading
            case trailing
            case leadingAndTrailing
        }

        public enum DebouncePolicy {
            case trailing
            case leading
        }

        // MARK: - State (thread-safe via your property wrapper)

        @PWThreadSafe private static var throttleTimestamps: [String: TimeInterval] = [:] // systemUptime
        @PWThreadSafe private static var throttlePendingTimers: [String: Timer] = [:]
        @PWThreadSafe private static var debounceTimers: [String: Timer] = [:]
        @PWThreadSafe private static var blockReferenceCount: [String: Int] = [:]

        // MARK: - Reset

        public static func reset() {
            throttleTimestamps.removeAll()
            throttlePendingTimers.values.forEach { $0.invalidate() }
            throttlePendingTimers.removeAll()
            debounceTimers.values.forEach { $0.invalidate() }
            debounceTimers.removeAll()
            blockReferenceCount.removeAll()
        }

        public static func reset(operationId: String) {
            throttleTimestamps[operationId] = nil
            if let t = throttlePendingTimers[operationId] { t.invalidate() }
            throttlePendingTimers[operationId] = nil
            if let t = debounceTimers[operationId] { t.invalidate() }
            debounceTimers[operationId] = nil
            blockReferenceCount[operationId] = nil
        }

        // MARK: - Execute once / counting

        @discardableResult
        public static func executeOnce(
            token: String,
            block: @escaping () -> Void,
            onIgnoredClosure: () -> Void = {}
        ) -> Bool {
            if !takeFirst(n: 1, operationId: token, block: block) {
                onIgnoredClosure()
                return false
            }
            return true
        }

        public static func dropFirst(
            n: Int,
            operationId: String,
            block: @escaping () -> Void
        ) {
            guard n > 0 else { block(); return }
            var ref = blockReferenceCount[operationId] ?? 0
            if ref >= n { block() }
            ref &+= 1
            blockReferenceCount[operationId] = ref
        }

        @discardableResult
        public static func takeFirst(
            n: Int,
            operationId: String,
            block: @escaping () -> Void
        ) -> Bool {
            guard n > 0 else { return false }
            var ref = blockReferenceCount[operationId] ?? 0
            defer {
                if ref < .max { ref &+= 1 }
                blockReferenceCount[operationId] = ref
            }
            if ref < n {
                block()
                return true
            }
            return false
        }

        // MARK: - Throttle

        public static func throttle(
            _ timeInterval: TimeInterval = Common.Constants.defaultThrottle,
            operationId: String,
            policy: ThrottlePolicy = .leading,
            closure: @escaping () -> Void,
            onIgnoredClosure: () -> Void = {}
        ) {
            let now = ProcessInfo.processInfo.systemUptime
            let last = throttleTimestamps[operationId]

            // If we have a pending trailing timer and the policy isn't trailing/leadingAndTrailing, clear it
            if policy == .leading, let pending = throttlePendingTimers[operationId] {
                pending.invalidate()
                throttlePendingTimers[operationId] = nil
            }

            let shouldFireLeading: Bool = {
                guard let last else { return true }
                return (now - last) >= timeInterval
            }()

            switch (policy, shouldFireLeading) {
            case (_, true):
                closure()
                throttleTimestamps[operationId] = now
                if policy == .leadingAndTrailing {
                    Task { @MainActor in
                        scheduleTrailingThrottle(timeInterval, operationId: operationId, closure: closure)
                    }
                }

            case (.trailing, false), (.leadingAndTrailing, false):
                Task { @MainActor in
                    scheduleTrailingThrottle(timeInterval, operationId: operationId, closure: closure)
                }

            case (.leading, false):
                onIgnoredClosure()
            }
        }

        @MainActor
        private static func scheduleTrailingThrottle(
            _ timeInterval: TimeInterval,
            operationId: String,
            closure: @escaping () -> Void
        ) {
            if let t = throttlePendingTimers[operationId] {
                t.invalidate()
            }

            let now = ProcessInfo.processInfo.systemUptime
            let last = throttleTimestamps[operationId] ?? now
            let remaining = max(0, timeInterval - (now - last))

            let timer = Timer(timeInterval: remaining, repeats: false) { _ in
                closure()
                throttleTimestamps[operationId] = ProcessInfo.processInfo.systemUptime
                throttlePendingTimers[operationId]?.invalidate()
                throttlePendingTimers[operationId] = nil
            }
            RunLoop.main.add(timer, forMode: .common)
            throttlePendingTimers[operationId] = timer
        }

        // MARK: - Debounce

        public static func debounce(
            _ timeInterval: TimeInterval = Common.Constants.defaultDebounce,
            operationId: String,
            policy: DebouncePolicy = .trailing,
            closure: @escaping () -> Void
        ) {
            switch policy {
            case .trailing:
                Task { @MainActor in
                    scheduleTrailingDebounce(timeInterval, operationId: operationId, closure: closure)
                }
            case .leading:
                // Fire immediately if no quiet window active
                if debounceTimers[operationId] == nil {
                    closure()
                }
                Task { @MainActor in
                    scheduleTrailingDebounce(timeInterval, operationId: operationId, closure: {})
                }
            }
        }

        public static func cancelDebounce(operationId: String) {
            if let t = debounceTimers[operationId] {
                t.invalidate()
                debounceTimers[operationId] = nil
            }
        }

        public static func isDebounceScheduled(operationId: String) -> Bool {
            debounceTimers[operationId] != nil
        }

        @MainActor
        private static func scheduleTrailingDebounce(
            _ timeInterval: TimeInterval,
            operationId: String,
            closure: @escaping () -> Void
        ) {
            if let scheduled = debounceTimers[operationId] {
                scheduled.invalidate()
            }

            let timer = Timer(timeInterval: timeInterval, repeats: false) { _ in
                closure()
                if let t = debounceTimers[operationId] {
                    t.invalidate()
                    debounceTimers[operationId] = nil
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            debounceTimers[operationId] = timer
        }
    }
}

// MARK: - Sample usage
extension Common.ExecutionControlManager {
    static func sampleUsage() {
        Common.ExecutionControlManager.throttle(1, operationId: "myClosure") {
            // "Executing closure..."
        }

        Common.ExecutionControlManager.debounce(1.0, operationId: "myDebouncedClosure") {
            // "Executing debounced closure..."
        }

        Common.ExecutionControlManager.throttle(0.5, operationId: "search", policy: .trailing) {
            // Fire once after burst
        }

        Common.ExecutionControlManager.debounce(0.3, operationId: "tap", policy: .leading) {
            // Immediate reaction, then coalesce
        }
    }
}
