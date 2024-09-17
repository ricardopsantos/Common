//
//  CommonDefault.swift
//  Common
//
//  Created by Ricardo Santos on 29/08/2024.
//

import Foundation
import Combine
import UIKit

public extension Common.InternalUserDefaults {
    enum Keys: String {
        case numberOfLogins
        case locationUtils
        case averageMetrics
        case expiringKeyValueEntity

        var keyPrefix: String {
            "\(Common.self).\(Common.InternalUserDefaults.self)"
        }

        var defaultsKey: String {
            "\(keyPrefix).\(rawValue)"
        }
    }
}

public extension Common {
    enum Storage {
        public static func cleanAll() {
            CommonNetworking.ImageUtils.cleanCache()
            CronometerAverageMetrics.shared.clear()
            Common.LocationUtils.clear()
            CacheManagerForCodableUserDefaultsRepository.shared.syncClearAll()
            CommonDataBaseRepository.shared.syncClearAll()
            Common.CacheManagerForCodableCoreDataRepository.shared.syncClearAll()
            Common.InternalUserDefaults.cleanUserDefaults()
        }
    }

    struct InternalUserDefaults {
        private init() {}
        public static var prefix: String { "\(Common.self).\(InternalUserDefaults.self)" }
        public static var defaults: UserDefaults? {
            let appGroup = Common.bundleIdentifier
            return UserDefaults(suiteName: appGroup)
        }

        public static func cleanUserDefaults() {
            let keys = defaults?.dictionaryRepresentation().filter { $0.key.hasPrefix("\(Common.self)") }.map(\.key)
            keys?.forEach { key in
                defaults?.removeObject(forKey: key)
            }
            defaults?.synchronize()
        }
    }
}

public extension Common.InternalUserDefaults {
    static var numberOfLogins: Int {
        let key = Common.InternalUserDefaults.Keys.numberOfLogins.defaultsKey
        return Common.InternalUserDefaults.defaults?.integer(forKey: key) ?? 0
    }

    @discardableResult
    static func numberOfLoginsIncrement() -> Int {
        let current = numberOfLogins + 1
        let key = Common.InternalUserDefaults.Keys.numberOfLogins.defaultsKey
        Common.InternalUserDefaults.defaults?.setValue(current, forKey: key)
        return current
    }
}
