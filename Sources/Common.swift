//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import Combine
import UIKit

internal class CommonBundleFinder {}

public extension Common {
    static var internalDB: String { "CommonDB" }
    static var bundleIdentifier: String {
        Bundle(for: CommonBundleFinder.self).bundleIdentifier ?? ""
    }

    static var coreDataPersistence: CommonCoreData.Utils.Persistence = .default
    
    static func cleanAllData() {
        CommonNetworking.ImageUtils.cleanCache()
        CronometerAverageMetrics.shared.clear()
        Common.LocationUtils.clear()
        CacheManagerForCodableUserDefaultsRepository.shared.syncClearAll()
        Common.CacheManagerForCodableCoreDataRepository.shared.syncClearAll()
        CommonDataBaseRepository.shared.syncClearAll()
        Common.InternalUserDefaults.cleanUserDefaults()
        Common.LogsManager.StorageUtils.deleteAllLogs()
        Common.ImagesFileManager.deleteAll()
    }
}
