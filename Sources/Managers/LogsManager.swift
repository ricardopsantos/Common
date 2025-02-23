//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import UIKit

// swiftlint:disable logs_rule_1

// MARK: - Logger (Public)

public extension Common {
    class LogsManager {
        private init() {}
        public static var counterTotal = 0
        public static var counterErrors = 0
        public static var maxLogSize = 5000
        public enum LogTemplate {
            case log(_ any: Any)
            case flow(name: String, message: String)
            case viewInit(_ origin: String, function: String = #function)
            case appLifeCycle(_ message: Any)
            case warning(_ message: Any)
            case retry(_ message: Any, i: Int, maxI: Int = 1, error: Any)
            case valueChanged(_ origin: String, _ key: String, _ value: String?)
            case screenIn(_ origin: String)
            case screenOut(_ origin: String)
            case onAppear(_ origin: String)
            case onDisappear(_ origin: String)
            case tapped(_ origin: String, _ message: String)
            var log: String {
                switch self {
                case .retry(let message, i: let i, maxI: let maxI, error: let error):
                    if i == 1, maxI == 1 {
                        return "⚠️ Will retry once [\(message)] ⚠️\n\(error)"
                    } else if i != maxI {
                        return "⚠️ Will retry [\(i)/\(maxI)] [\(message)] ⚠️\n\(error)"
                    } else if i == maxI {
                        return "⚠️ Will retry LAST [\(message)] ⚠️\n\(error)"
                    } else {
                        return "⚠️ Will retry [\(message)] ⚠️\n\(error)"
                    }
                case .warning(let message):
                    return "⚠️ \(message) ⚠️\n"
                case .log(let any):
                    return "\(any)"
                case .viewInit(let origin, let function):
                    return "👶🏻 \(origin) 👶🏻 \(function)"
                case .appLifeCycle(let message):
                    return "🔀 🔀 App Life Cycle 🔀 🔀: \(message)"
                case .flow(let name, let message):
                    return "🔑 Flow: \(name) 🔑 \(message)"
                case .screenIn(let origin):
                    return "➡️ Screen In ➡️ \(origin)"
                case .screenOut(let origin):
                    return "⬅️ Screen Out ⬅️ \(origin)"
                case .onAppear(let origin):
                    return "➡️ onAppear ➡️ \(origin)"
                case .onDisappear(let origin):
                    return "⬅️ onDisappear ⬅️ \(origin)"
                case .tapped(let origin, let message):
                    return "👆 \(origin) 👆 Tapped [\(message)] 👆"
                case .valueChanged(let origin, let key, let value):
                    if value == nil {
                        return "💾 \(origin) 💾 Value of [\(key)] was deleted"
                    }
                    guard let value else {
                        return ""
                    }
                    if value.isEmpty {
                        return "💾 \(origin) 💾 Value of [\(key)] changed"
                    } else {
                        return "💾 \(origin) 💾 Value of [\(key)] changed/updated to [\(value)]"
                    }
                }
            }
        }

        /// Things that must be fixed and shouldn't happen. This logs will always be printed (unless Prod apps)
        public static func error(
            _ any: any Error,
            _ tag: String,
            function: String = #function,
            file: String = #file,
            line: Int = #line
        ) {
            error("\(any)", tag, function: function, file: file, line: line)
        }

        public static func error(
            _ any: String,
            _ tag: String,
            function: String = #function,
            file: String = #file,
            line: Int = #line
        ) {
            guard canLog(any, tag) else {
                return
            }
            log(prefix: "🟥", log: "\(any)".replace("\\", with: ""), tag: tag, function: function, file: file, line: line)
        }

        public static func debug(
            _ string: String,
            _ tag: String,
            function: String = #function,
            file: String = #file,
            line: Int = #line
        ) {
            Self.debug(.log(string), tag, function: function, file: file, line: line)
        }

        public static func debug(
            _ any: LogTemplate,
            _ tag: String,
            function: String = #function,
            file: String = #file,
            line: Int = #line
        ) {
            guard canLog(any, tag) else {
                return
            }
            log(prefix: "🟢", log: any.log, tag: tag, function: function, file: file, line: line)
        }
    }


}

private extension Common.LogsManager {
    static func log(
        prefix: String,
        log: String,
        tag: String,
        function: String = #function,
        file: String = #file,
        line: Int = #line

    ) {
        counterTotal += 1
        let sender = Common.Utils.senderCodeId(function, file: file, line: line)
        let log = "\n\n\(prefix) Log_\(counterTotal) \(Date.utcNow)) @ \(sender)|\(tag)\n\(log)".replace(" +0000", with: "").replace("Optional", with: "")
        // swiftlint:disable logs_rule_1
        print(log)
        Persistence.appendToFileEnd(log)
        // swiftlint:enable logs_rule_1
    }

    static func canLog(_ any: Any?, _ tag: String) -> Bool {
        //guard FeatureFlag.logsEnabled.isEnabled else {
        //    return false
        //}
        guard any != nil else {
            return false
        }
        return true
    }
}

// MARK: - Logger (Private)

public extension Common.LogsManager {
    enum Persistence {
        /**
         In Swift, it's generally not recommended to perform file I/O operations on the main thread, especially if those operations are time-consuming
         or can potentially block the UI. File I/O can be slow, and performing it on the main thread can result in a poor user experience, including unresponsive user interfaces.
         */
        @PWThreadSafe fileprivate static var dispatchQueue = DispatchQueue(label: "\(logFilePrefix)", qos: .background)
        @PWThreadSafe fileprivate static var fileManager: FileManager = Common.FileManager.default
        @PWThreadSafe fileprivate static var _logFile: URL?
        fileprivate static var logFilePrefix = "\(Common.self).\(Common_Logs.self)"
        fileprivate static var logsFolder: URL? = fileManager.urls(
            for: Common.FileManager.defaultSearchPath,
            in: .userDomainMask
        ).first

        fileprivate static var logFile: URL? {
            if let _logFile {
                return _logFile
            }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let fileDynamicSuffic = dateFormatter.string(from: Date.utcNow)
            let dynamicFileName = "\(logFilePrefix)@\(fileDynamicSuffic).log"
            let fileName = dynamicFileName
            guard let logsFolder else {
                return nil
            }
            _logFile = logsFolder.appendingPathComponent(fileName)
            return _logFile
        }

        public static func deleteLastLog() {
            reset()
        }

        public static func reset() {
            Self.dispatchQueue.async {
                guard let logsFolder else {
                    return
                }
                if let contents = try? fileManager.contentsOfDirectory(
                    at: logsFolder,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]
                ) {
                    for file in contents {
                        if "\(file)".contains(logFilePrefix), fileManager.isDeletableFile(atPath: file.path) {
                            try? fileManager.removeItem(atPath: file.path)
                        }
                    }
                }
            }
        }

        public static var allLogs: [(logId: String, logContent: String)] {
            guard let logsFolder else {
                return []
            }
            var acc: [(logId: String, logContent: String)] = []
            if let contents = try? fileManager.contentsOfDirectory(
                at: logsFolder,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) {
                for file in contents {
                    if "\(file)".contains(logFilePrefix), fileManager.isDeletableFile(atPath: file.path) {
                        if let content = try? String(contentsOf: file, encoding: String.Encoding.utf8) {
                            if var id = "\(file.path)".split(by: "/").last {
                                id = id.replace(".log", with: "").replace("@", with: "").replace("_", with: " ")
                                id = id.replace(logFilePrefix, with: "")
                                acc.append((logId: id, logContent: content))
                            }
                        }
                    }
                }
            }
            return acc
        }

        public static var lastLog: String? {
            guard let logFile else {
                return nil
            }
            return try? String(contentsOf: logFile, encoding: String.Encoding.utf8)
        }

        public static func appendToFileStart(_ log: String) {
            Self.dispatchQueue.async {
                guard let logFile else {
                    return
                }
                let currentFile = lastLog ?? ""
                guard let data = "\(log)\n\(currentFile)".data(using: String.Encoding.utf8) else {
                    return
                }
                if fileManager.fileExists(atPath: logFile.path) {
                    if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                        defer {
                            fileHandle.closeFile()
                        }
                        fileHandle.write(data)
                    }
                } else {
                    try? data.write(to: logFile, options: .atomicWrite)
                }
            }
        }

        public static func appendToFileEnd(_ log: String) {
            Self.dispatchQueue.async {
                guard let logFile else {
                    return
                }
                guard let data = "\(log)\n".data(using: String.Encoding.utf8) else {
                    return
                }
                if fileManager.fileExists(atPath: logFile.path) {
                    if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                        defer {
                            fileHandle.closeFile()
                        }
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                    }
                } else {
                    try? data.write(to: logFile, options: .atomicWrite)
                }
            }
        }
    }
}

// swiftlint:enable logs_rule_1
