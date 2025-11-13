//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import CoreData
import Foundation

//

// MARK: - Utils CRUD operations

//

public extension CommonCoreData.Utils {
    // MARK: - Batch Delete

    @discardableResult
    static func batchDelete(
        context: NSManagedObjectContext,
        request: NSFetchRequest<NSFetchRequestResult>
    ) -> Bool {
        do {
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            deleteRequest.resultType = .resultTypeCount

            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult

            // Merge changes into context so it stays consistent
            if let deletedIDs = result?.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: deletedIDs]
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: changes,
                    into: [context]
                )
            }

            try context.save()
            try context.parent?.save()

            return true

        } catch {
            // ❗Do NOT use rollback after batch delete
            context.reset()

            Common.LogsManager.error(
                "Couldn't batch delete entities: \(error.localizedDescription)",
                "\(Self.self)"
            )
            return false
        }
    }

    // MARK: - Synchronous Save Wrapper

    // MARK: - Exclusive Save Lock

    // private static let syncSaveLockQueue = DispatchQueue(
    //    label: "CommonCoreData.Utils.syncSave.lock.queue",
    //    qos: .userInitiated
    // )

    private static let syncSaveGroup = DispatchGroup()

    // MARK: - Public Synchronous Save Wrapper (Safe)

    @discardableResult
    static func syncSave(
        viewContext: NSManagedObjectContext?,
        canEmitChanges: Bool = true
    ) -> Bool {
        guard let viewContext else { return false }

        var finalResult = false

        // Ensure only one save operation at a time
        // syncSaveLockQueue.sync {
        syncSaveGroup.enter()

        aSyncSave(viewContext: viewContext, canEmitChanges: canEmitChanges) { changed in
            finalResult = changed > 0
            syncSaveGroup.leave()
        }

        // Wait for aSyncSave to complete
        syncSaveGroup.wait()
        //  }

        return finalResult
    }

    // MARK: - Asynchronous Save (CRASH-FREE)

    static func aSyncSave(
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

        let threadInfo = Thread.isMainThread ? "Main Thread" : "Background Thread"

        var saveSuccess = false
        var changes: [(model: String, id: String?, op: DBOperation)] = []

        // MARK: - Snapshot Core Data change sets (❗required to avoid crashes)

        let insertedSnapshot = viewContext.insertedObjects
        let deletedSnapshot = viewContext.deletedObjects
        let updatedSnapshot = viewContext.updatedObjects

        func buildInfo(_ obj: NSManagedObject) -> (String, String?) {
            let name = obj.entity.name ?? ""
            let id = obj.extractId()
            return (name, id)
        }

        // Capturing snapshots is safe
        for obj in insertedSnapshot {
            let info = buildInfo(obj)
            changes.append((info.0, info.1, .insert))
        }
        for obj in deletedSnapshot {
            let info = buildInfo(obj)
            changes.append((info.0, info.1, .delete))
        }
        for obj in updatedSnapshot {
            let info = buildInfo(obj)
            changes.append((info.0, info.1, .update))
        }

        // MARK: - Emit change notifications

        func emitChanges() {
            guard canEmitChanges, saveSuccess else { return }

            for (model, id, op) in changes {
                switch op {
                case .insert: output.send(.databaseDidInsertRecord(model, id: id))
                case .delete: output.send(.databaseDidDeleteRecord(model, id: id))
                case .update: output.send(.databaseDidUpdateRecord(model, id: id))
                }
            }

            #if DEBUG
                guard !ProcessInfo.isRunningUnitTests else { return }
                for (model, _, op) in changes {
                    Common.LogsManager.debug("💾 \(op.rawValue) @ [\(model)] on [\(threadInfo)]", "\(Self.self)")
                }
            #endif
        }

        // MARK: - Private Queue Context Save

        if viewContext.concurrencyType == .privateQueueConcurrencyType ||
            viewContext.concurrencyType == .confinementConcurrencyType
        {
            viewContext.perform {
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

                completion(saveSuccess ? changes.count : 0)
            }
        }

        // MARK: - Main Queue Save

        if viewContext.concurrencyType == .mainQueueConcurrencyType {
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

            // Call completion safely
            if Thread.isMainThread {
                completion(saveSuccess ? changes.count : 0)
            } else {
                DispatchQueue.main.async {
                    completion(saveSuccess ? changes.count : 0)
                }
            }
        }
    }
}
