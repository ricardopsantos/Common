//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

public extension Encodable {
    func toData() throws -> Data {
        try JSONEncoder().encode(self)
    }

    var sizeInMB: Double {
        do {
            let dataSizeInBytes = try Double(toData().count)
            let sizeInMB = dataSizeInBytes / (1024 * 1024)
            return sizeInMB
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
        guard let data = try? encoder.encode(self) else {
            return nil
        }
        let jsonObject = try? JSONSerialization.jsonObject(with: data, options: [])
        if let dictionary = jsonObject as? [String: Any] {
            return dictionary
        }
        return nil
    }
}
