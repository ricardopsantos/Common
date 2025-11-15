//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

public extension URLRequest {
    @discardableResult
    func curlCommand(
        doPrint: Bool,
        // prefixCount: Int = Int.max,
        maxLogSize: Int = Common_Logs.maxLogSize
    ) -> String? {
        guard let url else { return nil }

        let newLine = ""
        var command = "curl '\(url.absoluteString)'\(newLine)"

        // Set method
        if let httpMethod {
            command += " -X \(httpMethod)\(newLine)"
        }

        // Set headers
        if let headers = allHTTPHeaderFields {
            let headersSorted = headers.sorted { $0.key < $1.key }
            for (key, value) in headersSorted {
                command += " -H '\(key): \(value)'\(newLine)"
            }
        }

        // Set body data
        if let bodyData = httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8)
        {
            // Escape single quotes for safe curl output
            let escaped = bodyString.replacingOccurrences(of: "'", with: "'\"'\"'")
            command += " -d '\(escaped)'\(newLine)"
        }

        // Remove last newLine–style suffix
        command = command.dropLastIf(newLine)

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

    static func with(
        urlString: String,
        httpMethod: String,
        httpBody: [String: Any]?,
        headerValues: [String: String]?
    ) -> URLRequest? {
        guard let theURL = URL(string: "\(urlString)") else {
            Common_Logs.error("Invalid url [\(urlString)]", "\(Self.self)")
            return nil
        }

        var request = URLRequest(url: theURL)
        request.httpMethod = httpMethod.uppercased()

        // Body handling
        if let httpBody {
            // Case 1: data-raw -> send raw body
            if httpBody.keys.count == 1,
               let dataRaw = httpBody["data-raw"] as? String
            {
                /**
                 curl --request POST 'https://login.microsoftonline.com/xxx-82a0-4bff-b9e9-xxxx/oauth2/token' \
                 --header 'Content-Type: application/x-www-form-urlencoded' \
                 --data-raw 'client_id=xxxx-f206-xxxx-86d8-xxxx&client_secret=b13828ebbc09a965bc&grant_type=client_credentials&resource=https://api.xxxx.com/b2bgateway'
                 */
                request.httpBody = Data(dataRaw.utf8)

                // Case 2: JSON dictionary
            } else if !httpBody.isEmpty {
                do {
                    request.httpBody = try JSONSerialization.data(
                        withJSONObject: httpBody,
                        options: .prettyPrinted
                    )
                } catch {
                    Common_Logs.error(
                        "Fail to serialize httpBody:\n\n\(httpBody)\nError: \(error)",
                        "\(Self.self)"
                    )
                }
            }
        }

        // Apply headers in sorted ordering
        headerValues?
            .sorted { $0.key < $1.key }
            .forEach { key, value in
                request.addValue(value, forHTTPHeaderField: key)
            }

        return request
    }
}
