//
//  SymmetricKeyManager.swift
//  Common
//
//  Created by Ricardo Santos on 22/02/2025.
//

import CryptoKit
import Foundation

public extension Common {
    enum SymmetricKeyManager {}
}

//

// MARK: - Public

//

public extension Common.SymmetricKeyManager {
    static var staticSymmetricKey: SymmetricKey {
        SymmetricKey(data: [38, 99, 51, 110, 99, 104, 35, 73, 120, 88, 36, 104, 57, 117, 35, 86].reversed())
    }

    // Get SymmetricKey, generate if not exists
    static var symmetricKey: SymmetricKey {
        if let keyData = loadKeyFromKeychain() {
            // Convert existing Data to SymmetricKey
            return dataToSymmetricKey(keyData)
        } else {
            // Generate a new key and store it
            let newKey = generateKey()
            let keyData = symmetricKeyToData(newKey)
            if saveKeyToKeychain(keyData) {
                return newKey
            } else {
                Common_Logs.error("Failed to save symmetric key to Keychain", "\(Self.self)")
                return staticSymmetricKey
            }
        }
    }
}

//

// MARK: - Private

//
private extension Common.SymmetricKeyManager {
    static let keychainKey =
        "\(String(describing: Bundle.main.bundleIdentifier))_\(Common.SymmetricKeyManager.self).symmetricKey"

    // Generate a new SymmetricKey
    static func generateKey() -> SymmetricKey {
        SymmetricKey(size: .bits256) // 256-bit symmetric key
    }

    // Convert SymmetricKey to Data for storage
    static func symmetricKeyToData(_ key: SymmetricKey) -> Data {
        key.withUnsafeBytes { Data(Array($0)) }
    }

    // Convert Data back to SymmetricKey
    static func dataToSymmetricKey(_ data: Data) -> SymmetricKey {
        SymmetricKey(data: data)
    }

    // Save Data to Keychain
    static func saveKeyToKeychain(_ data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
        ]

        // Delete any existing key before adding
        SecItemDelete(query as CFDictionary)

        // Add new key
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // Load Data from Keychain
    static func loadKeyFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess {
            return result as? Data
        }
        return nil
    }
}
