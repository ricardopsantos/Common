//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import CoreData
import Combine

//
// MARK: - CommonBaseCoreDataManager
//

open class CommonBaseCoreDataManager: NSObject, SyncCoreDataManagerCRUDProtocol {
    //
    // MARK: - Usage Propertyes
    //
    fileprivate let dbName: String
    fileprivate let managedObjectModelURL: URL?
    fileprivate let managedObjectModel: NSManagedObjectModel
    fileprivate let persistentContainer: NSPersistentContainer!
    static var output = PassthroughSubject<OutputType, Never>()
    public var fetchedResultsController: [String: NSFetchedResultsController<NSManagedObject>] = [:]

    public var databaseURL: URL {
        let storeDescription = persistentContainer.persistentStoreDescriptions.first
        return storeDescription?.url ?? NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("\(dbName).sqlite")
    }

    //
    // MARK: - Config
    //
    open func viewContextIsShared() -> Bool {
        false // Can be overridden
    }

    open func startFetchedResultsController() {
        // Should be overridden to start "listening" db changes
    }

    public init(dbName: String, managedObjectModel: NSManagedObjectModel, persistence: CommonCoreData.Utils.Persistence) {
        self.dbName = dbName
        self.managedObjectModel = managedObjectModel
        self.managedObjectModelURL = nil
        if let persistentContainer = CommonCoreData.Utils.buildPersistentContainer(
            dbName: dbName,
            managedObjectModel: managedObjectModel,
            persistence: persistence
        ) {
            self.persistentContainer = persistentContainer
        } else {
            fatalError("fail to load persistentContainer")
        }
        super.init()
        startFetchedResultsController()
    }

    public init(dbName: String, dbBundle: String, persistence: CommonCoreData.Utils.Persistence) {
        self.dbName = dbName
        if let nsManagedObjectModel = CommonCoreData.Utils.managedObjectModel(dbName: dbName, dbBundle: dbBundle) {
            self.managedObjectModel = nsManagedObjectModel.managedObjectModel
            self.managedObjectModelURL = nsManagedObjectModel.url
        } else if let nsManagedObjectModel = CommonCoreData.Utils.managedObjectModelForSPM(dbName: dbName) {
            self.managedObjectModel = nsManagedObjectModel.managedObjectModel
            self.managedObjectModelURL = nsManagedObjectModel.url
        } else {
            fatalError("fail to load managedObjectModel")
        }
        if let persistentContainer = CommonCoreData.Utils.buildPersistentContainer(
            dbName: dbName,
            managedObjectModel: managedObjectModel,
            persistence: persistence
        ) {
            self.persistentContainer = persistentContainer
        } else {
            fatalError("fail to load persistentContainer")
        }
        super.init()
        startFetchedResultsController()
    }

    public func save() {
        saveContext()
    }

    /// Default View Context
    public var viewContext: NSManagedObjectContext {
        viewContextIsShared() ? lazyViewContext : newViewContextInstance
    }

    public var backgroundContext: NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        return context
    }

    //
    // MARK: - Private
    //

    private var newViewContextInstance: NSManagedObjectContext {
        if Common_Utils.false {
            return CommonCoreData.Utils.mainViewContext(storeContainer: persistentContainer, automaticallyMergesChangesFromParent: true)
        } else {
            let context = persistentContainer.viewContext
            context.automaticallyMergesChangesFromParent = true
            return context
        }
    }

    private lazy var lazyViewContext: NSManagedObjectContext = {
        if Common_Utils.false {
            return CommonCoreData.Utils.mainViewContext(storeContainer: persistentContainer, automaticallyMergesChangesFromParent: true)
        } else {
            let context = persistentContainer.viewContext
            context.automaticallyMergesChangesFromParent = true
            return context
        }
    }()
}

//
// MARK: - iCould utils - Load/Unload/Replace database
//

public extension CommonBaseCoreDataManager {
    func replaceDatabase(newDatabaseURL: URL) {
        unloadDatabase()
        replaceDatabase(with: newDatabaseURL)
        reloadDatabase()
    }

    func unloadDatabase() {
        guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
            Common_Logs.error("Persistent store URL not found")
            return
        }
        let persistentStoreCoordinator = persistentContainer.persistentStoreCoordinator
        do {
            if let store = persistentStoreCoordinator.persistentStore(for: storeURL) {
                try persistentStoreCoordinator.remove(store)
                Common_Logs.debug("Successfully unloaded the database at \(storeURL)")
            }
        } catch {
            Common_Logs.error("Failed to unload database: \(error)")
        }
    }

    func replaceDatabase(with newDatabaseURL: URL) {
        let fileManager = FileManager.default
        do {
            // Remove the old database
            let oldDatabaseURL = databaseURL
            if fileManager.fileExists(atPath: oldDatabaseURL.path) {
                try fileManager.removeItem(at: oldDatabaseURL)
                Common_Logs.debug("Old database at \(oldDatabaseURL) deleted.")
            }

            // Copy the new database to the same location
            try fileManager.copyItem(at: newDatabaseURL, to: oldDatabaseURL)
            Common_Logs.debug("New database copied to \(oldDatabaseURL).")
        } catch {
            Common_Logs.error("Error replacing database: \(error)")
        }
    }

    func reloadDatabase() {
        guard let persistentStoreDescription = persistentContainer.persistentStoreDescriptions.first else {
            Common_Logs.error("Persistent store description not found")
            return
        }
        let persistentStoreCoordinator = persistentContainer.persistentStoreCoordinator

        do {
            try persistentStoreCoordinator.addPersistentStore(
                ofType: persistentStoreDescription.type,
                configurationName: nil,
                at: persistentStoreDescription.url,
                options: persistentStoreDescription.options
            )
            Common_Logs.debug("Successfully reloaded the new database.")
        } catch {
            Common_Logs.error("Failed to unload database: \(error)")
        }
    }
}
