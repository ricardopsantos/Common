//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import CoreData

//
// MARK: - NSPersistentContainer
//

public extension CommonCoreData.Utils {
    enum Persistence {
        case `default`
        case memory
        case directory(value: FileManager.SearchPathDirectory)
        case appGroup(identifier: String)
    }
}

public extension CommonCoreData.Utils {
    static func buildPersistentContainer(
        dbName: String,
        managedObjectModel: NSManagedObjectModel,
        persistence: Persistence
    ) -> NSPersistentContainer? {
        let container = NSPersistentContainer(name: dbName, managedObjectModel: managedObjectModel)
        switch persistence {
        case .default:
            ()
        case .memory:
            let description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
        case .directory(value: let value):
            if let defaultStoreURL = FileManager.default.urls(for: value, in: .userDomainMask).first {
                let storeURL = defaultStoreURL.appendingPathComponent("\(dbName).sqlite")
                let description = NSPersistentStoreDescription(url: storeURL)
                container.persistentStoreDescriptions = [description]
            }
        case .appGroup(identifier: let identifier):
            if let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) {
                let storeURL = sharedContainerURL.appendingPathComponent("\(dbName).sqlite")
                let description = NSPersistentStoreDescription(url: storeURL)
                container.persistentStoreDescriptions = [description]
            } else {
                Common_Logs.error("Fail to access appGroupIdentifier: \(String(describing: identifier))")
            }
        }

        container.loadPersistentStores { _, error in
            if let error {
                Common_Logs.error("Unresolved error \(error), \(error.localizedDescription)")
            } else {
                CommonCoreData.Utils.printDBReport(
                    dbName: dbName,
                    container: container,
                    managedObjectModel: managedObjectModel
                )
            }
        }
        return container
    }
}

//
// MARK: - NSPersistentContainer
//

public extension CommonCoreData.Utils {
    static func printDBReport(dbName: String, container: NSPersistentContainer, managedObjectModel: NSManagedObjectModel) {
        let tables = container.managedObjectModel.entitiesByName.keys.description
        let version = managedObjectModel.versionIdentifiers.description.replace("AnyHashable", with: "")
        if let persistentStoreURL = container.persistentStoreCoordinator.persistentStores.first?.url {
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: persistentStoreURL.path)
                if let fileSize = fileAttributes[.size] as? Int64 {
                    let fileSizeInMB = Double(fileSize) / (1024 * 1024)
                    let report = """
                    Loaded DataBase \(dbName)
                      • name: \(dbName)
                      • version: \(version)
                      • tables: \(tables)
                      • size: \(fileSizeInMB) MB
                    """
                    Common_Logs.debug("\(report)")
                }
            } catch {
                Common_Logs.error("\(error.localizedDescription)")
            }
        }
    }
}
