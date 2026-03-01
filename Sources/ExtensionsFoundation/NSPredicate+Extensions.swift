//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import CoreData
import Foundation

public extension NSPredicate {
    // MARK: - Simple Flags

    static var exists: NSPredicate {
        NSPredicate(format: "exists == true")
    }

    static var notExists: NSPredicate {
        NSPredicate(format: "exists == false")
    }

    // MARK: - ALL fields equal

    static func allFields(_ fields: [String], with value: String, caseSensitive: Bool = false) -> NSPredicate {
        buildCompoundPredicate(
            fields: fields,
            operator: "==",
            value: value,
            caseSensitive: caseSensitive,
            type: .and
        )
    }

    // MARK: - ANY field equals

    static func anyField(_ fields: [String], with value: String, caseSensitive: Bool = false) -> NSPredicate {
        buildCompoundPredicate(
            fields: fields,
            operator: "==",
            value: value,
            caseSensitive: caseSensitive,
            type: .or
        )
    }

    // MARK: - ANY field contains (multi-word AND search)

    static func anyField(_ fields: [String], thatContains value: String) -> NSPredicate? {
        let trimmed = value.trim
        guard !trimmed.isEmpty else { return nil }

        let words = trimmed.split(by: " ")

        guard !words.isEmpty else { return nil }

        let predicates = words.compactMap { word -> NSPredicate? in
            guard !word.trim.isEmpty else { return nil }
            return containsPredicate(for: fields, word: word)
        }

        if predicates.count == 1 {
            return predicates.first
        } else {
            return NSCompoundPredicate(type: .and, subpredicates: predicates)
        }
    }

    private static func containsPredicate(for fields: [String], word: String) -> NSPredicate {
        let format = fields
            .filter { !$0.isEmpty }
            .map { "\($0) CONTAINS[cd] %@" }
            .joined(separator: " OR ")

        return NSPredicate(format: format, argumentArray: Array(repeating: word, count: fields.count))
    }

    // MARK: - Core Builder

    private static func buildCompoundPredicate(
        fields: [String],
        operator op: String,
        value: String,
        caseSensitive: Bool,
        type: NSCompoundPredicate.LogicalType
    ) -> NSPredicate {
        guard !value.isEmpty else { return NSPredicate(value: false) }

        let modifier = caseSensitive ? "" : "[c]"
        let formatOp = "\(op)\(modifier) %@"

        let sub = fields
            .filter { !$0.isEmpty }
            .map { NSPredicate(format: "\($0) \(formatOp)", value) }

        if sub.count == 1 { return sub[0] }
        if sub.isEmpty { return NSPredicate(value: false) }

        return NSCompoundPredicate(type: type, subpredicates: sub)
    }
}

// MARK: - Convenience KeyPath-Based Predicates

public extension NSPredicate {
    static func contains(_ keyPath: String, substring: String) -> NSPredicate {
        NSPredicate(format: "%K CONTAINS[cd] %@", keyPath, substring)
    }

    static func beginsWith(_ keyPath: String, substring: String) -> NSPredicate {
        NSPredicate(format: "%K BEGINSWITH[cd] %@", keyPath, substring)
    }

    static func endsWith(_ keyPath: String, substring: String) -> NSPredicate {
        NSPredicate(format: "%K ENDSWITH[cd] %@", keyPath, substring)
    }

    static func matches(_ keyPath: String, regex: String) -> NSPredicate {
        NSPredicate(format: "%K MATCHES %@", keyPath, regex)
    }

    static func isEqual(_ keyPath: String, value: Any) -> NSPredicate {
        guard let arg = value as? CVarArg else { return NSPredicate(value: false) }
        return NSPredicate(format: "%K == %@", keyPath, arg)
    }

    static func isGreaterThan(_ keyPath: String, value: Any) -> NSPredicate {
        guard let arg = value as? CVarArg else { return NSPredicate(value: false) }
        return NSPredicate(format: "%K > %@", keyPath, arg)
    }

    static func isLessThan(_ keyPath: String, value: Any) -> NSPredicate {
        guard let arg = value as? CVarArg else { return NSPredicate(value: false) }
        return NSPredicate(format: "%K < %@", keyPath, arg)
    }

    static func isBetween(_ keyPath: String, minValue: Any, maxValue: Any) -> NSPredicate {
        guard let a = minValue as? CVarArg,
              let b = maxValue as? CVarArg
        else {
            return NSPredicate(value: false)
        }

        return NSPredicate(format: "%K >= %@ AND %K <= %@", keyPath, a, keyPath, b)
    }
}
