//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

public extension Data {
    /// Converts the data to a UTF-8 string.
    var utf8String: String? {
        String(data: self, encoding: .utf8)
    }

    /// Converts Data → JSON → pretty-printed JSON string.
    /// Returns nil if the data is not valid JSON.
    var jsonString: String? {
        guard
            let jsonObject = try? JSONSerialization.jsonObject(with: self, options: []),
            let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
            let prettyString = String(data: prettyData, encoding: .utf8)
        else {
            return nil
        }

        return prettyString
    }

    /// Decodes the data using a JSONDecoder with user-defined strategies.
    func toObject<D: Decodable>() throws -> D {
        try JSONDecoder().decodeFriendly(D.self, from: self)
    }

    /// Size in megabytes.
    var sizeInMB: Double {
        Double(count) / (1024 * 1024)
    }
}
