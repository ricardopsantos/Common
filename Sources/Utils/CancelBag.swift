//
//  CancelBag.swift
//  Common
//
//  Created by Ricardo Santos on 01/01/2025.
//

import Combine
import Foundation

public typealias CancelBag = AutoReleasedCancelBag

// MARK: - AutoReleasedCancelBag

/// Stores AnyCancellable subscriptions with optional auto-release.
/// Auto-released subscriptions are replaced when a new subscription arrives with the same ID.
public final class AutoReleasedCancelBag {
    // Auto-release subscriptions: (subscription, id)
    @PWThreadSafe public fileprivate(set) var autoReleased = [(AnyCancellable, String)]()

    // Manual-retained subscriptions
    @PWThreadSafe public fileprivate(set) var retained = Set<AnyCancellable>()

    public var count: Int { autoReleased.count + retained.count }
    public var isEmpty: Bool { count == 0 }

    public init() {}

    deinit { cancelAll() }

    // MARK: - Cancel All

    public func cancel() {
        cancelAll()
    }

    public func cancelAll() {
        Common.synced(autoReleased) {
            let arr = autoReleased
            arr.forEach { $0.0.cancel() }
            autoReleased = []
        }

        Common.synced(retained) {
            let set = retained
            set.forEach { $0.cancel() }
            retained = []
        }
    }

    // MARK: - Cancel First

    public func cancelFirst() {
        Common.synced(autoReleased) {
            if let first = autoReleased.first {
                first.0.cancel()
                autoReleased.removeFirst()
                return
            }
        }

        Common.synced(retained) {
            guard let first = retained.first else { return }
            first.cancel()

            var copy = retained
            copy.remove(first)
            retained = copy
        }
    }

    // MARK: - Removal by ID

    @discardableResult
    public func remove(id: String) -> Bool {
        let trimmed = id.trim
        guard !trimmed.isEmpty else { return false }

        return Common.synced(autoReleased) {
            let before = autoReleased.count

            var copy = autoReleased
            copy.removeAll { pair in
                if pair.1 == trimmed {
                    pair.0.cancel()
                    return true
                }
                return false
            }

            autoReleased = copy
            return before > copy.count
        }
    }

    /// Cancels and removes all subscriptions whose ID starts with the given prefix.
    public func cancel(withPrefix prefix: String) {
        let trimmed = prefix.trim
        guard !trimmed.isEmpty else { return }

        Common.synced(autoReleased) {
            let idsToRemove = autoReleased.map(\.1).filter { $0.hasPrefix(trimmed) }
            for id in idsToRemove {
                _ = remove(id: id)
            }
        }
    }
}

// MARK: - AnyCancellable Store Extension

public extension AnyCancellable {
    func store(
        in bag: CancelBag,
        autoRelease: Bool = true,
        subscriptionId: String = "",
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        let computedID =
            !subscriptionId.trim.isEmpty
                ? subscriptionId.trim
                : "[\(file)|\(function)|\(line)]"

        // Manual, non-auto-release storage
        if !autoRelease {
            Common.synced(bag.retained) {
                var copy = bag.retained
                copy.insert(self)
                bag.retained = copy
            }
            return
        }

        // Auto-release storage (unique per computedId)
        Common.synced(bag.autoReleased) {
            _ = bag.remove(id: computedID)

            var copy = bag.autoReleased
            copy.append((self, computedID))
            bag.autoReleased = copy
        }
    }
}

// MARK: - DebounceCancelBag

/// A cancel bag that keeps at most 2 subscriptions.
/// Ideal for debounce-style publisher management.
public final class DebounceCancelBag {
    public fileprivate(set) var subscriptions: [AnyCancellable] = []

    public init() {}

    deinit { cancelAll() }

    public func cancelAll() {
        subscriptions.forEach { $0.cancel() }
        subscriptions.removeAll()
    }

    public func cancelFirst() {
        guard !subscriptions.isEmpty else { return }
        subscriptions.first?.cancel()
        subscriptions.removeFirst()
    }
}

public extension AnyCancellable {
    func store(in bag: DebounceCancelBag) {
        bag.subscriptions.append(self)

        // Keep 2 most recent
        if bag.subscriptions.count > 2 {
            bag.cancelFirst()
        }
    }
}
