//
//  URLSessionConfiguration+Extensions.swift
//  Common
//
//  Created by Ricardo Santos on 20/09/2024.
//

import Foundation
import Network

public extension URLSessionConfiguration {
    static func defaultForNetworkAgent(
        waitsForConnectivity: Bool = false,
        cacheEnabled: Bool = false,
        timeoutIntervalForResource: TimeInterval = URLSession.defaultTimeoutIntervalForResource
    ) -> URLSessionConfiguration {
        let config = URLSessionConfiguration.default

        // Connectivity behavior
        config.waitsForConnectivity = waitsForConnectivity

        // Timeouts
        config.timeoutIntervalForResource = timeoutIntervalForResource
        config.timeoutIntervalForRequest = timeoutIntervalForResource

        if cacheEnabled {
            // Allocate a performant but safe URLCache
            let cache = URLCache(
                memoryCapacity: 20 * 1024 * 1024, // 20 MB
                diskCapacity: 100 * 1024 * 1024, // 100 MB
                diskPath: "URLSession.defaultWithConfig"
            )

            config.urlCache = cache
            config.requestCachePolicy = .returnCacheDataElseLoad

        } else {
            // Disable cache completely
            config.urlCache = nil
            config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        }

        return config
    }
}
