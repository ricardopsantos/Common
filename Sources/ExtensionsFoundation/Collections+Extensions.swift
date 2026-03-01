//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

// MARK: - Collection Safe Access

public extension Collection {
    /// Safely returns the element at the given index if it exists.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Array Helpers

public extension Array {
    /// Safe access by integer index (non-negative only).
    func safeItem(at index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }

    /// Alias for `safeItem(at:)`
    func item(at index: Int) -> Element? { safeItem(at: index) }

    /// Alias for `safeItem(at:)`
    func element(at index: Int) -> Element? { safeItem(at: index) }

    /// Safe access via IndexPath.row
    subscript(indexPath: IndexPath) -> Element? {
        safeItem(at: indexPath.row)
    }

    /// Takes the first *k* elements, safely.
    func take(_ k: Int) -> [Element] {
        Array(prefix(Swift.max(0, k)))
    }

    /// Skips the first *k* elements, safely.
    func skip(_ k: Int) -> [Element] {
        Array(dropFirst(Swift.max(0, k)))
    }

    /// Splits the array into chunks of given size.
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }

    /// Returns a random element or nil if empty.
    var randomItem: Element? {
        isEmpty ? nil : randomElement()
    }
}

// MARK: - Array Hashable Helpers

public extension Array where Element: Hashable {
    /// Returns this array converted to a Set.
    var set: Set<Element> { Set(self) }

    /// Removes duplicates while keeping the first occurrence.
    static func removeDuplicates(_ elements: [Element]) -> [Element] {
        var seen = Set<Element>()
        return elements.filter { seen.insert($0).inserted }
    }
}

// MARK: - Equatable Removal

public extension RangeReplaceableCollection where Element: Equatable {
    /// Removes the first element equal to the given one.
    mutating func removeObject(_ object: Element) {
        removeAll(where: { $0 == object })
    }
}
