//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

public extension ProcessInfo {
    /// Returns `true` when the process is running under **XCTest**.
    /// Works for both local Xcode tests and command-line test runs.
    static var isRunningUnitTests: Bool {
        return processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    /// Returns `true` when the process is running under **UI Tests**.
    /// Only true if your UI Test target sets this value:
    ///
    /// In UI Test `setUp()`:
    /// ```swift
    /// app.launchEnvironment["UITest"] = "1"
    /// ```
    static var isRunningUITests: Bool {
        return processInfo.environment["UITest"] == "1"
    }

    /// True if **any** type of test is running.
    static var isRunningTests: Bool {
        return isRunningUnitTests || isRunningUITests
    }
}
