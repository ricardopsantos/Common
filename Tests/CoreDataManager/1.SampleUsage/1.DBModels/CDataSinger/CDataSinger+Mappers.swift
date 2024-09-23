//
//  Created by Ricardo Santos on 14/08/2024.
//

import Foundation
//
@testable import Common
//
// Mappers
//
extension CDataSinger {
    var mapToModel: CoreDataSampleUsageNamespace.Singer {
        var artistSongs: [CDataSong] = []
        if let some = songs?.allObjects as? [CDataSong] {
            artistSongs = some
        }
        return .init(
            id: id ?? "",
            name: name ?? "",
            cascadeSongs: artistSongs.map { $0.mapToModel(cascade: false) }
        )
    }
}

extension CoreDataSampleUsageNamespace.Singer {
    var mapToDic: [String: Any] {
        [
            "id": id,
            "cascadeSongs": cascadeSongs ?? "",
            "name": name
        ]
    }
}
