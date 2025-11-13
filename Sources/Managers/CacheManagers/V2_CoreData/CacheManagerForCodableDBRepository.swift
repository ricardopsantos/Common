//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2023 - 2019 Ricardo Santos. All rights reserved.
//

import Combine
import CoreData
import Foundation

public extension Common {
    final class CacheManagerForCodableCoreDataRepository: CommonBaseCoreDataManager {
        public static let shared = CacheManagerForCodableCoreDataRepository(
            dbName: Common.internalDB,
            dbBundle: Common.bundleIdentifier,
            persistence: Common.coreDataPersistence
        )

        override public init(dbName: String, dbBundle: String, persistence: CommonCoreData.Utils.Persistence) {
            super.init(dbName: dbName, dbBundle: dbBundle, persistence: persistence)
        }
    }
}

// MARK: - CodableCacheManagerProtocol

extension Common.CacheManagerForCodableCoreDataRepository: CodableCacheManagerProtocol {
    // MARK: - Private helpers

    private func latestRecordFetchRequest(for composedKey: String) -> NSFetchRequest<CDataExpiringKeyValueEntity> {
        let req: NSFetchRequest<CDataExpiringKeyValueEntity> = CDataExpiringKeyValueEntity.fetchRequest()
        req.predicate = NSPredicate(format: "key == %@", composedKey)
        req.sortDescriptors = [NSSortDescriptor(
            key: #keyPath(CDataExpiringKeyValueEntity.recordDate),
            ascending: false
        )]
        req.fetchLimit = 1
        return req
    }

    // MARK: - Sync

    public func syncRetrieve<T: Codable>(_: T.Type, key: String,
                                         params: [any Hashable]) -> (model: T, recordDate: Date)?
    {
        let composedKey = Commom_ExpiringKeyValueEntity.composedKey(key, params)
        let context = viewContext
        do {
            let request = latestRecordFetchRequest(for: composedKey)
            if let record = try context.fetch(request).first,
               let model = record.asExpiringKeyValueEntity?.extract(T.self)
            {
                return (model, record.recordDate ?? .distantPast)
            }
        } catch {
            Common_Logs.error("syncRetrieve failed: \(error.localizedDescription)", "\(Self.self)")
        }
        return nil
    }

    public func syncStore(
        _ codable: some Codable,
        key: String,
        params: [any Hashable],
        timeToLiveMinutes: Int? = nil
    ) {
        let toStore = Commom_ExpiringKeyValueEntity(
            codable,
            key: key,
            params: params,
            timeToLiveMinutes: timeToLiveMinutes
        )
        guard let composedKey = toStore.key, !composedKey.isEmpty else { return }

        let context = viewContext
        let entity = CDataExpiringKeyValueEntity(context: context)
        entity.key = toStore.key
        entity.recordDate = toStore.recordDate
        entity.expireDate = toStore.expireDate
        entity.encoding = Int16(toStore.encoding)
        entity.object = toStore.object
        entity.objectType = toStore.objectType

        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            context.rollback()
            Common_Logs.error("syncStore save failed: \(error.localizedDescription)", "\(Self.self)")
        }
    }

    public func reset() {
        syncClearAll()
    }

    public func syncClearAll() {
        let context = viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDataExpiringKeyValueEntity.fetchRequest()
        do {
            let count = try context.count(for: fetchRequest)
            guard count > 0 else { return }
        } catch {
            // If count fails, still attempt a batch delete — Core Data can handle it.
        }
        let success = CommonCoreData.Utils.batchDelete(context: context, request: fetchRequest)
        if !success {
            Common_Logs.error("Failed to delete \(CDataExpiringKeyValueEntity.self) records", "\(Self.self)")
        }
    }

    public func syncAllCachedKeys() -> [(String, Date)] {
        let context = viewContext
        let fetchRequest: NSFetchRequest<CDataExpiringKeyValueEntity> = CDataExpiringKeyValueEntity.fetchRequest()
        do {
            let records = try context.fetch(fetchRequest)
            return records.compactMap { rec in
                if let k = rec.key, let d = rec.recordDate { return (k, d) }
                return nil
            }
            .sorted { $0.1 > $1.1 } // newest first by recordDate
        } catch {
            Common_Logs.error("syncAllCachedKeys failed: \(error.localizedDescription)", "\(Self.self)")
            return []
        }
    }

    // MARK: - Async

    public func aSyncClearAll() async {
        let context = backgroundContext
        await withCheckedContinuation { continuation in
            context.perform {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDataExpiringKeyValueEntity.fetchRequest()
                do {
                    let count = try context.count(for: fetchRequest)
                    guard count > 0 else {
                        continuation.resume()
                        return
                    }
                    let delete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    try context.execute(delete)
                    try context.save()
                    try context.parent?.save()
                    continuation.resume()
                } catch {
                    Common_Logs.error("aSyncClearAll failed: \(error.localizedDescription)", "\(Self.self)")
                    context.rollback()
                    continuation.resume()
                }
            }
        }
    }

    public func aSyncRetrieve<T: Codable>(_: T.Type, key: String,
                                          params: [any Hashable]) async -> (model: T, recordDate: Date)?
    {
        let composedKey = Commom_ExpiringKeyValueEntity.composedKey(key, params)
        let context = backgroundContext
        return await withCheckedContinuation { continuation in
            context.perform {
                do {
                    let request = self.latestRecordFetchRequest(for: composedKey)
                    if let record = try context.fetch(request).first,
                       let exp = record.asExpiringKeyValueEntity,
                       let model = exp.extract(T.self),
                       let when = record.recordDate
                    {
                        continuation.resume(returning: (model, when))
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    Common_Logs.error("aSyncRetrieve failed: \(error.localizedDescription)", "\(Self.self)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    public func aSyncStore(
        _ codable: some Codable,
        key: String,
        params: [any Hashable],
        timeToLiveMinutes: Int? = nil
    ) async {
        let toStore = Commom_ExpiringKeyValueEntity(
            codable,
            key: key,
            params: params,
            timeToLiveMinutes: timeToLiveMinutes
        )

        guard let composedKey = toStore.key, !composedKey.isEmpty else {
            Common_Logs.error("Invalid key provided for storage.", "\(Self.self)")
            return
        }

        let context = backgroundContext
        await withCheckedContinuation { continuation in
            context.perform {
                let entity = CDataExpiringKeyValueEntity(context: context)
                entity.key = toStore.key
                entity.recordDate = toStore.recordDate
                entity.expireDate = toStore.expireDate
                entity.encoding = Int16(toStore.encoding)
                entity.object = toStore.object
                entity.objectType = toStore.objectType

                guard context.hasChanges else {
                    continuation.resume()
                    return
                }

                do {
                    try context.save()
                    try context.parent?.save()
                    continuation.resume()
                } catch {
                    Common_Logs.error("aSyncStore save failed: \(error.localizedDescription)", "\(Self.self)")
                    context.rollback()
                    continuation.resume()
                }
            }
        }
    }

    public func aSyncAllCachedKeys() async -> [(String, Date)] {
        let context = backgroundContext
        return await withCheckedContinuation { continuation in
            context.perform {
                let fetchRequest: NSFetchRequest<CDataExpiringKeyValueEntity> = CDataExpiringKeyValueEntity
                    .fetchRequest()
                do {
                    let records = try context.fetch(fetchRequest)
                    let keys: [(String, Date)] = records.compactMap { rec in
                        if let k = rec.key, let d = rec.recordDate { return (k, d) }
                        return nil
                    }
                    .sorted { $0.1 > $1.1 }
                    continuation.resume(returning: keys)
                } catch {
                    continuation.resume(returning: [])
                }
            }
        }
    }
}

// MARK: - Mappers

public extension CDataExpiringKeyValueEntity {
    var asExpiringKeyValueEntity: Commom_ExpiringKeyValueEntity? {
        guard let key,
              let expireDate,
              let object,
              let objectType else { return nil }
        let encodingEnum = Commom_ExpiringKeyValueEntity.ValueEncoding(rawValue: Int(encoding)) ?? .dataPlain
        return Commom_ExpiringKeyValueEntity(
            key: key,
            expireDate: expireDate,
            object: object,
            objectType: objectType,
            encoding: encodingEnum
        )
    }
}
