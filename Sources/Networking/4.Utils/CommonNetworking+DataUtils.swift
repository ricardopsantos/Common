//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos.
//

import Foundation
import UIKit

public extension CommonNetworking {
    enum DataUtils {
        /// This function fetches raw Data from a URL.
        ///
        /// - Returns: The created `URLSessionDataTask` (so callers may cancel).
        /// - Calls `completion(data, true)` on success, or `(nil, false)` on failure.
        @discardableResult
        public static func dataFrom(
            _ urlString: String,
            completion: @escaping (Data?, Bool) -> Void
        ) -> URLSessionDataTask? {
            // MARK: - Helpers

            @inline(__always)
            func finish(_ data: Data?, _ success: Bool) {
                DispatchQueue.main.async {
                    completion(data, success)
                }
            }

            @inline(__always)
            func fail(_ message: String) {
                assertionFailure(message)
                finish(nil, false)
            }

            // MARK: - URL Validation

            guard let url = URL(string: urlString), !urlString.isEmpty else {
                fail("Invalid URL string: '\(urlString)'")
                return nil
            }

            // MARK: - Request

            let task = URLSession.shared.dataTask(with: url) { data, response, error in

                // 1. Handle basic error
                if let error {
                    fail("URLSession error for \(url): \(error.localizedDescription)")
                    return
                }

                // 2. Validate response object
                guard let http = response as? HTTPURLResponse else {
                    fail("Response is not HTTPURLResponse for: \(url)")
                    return
                }

                // 3. Validate HTTP code
                guard (200 ... 299).contains(http.statusCode) else {
                    fail("HTTP \(http.statusCode) for \(url)")
                    return
                }

                // 4. Validate data
                guard let data else {
                    fail("Received empty Data for \(url)")
                    return
                }

                // 5. SUCCESS
                finish(data, true)
            }

            task.resume()
            return task
        }
    }
}
