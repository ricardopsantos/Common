//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import CoreData
import Foundation

public extension NSManagedObject {
    class var entityName: String {
        String(describing: self).components(separatedBy: ".").last!
    }

    func extractId(extra: String? = nil) -> String? {
        var possibleKeys = [
            "id",
            "key",
            "uid",
            "guid",
            "identifier",
            "record_id",
            "recordId",
            "objectId",
            "object_id",
            "entityId",
            "entity_id",
            "primaryId",
            "primary_id",
        ]
        if let extra, !extra.isEmpty {
            possibleKeys.insert(extra, at: 0)
        }
        var id: String?
        for key in possibleKeys {
            if id == nil, responds(to: Selector(key)), let some = value(forKey: key) {
                if !"\(some)".isEmpty {
                    id = "\(some)"
                    break
                }
            }
        }
        return id
    }
}
