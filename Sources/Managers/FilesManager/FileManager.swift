//
//  File.swift
//  Common
//
//  Created by Ricardo Santos on 20/09/2024.
//

import Foundation

public extension Common {
    enum FileManager {
        public static var `default` = Foundation.FileManager.default
        public static var defaultSearchPath: Foundation.FileManager.SearchPathDirectory { .documentDirectory }
        public static var defaultFolder: String {
            let fileManager = FileManager.default
            let paths = NSSearchPathForDirectoriesInDomains(defaultSearchPath, .userDomainMask, true)
            guard let documentsDirectory = paths.first else {
                // Fallback cache directory
                return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first ?? ""
            }

            if !fileManager.fileExists(atPath: documentsDirectory) {
                // Fallback cache directory
                return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first ?? ""
            }
            return documentsDirectory
        }
        
        static func reset() {
            let fileManager = FileManager.default
            var folderURLs: [URL] = []
            folderURLs.append(contentsOf: fileManager.urls(for: .documentDirectory, in: .userDomainMask))
            folderURLs.append(contentsOf: fileManager.urls(for: .cachesDirectory, in: .userDomainMask))

            if let directory = folderURLs.first {
                do {
                    let fileURLs = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
                    for fileURL in fileURLs {
                        try fileManager.removeItem(at: fileURL)
                    }
                } catch {
                    Common_Logs.error(error)
                }
            }
        }
    }
}
