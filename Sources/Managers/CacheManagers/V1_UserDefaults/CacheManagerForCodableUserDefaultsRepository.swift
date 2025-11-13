//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Combine
import Foundation

//

// MARK: - CacheManagerForCodableUserDefaultsRepository

//

public extension Common {
    final class CacheManagerForCodableUserDefaultsRepository: CodableCacheManagerProtocol {
        private init() {}
        public static let shared = CacheManagerForCodableUserDefaultsRepository()

        // MARK: - Private helpers

        @inline(__always)
        private func defaults() -> UserDefaults? { Common.UserDefaultsManager.defaults }

        @inline(__always)
        private func composedKey(_ key: String, _ params: [any Hashable]) -> String {
            Commom_ExpiringKeyValueEntity.composedKey(key, params)
        }

        private func decodeEntity(from data: Data) -> Commom_ExpiringKeyValueEntity? {
            // Use your custom friendly decoder if available; fallback to plain JSONDecoder.
            if let entity = try? JSONDecoder().decodeFriendly(Commom_ExpiringKeyValueEntity.self, from: data) {
                return entity
            }
            return try? JSONDecoder().decode(Commom_ExpiringKeyValueEntity.self, from: data)
        }

        private func encodeEntity(_ entity: Commom_ExpiringKeyValueEntity) -> Data? {
            (try? JSONEncoder().encode(entity))
        }

        private func purgeIfExpired(_ key: String, entity: Commom_ExpiringKeyValueEntity) {
            guard let expire = entity.expireDate, expire < Date() else { return }
            defaults()?.removeObject(forKey: key)
        }

        // MARK: - Sync

        public func syncStore(
            _ codable: some Codable,
            key: String,
            params: [any Hashable],
            timeToLiveMinutes: Int? = nil
        ) {
            let entity = Commom_ExpiringKeyValueEntity(
                codable,
                key: key,
                params: params,
                timeToLiveMinutes: timeToLiveMinutes
            )
            guard let composedKey = entity.key, !composedKey.isEmpty else { return }
            guard let _data = encodeEntity(entity) else {
                Common_Logs.error("Failed to encode entity for key: \(key)", "\(Self.self)")
                return
            }
            defaults()?.set(_data, forKey: composedKey)
            // Avoids deprecated/ineffective synchronize(); the system flushes at appropriate times.
        }

        public func syncRetrieve<T: Codable>(_: T.Type, key: String,
                                             params: [any Hashable]) -> (model: T, recordDate: Date)?
        {
            let cKey = composedKey(key, params)
            guard let data = defaults()?.data(forKey: cKey),
                  let entity = decodeEntity(from: data) else { return nil }

            // TTL enforcement
            purgeIfExpired(cKey, entity: entity)
            if let expire = entity.expireDate, expire < Date() { return nil }

            guard let model = entity.extract(T.self) else { return nil }
            return (model, entity.recordDate)
        }

        public func syncAllCachedKeys() -> [(String, Date)] {
            guard let defaults = defaults() else { return [] }
            let prefix = Common.UserDefaultsManager.Keys.expiringKeyValueEntity.defaultsKey
            let keys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(prefix) }
            let pairs: [(String, Date)] = keys.compactMap { key in
                guard let data = defaults.data(forKey: key),
                      let entity = decodeEntity(from: data) else { return nil }
                return (key, entity.recordDate)
            }
            // Newest first
            return pairs.sorted { $0.1 > $1.1 }
        }

        public func syncClearAll() {
            guard let defaults = defaults() else { return }
            let prefix = Common.UserDefaultsManager.Keys.expiringKeyValueEntity.defaultsKey
            defaults.dictionaryRepresentation().keys
                .filter { $0.hasPrefix(prefix) }
                .forEach { defaults.removeObject(forKey: $0) }
        }

        // MARK: - Async (lightweight wrappers over sync)

        public func aSyncStore(
            _ codable: some Codable,
            key: String,
            params: [any Hashable],
            timeToLiveMinutes: Int?
        ) async {
            await withCheckedContinuation { continuation in
                syncStore(codable, key: key, params: params, timeToLiveMinutes: timeToLiveMinutes)
                continuation.resume()
            }
        }

        public func aSyncRetrieve<T: Codable>(_ type: T.Type, key: String,
                                              params: [any Hashable]) async -> (model: T, recordDate: Date)?
        {
            await withCheckedContinuation { continuation in
                let result = syncRetrieve(type, key: key, params: params)
                continuation.resume(returning: result)
            }
        }

        public func aSyncClearAll() async {
            await withCheckedContinuation { continuation in
                syncClearAll()
                continuation.resume()
            }
        }

        public func aSyncAllCachedKeys() async -> [(String, Date)] {
            await withCheckedContinuation { continuation in
                let result = syncAllCachedKeys()
                continuation.resume(returning: result)
            }
        }
    }
}
