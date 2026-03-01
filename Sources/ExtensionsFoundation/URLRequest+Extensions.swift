//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos.
//

import Foundation

public extension URLRequest {
    // MARK: - curlCommand

    @discardableResult
    func curlCommand(
        doPrint: Bool,
        // prefixCount: Int = Int.max,
        maxLogSize: Int = Common_Logs.maxLogSize
    ) -> String? {
        guard let url else { return nil }

        let newLine = ""
        var command = "curl '\(url.absoluteString)'\(newLine)"

        // HTTP Method
        if let method = httpMethod {
            command += " -X \(method)\(newLine)"
        }

        // Headers
        if let headers = allHTTPHeaderFields {
            for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
                // Escape single quotes in header values
                let safeValue = value.replacingOccurrences(of: "'", with: "'\"'\"'")
                command += " -H '\(key): \(safeValue)'\(newLine)"
            }
        }

        // Body
        if let body = httpBody,
           let bodyString = String(data: body, encoding: .utf8)
        {
            // Escape single quotes for safe curl output
            let escaped = bodyString.replacingOccurrences(of: "'", with: "'\"'\"'")
            command += " -d '\(escaped)'\(newLine)"
        }

        // Trim trailing newline if present
        command = command.dropLastIf(newLine)

        // Printing
        if doPrint {
            // swiftlint:disable logs_rule_1
            if command.count > maxLogSize {
                print(command.prefix(maxLogSize))
            } else {
                print(command)
            }
            // swiftlint:enable logs_rule_1
        }

        return command
    }

    // MARK: - Request Builder

    /// Safe, predictable URLRequest builder.
    static func with(
        urlString: String,
        httpMethod: String,
        httpBody: [String: Any]?,
        headerValues: [String: String]?
    ) -> URLRequest? {
        guard let theURL = URL(string: urlString) else {
            Common_Logs.error("Invalid url [\(urlString)]", "\(Self.self)")
            return nil
        }

        var request = URLRequest(url: theURL)
        request.httpMethod = httpMethod.uppercased()

        // MARK: - Body

        if let bodyDict = httpBody, !bodyDict.isEmpty {
            // Case 1 — raw string payload
            if bodyDict.count == 1, let raw = bodyDict["data-raw"] as? String {
                /**
                 curl --request POST 'https://example.com' \
                 --header 'Content-Type: application/x-www-form-urlencoded' \
                 --data-raw 'key=value&param=123'
                 */
                request.httpBody = Data(raw.utf8)

                // Case 2 — JSON dictionary
            } else {
                do {
                    request.httpBody = try JSONSerialization.data(
                        withJSONObject: bodyDict,
                        options: .prettyPrinted
                    )
                } catch {
                    Common_Logs.error(
                        "Fail to serialize httpBody:\n\n\(bodyDict)\nError: \(error)",
                        "\(Self.self)"
                    )
                }
            }
        }

        // MARK: - Headers (sorted for consistency)

        if let headerValues {
            for (key, value) in headerValues.sorted(by: { $0.key < $1.key }) {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        return request
    }
}
