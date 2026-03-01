//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import CoreData
import Foundation

public extension NSManagedObject {
    /// Returns the Core Data entity name for this NSManagedObject subclass.
    /// Uses the class name without module prefix.
    class var entityName: String {
        String(describing: self).components(separatedBy: ".").last ?? ""
    }

    /// Attempts to extract a reasonable identifier from the managed object.
    /// It searches for the following common key names (in order):
    ///
    /// ```
    /// id, key, uid, guid, identifier,
    /// record_id, recordId, objectId, object_id,
    /// entityId, entity_id, primaryId, primary_id
    /// ```
    ///
    /// - Parameter extra: A custom key name to try first.
    /// - Returns: The ID value converted to a String, or `nil` if not found.
    func extractId(extra: String? = nil) -> String? {
        // Most common ID keys in real-world Core Data models
        var keys = [
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

        // Insert custom key at highest priority
        if let extra, !extra.isEmpty {
            keys.insert(extra, at: 0)
        }

        for key in keys {
            // Avoid KVC crashes by checking availability
            guard entity.attributesByName.keys.contains(key) else { continue }

            let value = value(forKey: key)

            if let v = value, !"\(v)".isEmpty {
                return "\(v)"
            }
        }

        return nil
    }
}
