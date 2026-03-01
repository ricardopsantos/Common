//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Combine
@testable import Common
import Foundation

extension SampleWebAPI {
    enum Methods {
        case fetchEmployees(_ request: SampleWebAPI.RequestModel.Employee)
        case updateEmployee(_ request: SampleWebAPI.RequestModel.Employee)
        case httpbin
        case httpBinWith(status: Int)

        var urlRequest: URLRequest? {
            let requestWrapper: CommonNetworking.URLRequestWrapper = .init(
                path: data.path,
                queryItems: queryItems.map { URLQueryItem(name: $0.key, value: $0.value) },
                httpMethod: data.httpMethod,
                httpBody: httpBody,
                headerValues: headerValues,
                serverURL: data.serverURL,
                responseType: responseType
            )
            return requestWrapper.urlRequest
        }
    }
}

extension SampleWebAPI.Methods {
    /// Url paramenters
    var queryItems: [String: String?] {
        switch self {
        case let .updateEmployee(request):
            return [
                "id": request.id,
                "timezone": TimeZone.autoupdatingCurrent.identifier,
            ]
        default:
            return [:]
        }
    }

    var parameters: Encodable? {
        switch self {
        case let .updateEmployee(some):
            return some
        default:
            return nil
        }
    }

    var data: (
        httpMethod: CommonNetworking.HttpMethod,
        serverURL: String,
        path: String
    ) {
        switch self {
        case .fetchEmployees:
            (
                .get,
                "https://gist.githubusercontent.com/ricardopsantos/10a31da1c6981acd216a93cb040524b9",
                "raw/8f0f03e6bdfe0dd522ff494022f3aa7a676e882f/Article_13_G8.json"
            )
        case .updateEmployee:
            (
                .post,
                "https://gist.githubusercontent.com/ricardopsantos/10a31da1c6981acd216a93cb040524b9",
                "raw/8f0f03e6bdfe0dd522ff494022f3aa7a676e882f/Article_13_G8.json"
            )
        case .httpbin:
            (
                .get,
                "https://httpbin.org",
                "json"
            )
        case let .httpBinWith(status: status):
            (
                .get,
                "https://httpbin.org",
                "status/\(status)"
            )
        }
    }

    /// Sugar name
    var name: String {
        switch self {
        case .fetchEmployees: "fetchEmployees"
        case .updateEmployee: "updateUser"
        case .httpbin: "httpbin"
        case .httpBinWith: "httpBinWith"
        }
    }

    var headerValues: [String: String]? {
        nil
    }

    var httpBody: [String: Any]? {
        nil
    }

    var responseType: CommonNetworking.ResponseFormat {
        .json
    }
}
