//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

extension CommonNetworking {
    struct ParsingUtils {
        static func parseCSV(data: Data) throws -> Data {
            // Convert raw data → UTF8 string (safe)
            guard let rawString = String(data: data, encoding: .utf8) else {
                throw APIError.parsing(description: "\(Self.self) CSV encoding fail", data: data)
            }

            // Normalize line endings (handles \n, \r\n, \r)
            let dataString = rawString.replacingOccurrences(of: "\r", with: "")

            // Split lines, ignoring empty ones
            let lines = dataString
                .components(separatedBy: "\n")
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

            guard let headerLine = lines.first else {
                throw APIError.parsing(description: "\(Self.self) CSV missing header", data: data)
            }

            let jsonKeys = headerLine
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }

            var parsedCSV: [[String: String]] = []

            // Process each data row
            for line in lines.dropFirst() {
                let values = line
                    .components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }

                // Build dict safely
                var dict: [String: String] = [:]
                for i in 0 ..< min(jsonKeys.count, values.count) {
                    dict[jsonKeys[i]] = values[i]
                }

                // Avoid adding empty dictionaries
                if !dict.isEmpty {
                    parsedCSV.append(dict)
                }
            }

            // Convert array → JSON Data
            guard let jsonData = try? JSONSerialization.data(withJSONObject: parsedCSV, options: []) else {
                throw APIError.parsing(description: "\(Self.self) CSV → JSON fail", data: data)
            }

            return jsonData
        }
    }
}
