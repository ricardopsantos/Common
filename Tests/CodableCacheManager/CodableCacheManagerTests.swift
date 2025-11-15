//
//  Created by Ricardo Santos on 12/08/2024.
//

import XCTest
import Foundation
import Combine
@testable import Common

//
// MARK: - CodableCacheManagerBaseTests
//

class CodableCacheManagerBaseTests: XCTestCase {

    func codableCacheManager() -> CodableCacheManagerProtocol {
        // Override in subclass
        Common.CacheManagerForCodableUserDefaultsRepository.shared
    }

    private var sampleWebAPIUseCase: SampleWebAPIUseCase { SampleWebAPIUseCase() }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        TestsGlobal.loadedAny = nil
        TestsGlobal.cancelBag.cancel()
        syncClearAll()
    }

    // MARK: - Async CRUD

    func test_keys() {
        let key1 = #function
        let params1 = [#function, #file]
        let key2 = #function
        let params2 = [#function, #file]
        let composedKey1 = Commom_ExpiringKeyValueEntity.composedKey(key1, params1)
        let composedKey2 = Commom_ExpiringKeyValueEntity.composedKey(key2, params2)
        XCTAssertEqual(composedKey1, composedKey2)
    }
    
    func test_aSyncStoreAndRetrieve() async {
        let model = User.random
        let key = String.random(10)
        let params = [model.age.description, model.name]

        await codableCacheManager().aSyncStore(model, key: key, params: params, timeToLiveMinutes: nil)

        if let cached = await codableCacheManager().aSyncRetrieve(User.self, key: key, params: params) {
            XCTAssertEqual(cached.model, model)
        } else {
            XCTFail("Expected cached model to exist")
        }

        await codableCacheManager().aSyncClearAll()

        let cachedAfterClear = await codableCacheManager().aSyncRetrieve(User.self, key: key, params: params)
        XCTAssertNil(cachedAfterClear, "Expected cache to be empty after clearAll")
    }

    // MARK: - Sync CRUD

    func test_syncStoreAndRetrieve() {
        
        let model = User.random
        let key = String.random(10)
        let params = [model.age.description, model.name]

        codableCacheManager().syncStore(model, key: key, params: params, timeToLiveMinutes: nil)

        if let cached = codableCacheManager().syncRetrieve(User.self, key: key, params: params) {
            XCTAssertEqual(cached.model, model)
        } else {
            XCTFail("Expected cached model to exist")
        }

        codableCacheManager().syncClearAll()

        let cachedAfterClear = codableCacheManager().syncRetrieve(User.self, key: key, params: params)
        XCTAssertNil(cachedAfterClear, "Expected cache to be empty after clearAll")
    }

    // MARK: - Cache Policy Tests

    func test_webapi_cachePolicy_ignoringCache() async {

        var counter = 0

        sampleWebAPIUseCase.fetchEmployees(cachePolicy: .ignoringCache)
            .sinkToReceiveValue { some in
                if case .success = some { counter += 1 }
            }
            .store(in: TestsGlobal.cancelBag)

        let ok = await eventually(timeoutSeconds: Double(TestsGlobal.timeout)) { counter == 1 }
        XCTAssertTrue(ok, "Expected exactly one success emission")
    }

    func test_webapi_cachePolicy_cacheElseLoad() async {

        var counter = 0

        sampleWebAPIUseCase.fetchEmployees(cachePolicy: .cacheElseLoad)
            .sinkToReceiveValue { some in
                if case .success = some { counter += 1 }
            }
            .store(in: TestsGlobal.cancelBag)

        let ok = await eventually(timeoutSeconds: Double(TestsGlobal.timeout)) { counter == 1 }
        XCTAssertTrue(ok, "Expected exactly one success emission")
    }

    func test_webapi_cachePolicy_cacheDontLoad() async {

        var counter = 0

        sampleWebAPIUseCase.fetchEmployees(cachePolicy: .cacheDontLoad)
            .sinkToReceiveValue { some in
                if case .success = some { counter += 1 }
            }
            .store(in: TestsGlobal.cancelBag)

        let ok = await eventually(timeoutSeconds: Double(TestsGlobal.timeout)) { counter == 0 }
        XCTAssertTrue(ok, "Expected zero emissions when cacheDontLoad and no cache present")
    }

    func test_webapi_cachePolicy_cacheAndLoad_once() async {

        var counter = 0

        sampleWebAPIUseCase.fetchEmployees(cachePolicy: .cacheAndLoad)
            .sinkToReceiveValue { some in
                if case .success = some { counter += 1 }
            }
            .store(in: TestsGlobal.cancelBag)

        let ok = await eventually(timeoutSeconds: Double(TestsGlobal.timeout)) { counter == 1 }
        XCTAssertTrue(ok, "Expected one emission (cache or network)")
    }

    func test_webapi_cachePolicy_cacheAndLoad_twice() async {

        var counter = 0

        sampleWebAPIUseCase.fetchEmployees(cachePolicy: .ignoringCache)
            .sinkToReceiveValue { some in
                switch some {
                case .success:
                    self.sampleWebAPIUseCase.fetchEmployees(cachePolicy: .cacheAndLoad)
                        .sinkToReceiveValue { result in
                            if case .success = result {
                                counter += 1
                            } else {
                                XCTFail("Expected success")
                            }
                        }
                        .store(in: TestsGlobal.cancelBag)
                case .failure:
                    XCTFail("Expected success")
                }
            }
            .store(in: TestsGlobal.cancelBag)

        let ok = await eventually(timeoutSeconds: Double(TestsGlobal.timeout)) { counter == 2 }
        XCTAssertTrue(ok, "Expected two total emissions across both requests")
    }

    func test_fetchingFrom_10000Records() {

        syncClearAll()
        syncStore(count: 10_000)

        // Time: ~0.004s
        measure {
            syncFetchFirst()
        }
    }
}

//
// MARK: - Helpers
//

private extension CodableCacheManagerBaseTests {
    
    struct User: Codable, Equatable {
        let name: String
        let age: Int
        let height: Double

        static var random: Self {
            let randomName = UUID().uuidString
            let randomAge = Int.random(in: 18...40)
            let randomHeight = Double.random(in: 150...200)
            return .init(name: randomName, age: randomAge, height: randomHeight)
        }
    }
    
    func syncStore(count: Int) {
        for i in 0...count {
            codableCacheManager().syncStore(
                User.random,
                key: "cachedKey_\(i)",
                params: [],
                timeToLiveMinutes: nil
            )
        }
    }

    func syncFetchFirst() {
        let cached = codableCacheManager().syncRetrieve(User.self, key: "cachedKey_0", params: [])
        XCTAssertNotNil(cached, "Expected to find cached record at index 0")
    }

    func syncClearAll() {
        codableCacheManager().syncClearAll()
    }
}

//
// MARK: - Specific Implementations
//

final class CodableCacheManagerUserDefaultsTests: CodableCacheManagerBaseTests {
    override func codableCacheManager() -> CodableCacheManagerProtocol {
        Common.CacheManagerForCodableUserDefaultsRepository.shared
    }
}

final class CodableCacheManagerCoreDataTests: CodableCacheManagerBaseTests {
    override func codableCacheManager() -> CodableCacheManagerProtocol {
        Common.CacheManagerForCodableCoreDataRepository.shared
    }
}
