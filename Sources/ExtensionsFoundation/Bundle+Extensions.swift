//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

public extension Bundle {
    // MARK: - Public convenience accessors

    /// Example: "1.0 (123)"
    static var versionDescription: String {
        let short = bundleShortVersion ?? "Unknown"
        let build = bundleVersion ?? "Unknown"
        return "\(short) (\(build))"
    }

    /// Example: "123"
    static var bundleVersion: String? {
        main.bundleVersion
    }

    /// Example: "1.0"
    static var bundleShortVersion: String? {
        main.bundleShortVersion
    }

    // MARK: - Instance accessors

    /// Returns the CFBundleVersion (Build number)
    var bundleVersion: String? {
        value(for: .cfBundleVersion)
    }

    /// Returns the CFBundleShortVersionString (Marketing version)
    var bundleShortVersion: String? {
        value(for: .cfBundleShortVersionString)
    }

    // MARK: - Private helpers

    private func value(for key: InfoKey) -> String? {
        (infoDictionary?[key.rawValue] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nonEmpty
    }

    private enum InfoKey: String {
        case cfBundleVersion = "CFBundleVersion"
        case cfBundleShortVersionString = "CFBundleShortVersionString"
    }
}

// MARK: - Tiny helper

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
