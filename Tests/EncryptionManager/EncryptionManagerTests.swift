//
//  Created by Ricardo Santos on 12/08/2024.
//

@testable import Common
import Foundation
import Testing

@Suite
struct EncryptionManagerTests {
    @Test
    func encryptedToDecryptedString() {
        let string = String.random(1000)
        let encrypted = string.encrypted
        let decrypted = encrypted?.decrypted
        #expect(decrypted == string)
    }

    @Test
    func encryptedToDecryptedStringTuple() {
        let string = String.random(1000)
        let encTuple = Common.EncryptionManager.encrypt(string: string, method: .aesGCM)
        let cipherBase64 = encTuple!.1
        let decTuple = Common.EncryptionManager.decrypt(base64String: cipherBase64, method: .aesGCM)
        let plain = decTuple!.1
        #expect(plain == string)
    }

    @Test
    func encryptedToDecryptedData() throws {
        let entity: CoreDataSampleUsageNamespace.CRUDEntity = .random
        let data = try JSONEncoder().encode(entity)
        let encrypted = Common.EncryptionManager.encrypt(data: data, method: .aesGCM)
        let decrypted = Common.EncryptionManager.decrypt(data: encrypted, method: .aesGCM)
        #expect(decrypted == data)
    }
}
