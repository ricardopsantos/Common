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
        /*
           guard let data = data(using: .utf8) else {
               return nil
           }
           guard let decryptedData = Common.EncryptionManager.decrypt(data: data, method: .default) else {
               return nil
           }
            return String(data: decryptedData, encoding: .utf8)
         */
    }

    var encrypted: String? {
        Common.EncryptionManager.encrypt(string: self, method: .default)?.1 ?? ""
        /*
        guard let data = data(using: .utf8) else {
            return nil
        }
        guard let encryptedData = Common.EncryptionManager.encrypt(data: data, method: .default) else {
            return nil
        }
        return encryptedData.base64EncodedString()
         */
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
        guard let key else {
            return nil
        }
        let nonce = AES.GCM.Nonce() // Generates a 12-byte random nonce
        let sealedBox = try? AES.GCM.seal(data, using: key, nonce: nonce)
        return sealedBox?.combined
    }

    static func decryptAESGCM(data: Data, key: SymmetricKey?) -> Data? {
        guard let key,
              let sealedBox = try? AES.GCM.SealedBox(combined: data)
        else {
            return nil
        }

        return try? AES.GCM.open(sealedBox, using: key)
    }
}
