//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import CoreLocation
import Foundation

public extension CLPlacemark {
    // MARK: - DTOs

    struct CoreLocationManagerAddressResponse: ModelProtocol {
        public let addressMin: String
        public let addressMax: String
        public let jsonFormat: CLPlacemarkJSONFormat

        public init(addressMin: String, addressMax: String, jsonFormat: CLPlacemarkJSONFormat) {
            self.addressMin = addressMin
            self.addressMax = addressMax
            self.jsonFormat = jsonFormat
        }

        public static var noData: Self {
            .init(
                addressMin: "...",
                addressMax: "...",
                jsonFormat: .init(jsonString: "", jsonAsData: Data(), jsonAsDic: [:])
            )
        }
    }

    struct CLPlacemarkJSONFormat: ModelProtocol {
        public let jsonString: String
        public let jsonAsData: Data
        public let jsonAsDic: [String: String]
        public init(jsonString: String, jsonAsData: Data, jsonAsDic: [String: String]) {
            self.jsonString = jsonString
            self.jsonAsData = jsonAsData
            self.jsonAsDic = jsonAsDic
        }
    }
}

public extension CLPlacemark {
    // MARK: - Public Conversions

    var asCoreLocationManagerAddressResponse: CoreLocationManagerAddressResponse {
        guard let format = asCLPlacemarkJSONFormat else {
            return .noData
        }

        let (min, full) = parsedLocation

        return .init(
            addressMin: min,
            addressMax: full,
            jsonFormat: format
        )
    }

    /// Converts available CLPlacemark fields into JSON-friendly dictionary,
    /// plus JSON String + Data.
    var asCLPlacemarkJSONFormat: CLPlacemarkJSONFormat? {
        // Build dictionary in a clean and scalable way
        var map: [String: String] = [:]

        let fields: [(String, String?)] = [
            ("name", name),
            ("thoroughfare", thoroughfare),
            ("subThoroughfare", subThoroughfare),
            ("locality", locality),
            ("subLocality", subLocality),
            ("administrativeArea", administrativeArea),
            ("subAdministrativeArea", subAdministrativeArea),
            ("postalCode", postalCode),
            ("isoCountryCode", isoCountryCode),
            ("country", country),
            ("inlandWater", inlandWater),
            ("ocean", ocean),
        ]

        for (key, value) in fields {
            if let v = value { map[key] = v }
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: map, options: .prettyPrinted)
            guard let json = String(data: data, encoding: .utf8) else { return nil }

            return .init(
                jsonString: json,
                jsonAsData: data,
                jsonAsDic: map
            )
        } catch {
            return nil
        }
    }

    // MARK: - Parsed Address

    /// Produces:
    /// - addressMin = "Street 12, 70771 City"
    /// - addressFull = "District, Street 12, 70771 City, Germany"
    var parsedLocation: (addressMin: String, addressFull: String) {
        var componentsMin: [String] = []
        var componentsFull: [String] = []

        // Sub-locality / district (full only)
        if let sub = subLocality { componentsFull.append(sub) }

        // Street
        if let street = thoroughfare {
            if let nr = subThoroughfare {
                let fullStreet = "\(street) \(nr)"
                componentsFull.append(fullStreet)
                componentsMin.append(fullStreet)
            } else {
                componentsFull.append(street)
                componentsMin.append(street)
            }
        }

        // ZIP
        if let zip = postalCode {
            componentsFull.append(zip)
            componentsMin.append(zip)
        }

        // City
        if let city = locality {
            componentsFull.append(city)
            componentsMin.append(city)
        }

        // Country (full only)
        if let c = country {
            componentsFull.append(c)
        }

        // Final strings
        let addressFull = componentsFull.joined(separator: ", ")
        let addressMin = componentsMin.joined(separator: ", ")

        return (addressMin, addressFull)
    }
}
