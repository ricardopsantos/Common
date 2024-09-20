//
//  CommonDefault.swift
//  Common
//
//  Created by Ricardo Santos on 29/08/2024.
//

import Foundation
import Combine
import UIKit

public extension Common.UserDefaultsManager {
    enum Keys: String {
        case numberOfLogins
        case locationUtils
        case averageMetrics
        case expiringKeyValueEntity

        var keyPrefix: String {
            "\(Common.self).\(Common.UserDefaultsManager.self)"
        }

        var defaultsKey: String {
            "\(keyPrefix).\(rawValue)"
        }
    }
}

public extension Common {
    struct UserDefaultsManager {
        private init() {}
        public static var prefix: String { "\(Common.self).\(Self.self)" }
        public static var defaults: UserDefaults? {
            let appGroup = Common.bundleIdentifier
            return UserDefaults(suiteName: appGroup)
        }

        public static func reset() {
            let keys = defaults?.dictionaryRepresentation().filter { $0.key.hasPrefix("\(Common.self)") }.map(\.key)
            keys?.forEach { key in
                defaults?.removeObject(forKey: key)
            }
            defaults?.synchronize()
        }
    }
}

public extension Common.UserDefaultsManager {
    static var numberOfLogins: Int {
        let key = Keys.numberOfLogins.defaultsKey
        return defaults?.integer(forKey: key) ?? 0
    }

    @discardableResult
    static func numberOfLoginsIncrement() -> Int {
        let current = numberOfLogins + 1
        defaults?.setValue(current, forKey: Keys.numberOfLogins.defaultsKey)
        return current
    }
}
