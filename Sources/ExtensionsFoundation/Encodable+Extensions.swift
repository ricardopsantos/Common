//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

public extension Encodable {
    /// Convert struct/class to JSON `Data`
    func toData() throws -> Data {
        try JSONEncoder().encode(self)
    }

    /// Size of encoded JSON in MB (returns 0 if encoding fails)
    var sizeInMB: Double {
        do {
            let data = try toData()
            return Double(data.count) / (1024 * 1024)
        } catch {
            return 0
        }
    }

    /**
     struct Person: Codable {
         let name: String
         let age: Int
         let address: String
     }

     let person = Person(name: "John", age: 30, address: "123 Main St")
     if let dictionary = person.toDictionary {
         (dictionary)
     } else {
         ("Conversion failed.")
     }
     */
    var toDictionary: [String: Any]? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        // Encode to JSON data
        guard let data = try? encoder.encode(self) else {
            return nil
        }

        // Convert JSON → Dictionary
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []),
              let dictionary = json as? [String: Any]
        else {
            return nil
        }

        return dictionary
    }
}
