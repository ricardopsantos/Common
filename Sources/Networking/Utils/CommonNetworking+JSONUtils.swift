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
        /// Returns in success: Dictionary<String, Any> or [Dictionary<String, Any>]
        static func jsonFrom(
            _ urlString: String,
            completion: @escaping ((AnyObject?, Bool) -> Void)
        ) {
            DataUtils.dataFrom(urlString) { data, success in

                guard success, let data else {
                    completion(nil, false)
                    return
                }

                // Try decode JSON safely
                guard let object = try? JSONSerialization.jsonObject(with: data, options: []) else {
                    completion(nil, false)
                    return
                }

                // Map only the supported types
                if let dict = object as? [String: Any] {
                    completion(dict as AnyObject, true)
                } else if let array = object as? [[String: Any]] {
                    completion(array as AnyObject, true)
                } else {
                    completion(nil, false)
                }
            }
        }
    }
}
