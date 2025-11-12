//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import CoreData

//
// MARK: - Utils CRUD operations
//

public extension CommonCoreData.Utils {
    @discardableResult
    static func batchDelete(
        context: NSManagedObjectContext,
        request: NSFetchRequest<NSFetchRequestResult>
    ) -> Bool {
        do {
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            deleteRequest.resultType = .resultTypeCount
            try context.execute(deleteRequest)
            try context.save()
            try context.parent?.save()
            return true
        } catch {
            context.rollback()
            Common.LogsManager.error("Couldn't delete the entities " + error.localizedDescription, "\(Self.self)")
            return false
        }
    }

    /// Saves the context, at the same time it prints debug messages
    @discardableResult
    static func save(viewContext: NSManagedObjectContext?, canEmitChanges: Bool = true) -> Bool {
        guard let viewContext else { return false }
        var result: Bool?
        let semaphore = DispatchSemaphore(value: 0)
        asyncSave(viewContext: viewContext, canEmitChanges: canEmitChanges) { recordsChanged in
            result = recordsChanged > 0
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 0.1)
        return result ?? false
    }

    static func asyncSave(
        viewContext: NSManagedObjectContext?,
        canEmitChanges: Bool = true,
        completion: @escaping (Int) -> Void
    ) {
        guard let viewContext, viewContext.hasChanges else {
            completion(0)
            return
        }
        enum DBOperation: String {
            case insert = "Inserted"
            case delete = "Deleted"
            case update = "Updated"
        }
        var saveSuccess = false
        let threadInfo: String = (Thread.isMain ? "Main" : "Background") + " Thread"
        var changes: [(dbModelName: String, id: String?, operation: DBOperation)] = []

        func buildInfo(managedObject: NSManagedObject) -> (dbModelName: String, id: String?) {
            let dbModelName = managedObject.entity.name ?? ""
            let id = managedObject.extractId()
            return (dbModelName, id)
        }
        viewContext.insertedObjects.forEach { managedObject in
            let info = buildInfo(managedObject: managedObject)
            changes.append((info.dbModelName, info.id, .insert))
        }
        viewContext.deletedObjects.forEach { managedObject in
            let info = buildInfo(managedObject: managedObject)
            changes.append((info.dbModelName, info.id, .delete))
        }
        viewContext.updatedObjects.forEach { managedObject in
            let info = buildInfo(managedObject: managedObject)
            changes.append((info.dbModelName, info.id, .update))
        }

        func emitChanges() {
            guard canEmitChanges, saveSuccess else { return }
            changes.forEach { (dbModelName: String, id: String?, operation: DBOperation) in
                switch operation {
                case .insert:
                    output.send(.databaseDidInsertRecord(dbModelName, id: id))
                case .delete:
                    output.send(.databaseDidDeleteRecord(dbModelName, id: id))
                case .update:
                    output.send(.databaseDidUpdateRecord(dbModelName, id: id))
                }
            }
            #if DEBUG
            // ✅ Only log when not running unit tests
            guard !ProcessInfo.isRunningUnitTests else { return }

            changes.forEach { (dbModelName: String, _, operation: DBOperation) in
                Common.LogsManager.debug("💾 \(operation.rawValue) record @ [\(dbModelName)] on [\(threadInfo)]", "\(Self.self)")
            }
            #endif
        }

        switch viewContext.concurrencyType {
        case .privateQueueConcurrencyType, .confinementConcurrencyType:
            let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            privateContext.parent = viewContext
            privateContext.performAndWait { [weak viewContext, weak privateContext] in
                do {
                    try privateContext?.save()
                    try viewContext?.save()
                    saveSuccess = true
                    emitChanges()
                } catch {
                    viewContext?.rollback()
                    let nserror = error as NSError
                    Common.LogsManager.error("Unresolved error \(nserror), \(nserror.userInfo)", "\(Self.self)")
                }
                completion(saveSuccess ? changes.count : 0)
            }
        case .mainQueueConcurrencyType:
            do {
                try viewContext.save()
                if let parent = viewContext.parent, parent.hasChanges {
                    try parent.save()
                }
                saveSuccess = true
                emitChanges()
            } catch {
                viewContext.rollback()
                let nserror = error as NSError
                Common.LogsManager.error("Unresolved error \(nserror), \(nserror.userInfo)", "\(Self.self)")
            }
            if Thread.isMainThread {
                completion(saveSuccess ? changes.count : 0)
            } else {
                let mergeContextDelay: TimeInterval = 0.01
                DispatchQueue.executeWithDelay(delay: mergeContextDelay) {
                    completion(saveSuccess ? changes.count : 0)
                }
            }
        @unknown default:
            ()
        }
    }
}
