//
//  Created by Ricardo Santos on 14/08/2024.
//

import Foundation
@testable import Common

//
// Mappers
//

extension CDataSong {
    /// `cascade` to avoid dead lock on map (artists adding songs and songs adding back artists)
    func mapToModel(cascade: Bool) -> CoreDataSampleUsageNamespace.Song {
        .init(
            id: id ?? "",
            title: title ?? "",
            releaseDate: releaseDate ?? Date(),
            cascadeSinger: cascade ? singer?.mapToModel : nil
        )
    }
}

extension CoreDataSampleUsageNamespace.Song {
    var mapToDic: [String: Any] {
        [
            "releaseDate": releaseDate,
            "title": title,
            "id": id,
            "cascadeSinger": cascadeSinger ?? ""
        ]
    }
}
