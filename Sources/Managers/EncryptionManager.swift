//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import CommonCrypto
import CryptoKit

public extension StringProtocol {
    var data: Data { .init(utf8) }
    var bytes: [UInt8] { .init(utf8) }
}

public extension Data {
    var decrypted: Data? {
        Common.EncryptionManager.decrypt(data: self, method: .default)
    }

    var encrypted: Data? {
        Common.EncryptionManager.encrypt(data: self, method: .default)
    }
}

public extension String {
    var decrypted: String? {
        Common.EncryptionManager.decrypt(base64String: self, method: .default)?.1 ?? ""
    }

    var encrypted: String? {
        Common.EncryptionManager.encrypt(string: self, method: .default)?.1 ?? ""
    }
}

public extension Common {

    enum EncryptionManager {
        public enum Method {
            case none
            // AES-GCM: offers both encryption and built-in integrity/authentication,
            // making it a more secure and efficient choice for modern applications.
            // GCM is generally preferred for its performance benefits and stronger security model.
            case aesGCM

            static var `default`: Self {
                .aesGCM
            }
        }

        public static func decrypt(string: String, method: EncryptionManager.Method, key: SymmetricKey? = nil) -> Data? {
            guard let data = string.data(using: .utf8) else {
                return nil
            }
            return decrypt(data: data, method: method, key: key)
        }

        public static func decrypt(data: Data?, method: EncryptionManager.Method, key: SymmetricKey? = nil) -> Data? {
            guard let data else {
                return nil
            }
            let key = key ?? symmetricKey
            return switch method {
            case .none: data
            case .aesGCM: decryptAESGCM(data: data, key: key)
            }
        }

        public static func decrypt(base64String: String, method: EncryptionManager.Method, key: SymmetricKey? = nil) -> (Data, String)? {
            guard let data = Data(base64Encoded: base64String) else {
                return nil
            }
            guard let result = decrypt(data: data, method: method, key: key) else {
                return nil
            }
            guard let string = String(data: result, encoding: .utf8) else {
                return nil
            }
            return (result, string)
        }
        
        public static func encrypt(data: Data?, method: EncryptionManager.Method, key: SymmetricKey? = nil) -> Data? {
            guard let data else {
                return nil
            }
            let key = key ?? symmetricKey
            return switch method {
            case .none: data
            case .aesGCM: encryptAESGCM(data: data, key: key)
            }
        }

        public static func encrypt(string: String, method: EncryptionManager.Method, key: SymmetricKey? = nil) -> (Data, String)? {
            guard let data = string.data(using: .utf8) else {
                return nil
            }
            guard let result = encrypt(data: data, method: method, key: key) else {
                return nil
            }
            return (result, result.base64EncodedString())
        }
        
        public static func encrypt(codable: Codable, method: EncryptionManager.Method, key: SymmetricKey? = nil) -> Data? {
            let data = try? JSONEncoder().encode(codable)
            return encrypt(data: data, method: method, key: key)
        }
    }
}

//
// MARK: - Implementation (AES-CBC)
//

extension Common.EncryptionManager {
    static var symmetricKey: SymmetricKey {
        Common.SymmetricKeyManager.symmetricKey
    }

    static func encryptAESGCM(data: Data, key: SymmetricKey?) -> Data? {
        EncryptionManagerWithFixKey.encryptAESGCM(data: data, key: key)
    }

    static func decryptAESGCM(data: Data, key: SymmetricKey?) -> Data? {
        EncryptionManagerWithFixKey.decryptAESGCM(data: data, key: key)
    }
}


// MARK: - Small helper to encode unknown Codable cleanly

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ wrapped: Encodable) { self._encode = wrapped.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}

//
// MARK: - EncryptionManagerWithFixKey
//
private enum EncryptionManagerWithFixKey {
    public enum Method {
        case none
        // AES-GCM: offers both encryption and built-in integrity/authentication,
        // making it a more secure and efficient choice for modern applications.
        // GCM is generally preferred for its performance benefits and stronger security model.
        case aesGCM

        static var `default`: Self {
            .aesGCM
        }
    }

    public static func decrypt(
        data: Data?,
        method: Self.Method,
        key: SymmetricKey? = nil
    ) -> Data? {
        guard let data else {
            return nil
        }
        let key = key ?? symmetricKey
        return switch method {
        case .none: data
        case .aesGCM: decryptAESGCM(data: data, key: key)
        }
    }

    public static func encrypt(
        data: Data?,
        method: Self.Method,
        key: SymmetricKey? = nil
    ) -> Data? {
        guard let data else {
            return nil
        }
        let key = key ?? symmetricKey
        return switch method {
        case .none: data
        case .aesGCM: EncryptionManagerWithFixKey.encryptAESGCM(data: data, key: key)
        }
    }
}

//
// MARK: - Implementation (AES-CBC)
//
extension EncryptionManagerWithFixKey {
    static var symmetricKey: SymmetricKey {
        SingleSymmetricKeyManager.symmetricKey
    }

    static func encryptAESGCM(
        data: Data,
        key: SymmetricKey?
    ) -> Data? {
        let nonce = AES.GCM.Nonce() // Generates a 12-byte random nonce
        let sealedBox = try? AES.GCM.seal(data, using: key ?? Self.symmetricKey, nonce: nonce)
        return sealedBox?.combined
    }

    static func decryptAESGCM(
        data: Data,
        key: SymmetricKey?
    ) -> Data? {
        guard let sealedBox = try? AES.GCM.SealedBox(combined: data)
        else {
            return nil
        }

        return try? AES.GCM.open(sealedBox, using: key ?? Self.symmetricKey)
    }
}


public enum SingleSymmetricKeyManager {}

public extension SingleSymmetricKeyManager {
    // Get SymmetricKey, generate if not exists
    static var symmetricKey: SymmetricKey {
        if Common.Utils.onUnitTests {
            // Return a static hardcoded key for unit tests
            let hardcodedKeyData = Data([
                0x00,
                0x01,
                0x02,
                0x03,
                0x04,
                0x05,
                0x06,
                0x07,
                0x08,
                0x09,
                0x0A,
                0x0B,
                0x0C,
                0x0D,
                0x0E,
                0x0F
            ])
            return SymmetricKey(data: hardcodedKeyData)
        }
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
                Common.LogsManager.error("Failed to save symmetric key to Keychain", "\(Self.self)")
                fatalError("Failed to save symmetric key to Keychain")
            }
        }
    }
}



private extension SingleSymmetricKeyManager {
    static let keychainKey = "\(Self.self).symmetricKey"

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
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
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
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess {
            return result as? Data
        }
        return nil
    }
}
