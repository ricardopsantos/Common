//
//  Created by Ricardo Santos on 12/08/2024.
//

import XCTest
import Foundation
import Combine
//
import Nimble
//
@testable import Common
class EncryptionManager_Tests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        TestsGlobal.loadedAny = nil
        TestsGlobal.cancelBag.cancel()
    }

    func test_string_1() {
        let string = String.randomWithSpaces(1000)
        let encrypted = string.encrypted
        let decrypted = encrypted?.decrypted
        XCTAssert(decrypted == string)
    }
    
    func test_string_2() {
        let string = String.randomWithSpaces(1000)
        let encrypted = Common.EncryptionManager.encrypt(string: string, method: .aesGCM)?.1 ?? ""
        let decrypted = Common.EncryptionManager.decrypt(base64String: encrypted, method: .aesGCM)?.1 ?? ""
        XCTAssert(decrypted == string)
    }

    func test_data() {
        let entity: CoreDataSampleUsageNamespace.CRUDEntity = .random
        let data = try? JSONEncoder().encode(entity)
        let encrypted = Common.EncryptionManager.encrypt(data: data, method: .aesGCM)
        let decrypted = Common.EncryptionManager.decrypt(data: encrypted, method: .aesGCM)
        XCTAssert(decrypted == data)
    }

    func test_stringExtension() {
        let string = String.randomWithSpaces(1000)
        let encrypted = string.encrypted
        let decrypted = encrypted?.decrypted
        XCTAssert(string == decrypted)
    }

    func test_dataExtension() {
        let entity: CoreDataSampleUsageNamespace.CRUDEntity = .random
        if let data = try? JSONEncoder().encode(entity) {
            let encrypted = data.encrypted
            let decrypted = encrypted?.decrypted
            XCTAssert(data == decrypted)
        } else {
            XCTAssert(false)
        }
    }
}
