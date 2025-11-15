//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import UIKit

public extension Common {
    struct Utils {
        private init() {}

        // MARK: - Simple helpers

        public static var `true`: Bool { true }
        public static var `false`: Bool { false }

        public static func delay(_ delay: Double = 0.1, block: @escaping () -> Void) {
            DispatchQueue.executeWithDelay(delay: delay, block: block)
        }

        // MARK: - Environment detection

        public static var onUnitTests: Bool {
            ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        }

        public static var onUITests: Bool {
            let env = ProcessInfo.processInfo.environment
            return env["UITestRunner"] == "1" || env["XCUI_TESTING"] == "1"
        }

        public static var onDebug: Bool {
            #if DEBUG
                return true
            #else
                return false
            #endif
        }

        public static var onRelease: Bool {
            !onDebug
        }

        public static var onSimulator: Bool {
            #if targetEnvironment(simulator)
                return true
            #else
                return false
            #endif
        }

        public static var onDevice: Bool {
            !onSimulator
        }

        // Compatibility alias
        public static var isSimulator: Bool { onSimulator }
        public static var isRealDevice: Bool { !onSimulator }

        // MARK: - Thread helpers

        public static func executeInMainTread(_ block: @escaping () -> Void) {
            DispatchQueue.executeInMainTread(block)
        }

        public static func executeInUserInteractiveTread(_ block: @escaping () -> Void) {
            DispatchQueue.executeInUserInteractiveTread(block)
        }

        public static func executeInBackgroundTread(_ block: @escaping () -> Void) {
            DispatchQueue.executeInBackgroundTread(block)
        }

        // MARK: - Sender / Caller tracing

        public static func senderCodeId(
            _ function: String = #function,
            file: String = #file,
            line: Int = #line,
            showLine: Bool = isRealDevice
        ) -> String {
            let fileName = file.split(separator: "/").last.map(String.init) ?? "UnknownFile"
            var sender = "\(fileName), func/var \(function)"
            if showLine {
                sender += ", line \(line)"
            }
            return sender
        }

        // MARK: - Networking

        public static func existsInternetConnection(_ method: CommonNetworking.Reachability.Method = .default) -> Bool {
            CommonNetworking.Reachability.isConnectedToNetwork(method)
        }

        // MARK: - Assertions

        /// Custom assert that logs instead of crashing in DEBUG mode.
        public static func assert(
            _ value: @autoclosure () -> Bool,
            message: @autoclosure () -> String = "",
            function: StaticString = #function,
            file: StaticString = #file,
            line: Int = #line
        ) {
            guard onDebug else { return }

            if !value() {
                LogsManager.error(
                    "Assert condition not met! \(message())",
                    "\(Self.self)",
                    function: "\(function)",
                    file: "\(file)",
                    line: line
                )
            }
        }
    }
}
