//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

public extension CommonNetworking {
    /// Represents all HTTP status codes grouped by class (1xx–5xx) with helpers.
    enum HTTPStatusCode: Int, Sendable {
        case unknown = -1

        // MARK: - 1xx Informational

        case continueRequest = 100
        case switchingProtocols = 101
        case processing = 102

        // MARK: - 2xx Success

        case ok = 200
        case created = 201
        case accepted = 202
        case nonAuthoritativeInformation = 203
        case noContent = 204
        case resetContent = 205
        case partialContent = 206
        case multiStatus = 207
        case alreadyReported = 208
        case IMUsed = 226

        // MARK: - 3xx Redirection

        case multipleChoices = 300
        case movedPermanently = 301
        case found = 302
        case seeOther = 303
        case notModified = 304
        case useProxy = 305
        case temporaryRedirect = 307
        case permanentRedirect = 308

        // MARK: - 4xx Client Error

        case badRequest = 400
        case unauthorized = 401
        case paymentRequired = 402
        case forbidden = 403
        case notFound = 404
        case methodNotAllowed = 405
        case notAcceptable = 406
        case proxyAuthenticationRequired = 407
        case requestTimeout = 408
        case conflict = 409
        case gone = 410
        case lengthRequired = 411
        case preconditionFailed = 412
        case payloadTooLarge = 413
        case URITooLong = 414
        case unsupportedMediaType = 415
        case rangeNotSatisfiable = 416
        case expectationFailed = 417
        case imATeapot = 418
        case misdirectedRequest = 421
        case unprocessableEntity = 422
        case locked = 423
        case failedDependency = 424
        case tooEarly = 425
        case upgradeRequired = 426
        case preconditionRequired = 428
        case tooManyRequests = 429
        case requestHeaderFieldsTooLarge = 431
        case unavailableForLegalReasons = 451

        // MARK: - 5xx Server Error

        case internalServerError = 500
        case notImplemented = 501
        case badGateway = 502
        case serviceUnavailable = 503
        case gatewayTimeout = 504
        case HTTPVersionNotSupported = 505
        case variantAlsoNegotiates = 506
        case insufficientStorage = 507
        case loopDetected = 508
        case notExtended = 510
        case networkAuthenticationRequired = 511

        // MARK: - Groups

        /// 1xx informational
        public var isInformational: Bool {
            (100 ... 199).contains(rawValue)
        }

        /// 2xx success
        public var isSuccess: Bool {
            (200 ... 299).contains(rawValue)
        }

        /// 3xx redirection
        public var isRedirection: Bool {
            (300 ... 399).contains(rawValue)
        }

        /// 4xx client errors
        public var isClientError: Bool {
            (400 ... 499).contains(rawValue)
        }

        /// 5xx server errors
        public var isServerError: Bool {
            (500 ... 599).contains(rawValue)
        }

        /// True for ANY error (client + server)
        public var isError: Bool {
            isClientError || isServerError
        }

        /// Convert an Int to HTTPStatusCode safely
        public init(code: Int) {
            self = HTTPStatusCode(rawValue: code) ?? .unknown
        }

        /// Human-readable reason phrase (common ones)
        public var reason: String {
            switch self {
            case .ok: return "OK"
            case .created: return "Created"
            case .accepted: return "Accepted"
            case .noContent: return "No Content"
            case .badRequest: return "Bad Request"
            case .unauthorized: return "Unauthorized"
            case .forbidden: return "Forbidden"
            case .notFound: return "Not Found"
            case .methodNotAllowed: return "Method Not Allowed"
            case .tooManyRequests: return "Too Many Requests"
            case .internalServerError: return "Internal Server Error"
            case .serviceUnavailable: return "Service Unavailable"
            case .gatewayTimeout: return "Gateway Timeout"
            default: return "HTTP \(rawValue)"
            }
        }
    }
}
