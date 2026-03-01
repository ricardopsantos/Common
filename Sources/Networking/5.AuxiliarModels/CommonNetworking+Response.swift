//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

public extension CommonNetworking {
    struct Response<T: Decodable> {
        public let model: T
        public let rawResponse: URLResponse

        public var httpResponse: HTTPURLResponse? {
            rawResponse as? HTTPURLResponse
        }

        public var statusCode: Int { httpResponse?.statusCode ?? -1 }
        public var httpStatusCode: HTTPStatusCode {
            HTTPStatusCode(rawValue: statusCode) ?? .unknown
        }
    }
}
