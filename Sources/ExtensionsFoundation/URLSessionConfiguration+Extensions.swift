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
        config.waitsForConnectivity = waitsForConnectivity
        if cacheEnabled {
            config.timeoutIntervalForResource = timeoutIntervalForResource
            let cache = URLCache(
                memoryCapacity: 20 * 1024 * 1024,
                diskCapacity: 100 * 1024 * 1024,
                diskPath: "URLSession.defaultWithConfig"
            )
            config.urlCache = cache
            config.requestCachePolicy = .returnCacheDataElseLoad
        } else {
            config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        }
        return config
    }
}
