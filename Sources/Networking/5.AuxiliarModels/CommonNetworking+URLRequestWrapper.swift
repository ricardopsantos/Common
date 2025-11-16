//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

public extension CommonNetworking {
    struct URLRequestWrapper {
        public let path: String
        public let queryItems: [URLQueryItem]?
        public let httpMethod: CommonNetworking.HttpMethod
        public let httpBody: [String: Any]?
        public let headerValues: [String: String]?
        public let serverURL: String // baseURLString
        public let responseFormat: CommonNetworking.ResponseFormat

        public init(
            path: String,
            queryItems: [URLQueryItem]?,
            httpMethod: CommonNetworking.HttpMethod,
            httpBody: [String: Any]?,
            headerValues: [String: String]?,
            serverURL: String,
            responseType: CommonNetworking.ResponseFormat
        ) {
            self.path = path
            self.queryItems = queryItems
            self.httpMethod = httpMethod
            self.httpBody = httpBody
            self.headerValues = headerValues
            self.serverURL = serverURL
            responseFormat = responseType
        }

        // MARK: - URLRequest builder

        public var urlRequest: URLRequest? {
            // --- Normalize base URL
            let trimmedBase = serverURL.trim.dropLastIf("/")
            guard var baseComponents = URLComponents(string: String(trimmedBase)) else {
                Common_Logs.error("Invalid base URL: \(serverURL)", "\(Self.self)")
                return nil
            }

            // --- Normalize and encode path
            var cleanedPath = path.trim.dropFirstIf("/")

            // Correct encoding for PATH, not query:
            //   ".urlPathAllowed" is the correct charset.
            if let encoded = cleanedPath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
                cleanedPath = encoded
            }

            // Build final path relative to base
            if cleanedPath.isEmpty {
                // leave baseComponents.path as-is
            } else if baseComponents.path.isEmpty || baseComponents.path == "/" {
                baseComponents.path = "/" + cleanedPath
            } else {
                baseComponents.path = baseComponents.path.dropLastIf("/") + "/" + cleanedPath
            }

            // --- Attach query items (correctly)
            if let queryItems, !queryItems.isEmpty {
                baseComponents.queryItems = queryItems
            }

            // --- Final URL
            guard let finalURL = baseComponents.url else {
                Common_Logs.error("Failed to assemble URL from components", "\(Self.self)")
                return nil
            }

            // --- Build final request
            let request = URLRequest.with(
                urlString: finalURL.absoluteString,
                httpMethod: httpMethod.rawValue,
                httpBody: httpBody,
                headerValues: headerValues
            )

            return request
        }

        // MARK: - curlCommand

        public var curlCommand: String? {
            urlRequest?.curlCommand(doPrint: false)
        }

        // MARK: - Extract JSON Body

        public var httpBodyAsJSON: Any? {
            guard
                let data = urlRequest?.httpBody,
                let json = try? JSONSerialization.jsonObject(with: data, options: [])
            else { return nil }
            return json
        }
    }
}
