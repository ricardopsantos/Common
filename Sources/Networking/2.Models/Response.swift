//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import Combine
import Security
import CommonCrypto

public extension CommonNetworking {
    //
    // MARK: - Response
    //

    struct Response<T: Decodable> {
        public let modelDto: T
        public let response: Any

        public init(modelDto: T, response: Any) {
            self.modelDto = modelDto
            self.response = response
        }

        /// The transport's `URLResponse`, when there was one.
        public var urlResponse: URLResponse? { response as? URLResponse }

        public var statusCode: Int? {
            if let urlResponse = response as? HTTPURLResponse {
                return urlResponse.statusCode
            }
            return nil
        }

        public var httpStatusCode: HTTPStatusCode {
            guard let statusCode else {
                return .unknown
            }
            return HTTPStatusCode(rawValue: statusCode) ?? .unknown
        }
    }
}
