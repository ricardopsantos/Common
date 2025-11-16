//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import UIKit

//
// JSON
//

public extension CommonNetworking {
    enum JSONUtils {
        /// Returns on success either:
        ///  - Dictionary<String, Any>
        ///  - Array<Dictionary<String, Any>>
        ///
        /// Completion block always runs on main thread.
        static func jsonFrom(
            _ urlString: String,
            completion: @escaping (AnyObject?, Bool) -> Void
        ) {
            @inline(__always)
            func finish(_ object: AnyObject?, _ ok: Bool) {
                DispatchQueue.main.async {
                    completion(object, ok)
                }
            }

            DataUtils.dataFrom(urlString) { data, success in

                // Handle fetch failure
                guard success, let data else {
                    finish(nil, false)
                    return
                }

                // Parse JSON
                let json: Any
                do {
                    json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
                } catch {
                    assertionFailure("JSON parsing error for URL '\(urlString)': \(error)")
                    finish(nil, false)
                    return
                }

                // Accept ONLY two possible output types
                if let dict = json as? [String: Any] {
                    finish(dict as AnyObject, true)
                } else if let array = json as? [[String: Any]] {
                    finish(array as AnyObject, true)
                } else {
                    assertionFailure(
                        "Unsupported JSON root type for URL '\(urlString)'. " +
                            "Expected object or array of objects, got: \(type(of: json))"
                    )
                    finish(nil, false)
                }
            }
        }
    }
}
