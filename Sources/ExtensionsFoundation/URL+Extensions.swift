//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

public extension URL {
    /// Splits a query-style string ("a=1&b=2") into a dictionary of `[key: [values]]`
    private func splitQuery(_ query: String) -> [String: [String]] {
        query
            .components(separatedBy: "&")
            .reduce(into: [String: [String]]()) { result, pair in
                let parts = pair.components(separatedBy: "=")

                guard let rawKey = parts.first,
                      let key = rawKey.removingPercentEncoding
                else { return }

                let rawValue = parts.count > 1 ? parts[1] : ""
                let value = rawValue.removingPercentEncoding ?? rawValue

                result[key, default: []].append(value)
            }
    }

    /// Extracts fragment items (#a=1&b=2)
    var fragmentItems: [String: [String]] {
        guard let fragment else { return [:] }
        return splitQuery(fragment)
    }

    /// Extracts query items (?a=1&b=2)
    var queryItems: [String: [String]] {
        guard let query else { return [:] }
        return splitQuery(query)
    }

    /// Returns "scheme://host" if available
    var schemeAndHostURL: URL? {
        guard let scheme, let host else { return nil }
        return URL(string: "\(scheme)://\(host)")
    }
}
