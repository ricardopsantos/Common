//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import Combine
import UIKit
import WebKit

public struct Common {
    private init() {}
    static var internalDB: String { "CommonDB" }
    static var bundleIdentifier: String {
        Bundle(for: CommonBundleFinder.self).bundleIdentifier ?? ""
    }

    static var coreDataPersistence: CommonCoreData.Utils.Persistence = .default

    public static func cleanAllData() {
        WKWebView.cleanAllCookies()
        CommonNetworking.ImageUtils.reset()
        CronometerAverageMetrics.shared.reset()
        Common.LocationUtils.reset()
        Common.UserDefaultsManager.reset()
        Common.LogsManager.Persistence.reset()
        Common.FileManager.reset()
        Common.FileManager.Images.reset()
        Common.ExecutionControlManager.reset()
        CommonNetworking.ImageUtils.reset()
        CacheManagerForCodableUserDefaultsRepository.shared.syncClearAll()
        Common.CacheManagerForCodableCoreDataRepository.shared.syncClearAll()
        //CommonDataBaseRepository.shared.syncClearAll()
    }
}

//
// MARK: - Namespaces
//

internal class CommonBundleFinder {}
public struct Common_Preview { }

//
// MARK: - Alias: Main
//

public typealias Common_Utils = Common.Utils
public typealias Common_Logs = Common.LogsManager

// MARK: - Alias: SwiftUI

public typealias Common_ViewControllerRepresentable = Common.ViewControllerRepresentable
public typealias Common_ViewRepresentable = Common.ViewRepresentable2

// MARK: - Others
public typealias Common_CronometerManager = Common.CronometerManager
public typealias Common_PropertyWrappers = Common.PropertyWrappers
