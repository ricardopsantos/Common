//
//  Created by Ricardo Santos on 13/08/2024.
//

import Foundation
@testable import Common

//
// MARK: - Singer
//

extension CoreDataSampleUsageNamespace {
    struct Singer: Equatable, Codable {
        public var id: String
        public var name: String
        public var cascadeSongs: [CoreDataSampleUsageNamespace.Song]?
        public init(id: String, name: String, cascadeSongs: [CoreDataSampleUsageNamespace.Song]) {
            self.id = id
            self.name = name
            self.cascadeSongs = cascadeSongs
        }
    }
}

extension CoreDataSampleUsageNamespace.Singer {
    static var random: Self {
        Self(
            id: UUID().uuidString,
            name: "Joe \(String.randomWithSpaces(10))",
            cascadeSongs: [.random, .random]
        )
    }
}
