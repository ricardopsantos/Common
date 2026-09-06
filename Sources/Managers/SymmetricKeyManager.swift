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
    /// The device key, loaded from the Keychain or generated on first use.
    ///
    /// `nil` means the Keychain was unavailable (locked device, entitlement
    /// problem). Callers must fail the operation: encrypting under a fallback
    /// key would either expose data under a key shipped in the binary, or make
    /// previously written data undecryptable.
    static var symmetricKey: SymmetricKey? {
        // Tests run without Keychain entitlements on some hosts, so give them a
        // deterministic key. This is the ONLY fallback: production must never
        // silently encrypt under a key that ships in the binary.
        if Common.Utils.onUnitTests {
            return unitTestKey
        }

        // Generation is read-modify-write against the Keychain: without this
        // lock two threads racing on first use both generate and both save,
        // and the loser hands back a key that is no longer stored.
        keyLock.lock()
        defer { keyLock.unlock() }

        if let keyData = loadKeyFromKeychain() {
            return dataToSymmetricKey(keyData)
        }

        let newKey = generateKey()
        guard saveKeyToKeychain(symmetricKeyToData(newKey)) else {
            Common_Logs.error("Failed to save symmetric key to Keychain", "\(Self.self)")
            return nil
        }
        return newKey
    }
}

//

// MARK: - Private

//
private extension Common.SymmetricKeyManager {
    static let keyLock = NSLock()

    /// 256-bit, matching `generateKey()` so tests exercise the production key size.
    static var unitTestKey: SymmetricKey {
        SymmetricKey(data: Data((0 ..< 32).map { UInt8($0) }))
    }

    /// Frozen on purpose — the `Optional(...)` spelling is part of the stored
    /// account name on existing installs. Changing it orphans their key and
    /// makes everything written under it undecryptable.
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
        // A generic password is identified by class + account only. Passing the
        // value and accessibility here too can stop the delete from matching,
        // which then makes SecItemAdd fail with errSecDuplicateItem.
        let identity: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
        ]

        SecItemDelete(identity as CFDictionary)

        var insert = identity
        insert[kSecValueData as String] = data
        insert[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked

        return SecItemAdd(insert as CFDictionary, nil) == errSecSuccess
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
