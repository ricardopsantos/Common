//
//  Created by Ricardo Santos on 14/08/2024.
//

@testable import Common
import Foundation

//
// Mappers
//
extension CDataCRUDEntity {
    var mapToModel: CoreDataSampleUsageNamespace.CRUDEntity? {
        .init(id: id ?? "", name: name ?? "", recordDate: recordDate ?? Date())
    }
}

extension CoreDataSampleUsageNamespace.CRUDEntity {
    var mapToDic: [String: Any] {
        [
            "id": id,
            "name": name,
            "recordDate": recordDate,
        ]
    }
}
