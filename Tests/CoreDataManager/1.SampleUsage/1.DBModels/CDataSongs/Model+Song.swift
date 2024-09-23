//
//  Created by Ricardo Santos on 13/08/2024.
//

import Foundation
@testable import Common

//
// MARK: - Song
//

extension CoreDataSampleUsageNamespace {
    struct Song: Equatable, Codable {
        public var id: String
        public var title: String
        public var releaseDate: Date
        public var cascadeSinger: CoreDataSampleUsageNamespace.Singer?
        public init(
            id: String,
            title: String,
            releaseDate: Date,
            cascadeSinger: CoreDataSampleUsageNamespace.Singer?
        ) {
            self.id = id
            self.title = title
            self.releaseDate = releaseDate
            self.cascadeSinger = cascadeSinger
        }
    }
}

extension CoreDataSampleUsageNamespace.Song {
    static var random: Self {
        Self(
            id: UUID().uuidString,
            title: "Title \(String.randomWithSpaces(10))",
            releaseDate: Date(),
            cascadeSinger: .random
        )
    }
}
