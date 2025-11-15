//
//  Created by Ricardo Santos on 14/08/2024.
//

@testable import Common
import CoreData
import Foundation

/**

 6 Performance Improvements for Core Data in iOS Apps

 https://stevenpcurtis.medium.com/5-performance-improvements-for-core-data-in-ios-apps-2dbd1ab5d601

 * Avoid using the viewContext for writes and only use it for reads on the main thread.
 * Only save your managed object context if it has changes to prevent unnecessary work.
 * Use NSInMemoryStoreType to test your Core Data implementation without hitting the disk.
 * Consider using multiple managed object contexts to better manage changes and save off the main thread.
 * Use fetch requests to only access the data you need and be mindful of predicates to avoid over-fetching.
 * Use batch processing with NSBatchUpdateRequest and NSBatchDeleteRequest to save time and resources when working with large amounts of data.
 */

//

// MARK: - CRUDEntityDBRepository / Sync Methods

//

extension DatabaseRepository {
    // MARK: - Insert or Update (Upsert)

    func syncStore(_ model: CoreDataSampleUsageNamespace.CRUDEntity) {
        typealias DB = CDataCRUDEntity
        let context = viewContext

        let request = DB.fetchRequestWith(id: model.id)
        request.fetchLimit = 1

        let entity = (try? context.fetch(request))?.first ?? DB(context: context)
        entity.id = model.id
        entity.name = model.name
        entity.recordDate = model.recordDate

        CommonCoreData.Utils.syncSave(viewContext: context)
    }

    // MARK: - Batch Insert

    func syncStoreBatch(_ models: [CoreDataSampleUsageNamespace.CRUDEntity]) {
        typealias DB = CDataCRUDEntity
        let context = viewContext

        let objects = models.map(\.mapToDic)
        let request = NSBatchInsertRequest(entity: DB.entity(), objects: objects)

        _ = try? context.execute(request)
    }

    // MARK: - Update

    func syncUpdate(_ model: CoreDataSampleUsageNamespace.CRUDEntity) {
        typealias DB = CDataCRUDEntity
        let context = viewContext

        let request = DB.fetchRequestWith(id: model.id)
        request.fetchLimit = 1

        if let entity = try? context.fetch(request).first {
            entity.name = model.name
            entity.recordDate = model.recordDate
            CommonCoreData.Utils.syncSave(viewContext: context)
        }
    }

    // MARK: - Delete

    func syncDelete(_ model: CoreDataSampleUsageNamespace.CRUDEntity) {
        typealias DB = CDataCRUDEntity
        let context = viewContext

        let request = DB.fetchRequestWith(id: model.id)
        request.fetchLimit = 1

        if let entity = try? context.fetch(request).first {
            context.delete(entity)
            CommonCoreData.Utils.syncSave(viewContext: context)
        }
    }

    // MARK: - Count

    func syncRecordCount() -> Int {
        typealias DB = CDataCRUDEntity
        return (try? viewContext.count(for: DB.fetchRequest())) ?? 0
    }

    // MARK: - Clear All

    func syncClearAll() {
        typealias DB = CDataCRUDEntity
        CommonCoreData.Utils.batchDelete(context: viewContext, request: DB.fetchRequest())
    }

    // MARK: - Retrieve (Optimized)

    func syncRetrieve(key: String) -> CoreDataSampleUsageNamespace.CRUDEntity? {
        typealias DB = CDataCRUDEntity
        let context = viewContext

        let request = DB.fetchRequestWith(id: key)
        request.fetchLimit = 1
        request.sortDescriptors = [
            NSSortDescriptor(key: #keyPath(CDataCRUDEntity.recordDate), ascending: false),
        ]

        guard let result = try? context.fetch(request).first else { return nil }
        return result.mapToModel
    }

    // MARK: - All IDs (Efficient)

    func syncAllIds() -> [String] {
        typealias DB = CDataCRUDEntity
        let context = viewContext

        let request = NSFetchRequest<NSDictionary>(entityName: DB.entity().name!)
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = ["id"]

        let results = (try? context.fetch(request)) ?? []
        return results.compactMap { $0["id"] as? String }
    }
}
