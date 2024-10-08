//
//  Created by Ricardo Santos on 13/08/2024.
//

import Foundation
import CoreData
import Combine
@testable import Common

//
// MARK: - CommonDataBaseRepository
//

public class DatabaseRepository: CommonBaseCoreDataManager {
    public static var shared = DatabaseRepository(
        dbName: Common.internalDB,
        dbBundle: Common.bundleIdentifier,
        persistence: Common.coreDataPersistence
    )
    override private init(dbName: String, dbBundle: String, persistence: CommonCoreData.Utils.Persistence) {
        super.init(dbName: dbName, dbBundle: dbBundle, persistence: persistence)
    }

    override public func startFetchedResultsController() {
        guard fetchedResultsController.isEmpty else {
            return
        }

        // Create the controller with specific type
        fetchedResultsController["\(CDataCRUDEntity.self)"] = NSFetchedResultsController<NSManagedObject>(
            fetchRequest: CDataCRUDEntity.fetchRequestAll(sorted: true) as! NSFetchRequest<NSManagedObject>,
            managedObjectContext: viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        fetchedResultsController["\(CDataSinger.self)"] = NSFetchedResultsController<NSManagedObject>(
            fetchRequest: CDataSinger.fetchRequestAll(sorted: true) as! NSFetchRequest<NSManagedObject>,
            managedObjectContext: viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        fetchedResultsController["\(CDataSong.self)"] = NSFetchedResultsController<NSManagedObject>(
            fetchRequest: CDataSong.fetchRequestAll(sorted: true) as! NSFetchRequest<NSManagedObject>,
            managedObjectContext: viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        fetchedResultsController.forEach { _, controller in
            controller.delegate = self
            try? controller.performFetch()
        }
    }
}
