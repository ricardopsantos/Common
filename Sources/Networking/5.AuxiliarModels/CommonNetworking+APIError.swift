//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

public extension CommonNetworking {
    enum APIError: Error {
        case ok // no error

        case genericError(devMessage: String)
        case parsing(description: String, data: Data?)
        case network(description: String)
        case finishWithStatusCodeAndJSONData(
            code: Int,
            description: String?,
            data: Data?,
            jsonString: String?
        )

        /// Wrapper around any unexpected system/framework error.
        case underlying(Error)

        // MARK: - UTILS

        public func isHTTPStatusCode(_ httpStatusCode: CommonNetworking.HTTPStatusCode) -> Bool {
            switch self {
            case let .finishWithStatusCodeAndJSONData(code, _, _, _):
                return CommonNetworking.HTTPStatusCode(rawValue: code) == httpStatusCode
            default:
                return false
            }
        }

        public var isBadRequestHTTPStatusCode: Bool {
            isHTTPStatusCode(.badRequest)
        }

        public var isForbiddenHTTPStatusCode: Bool {
            isHTTPStatusCode(.forbidden)
        }

        public var isUnauthorizedHTTPStatusCode: Bool {
            isHTTPStatusCode(.unauthorized)
        }

        public var isNotFoundHTTPStatusCode: Bool {
            isHTTPStatusCode(.notFound)
        }

        public var isNetworkError: Bool {
            switch self {
            case .network:
                return true
            default:
                return false
            }
        }

        /// Human readable error message (optional helper)
        public var message: String {
            switch self {
            case .ok:
                return "OK"
            case let .genericError(msg):
                return msg
            case let .parsing(desc, _):
                return desc
            case let .network(desc):
                return desc
            case let .finishWithStatusCodeAndJSONData(_, desc, _, _):
                return desc ?? "Unexpected server response"
            case let .underlying(err):
                return err.localizedDescription
            }
        }
    }
}
