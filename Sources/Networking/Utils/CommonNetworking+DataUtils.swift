//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import UIKit

//
// DataUtils
//

public extension CommonNetworking {
    enum DataUtils {
        /// this function is fetching the json from URL
        @discardableResult
        public static func dataFrom(
            _ urlString: String,
            completion: @escaping ((Data?, Bool) -> Void)
        ) -> URLSessionDataTask? {
            guard let url = URL(string: urlString) else {
                assertionFailure("Invalid url : \(urlString)")
                DispatchQueue.main.async { completion(nil, false) }
                return nil
            }

            let task = URLSession.shared.dataTask(with: url) { data, response, error in

                // Handle errors first
                if let error {
                    assertionFailure("URLSession error: \(error.localizedDescription)")
                    DispatchQueue.main.async { completion(nil, false) }
                    return
                }

                // Validate response
                guard let httpResponse = response as? HTTPURLResponse else {
                    assertionFailure("Invalid response type for URL: \(url)")
                    DispatchQueue.main.async { completion(nil, false) }
                    return
                }

                guard (200 ... 299).contains(httpResponse.statusCode) else {
                    assertionFailure("Bad status: \(httpResponse.statusCode) for URL: \(url)")
                    DispatchQueue.main.async { completion(nil, false) }
                    return
                }

                // Validate data
                guard let data else {
                    assertionFailure("Empty data received for URL: \(url)")
                    DispatchQueue.main.async { completion(nil, false) }
                    return
                }

                // Success
                DispatchQueue.main.async { completion(data, true) }
            }

            task.resume()
            return task
        }
    }
}
