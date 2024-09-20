//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import Network

public extension URLSession {
    static var defaultForNetworkAgent: URLSession {
        defaultWithConfig(
            waitsForConnectivity: false,
            timeoutIntervalForResource: defaultTimeoutIntervalForResource,
            cacheEnabled: false
        )
    }

    static var defaultTimeoutIntervalForResource: TimeInterval { 60 }

    static func defaultWithConfig(
        waitsForConnectivity: Bool,
        timeoutIntervalForResource: TimeInterval = defaultTimeoutIntervalForResource,
        cacheEnabled: Bool = true
    ) -> URLSession {
        let config = URLSessionConfiguration.defaultForNetworkAgent(
            waitsForConnectivity: waitsForConnectivity,
            cacheEnabled: cacheEnabled,
            timeoutIntervalForResource: timeoutIntervalForResource
        )
        return URLSession(configuration: config)
    }
}
