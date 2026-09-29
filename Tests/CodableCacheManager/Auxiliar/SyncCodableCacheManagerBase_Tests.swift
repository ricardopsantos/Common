//
//  Created by Ricardo Santos on 12/08/2024.
//

import Combine
import Foundation
import Testing
//
@testable import Common

//
// Swift Testing has no test-class inheritance, so the old
// base-class-plus-two-subclasses arrangement is expressed as one suite
// parameterised over the backends it used to be subclassed for.
//

enum CodableCacheBackend: String, CaseIterable, Sendable {
    case userDefaults
    case coreData

    var manager: CodableCacheManagerProtocol {
        switch self {
        case .userDefaults: Common.CacheManagerForCodableUserDefaultsRepository.shared
        case .coreData: Common.CacheManagerForCodableCoreDataRepository.shared
        }
    }
}

/// Serialised: the backends are shared singletons and the tests clear them.
@Suite(.serialized)
struct SyncCodableCacheManager_Tests {
    init() {
        TestsGlobal.loadedAny = nil
        TestsGlobal.cancelBag.cancel()
    }

    private var sampleWebAPIUseCase: SampleWebAPIUseCase {
        SampleWebAPIUseCase(codableCacheManager: Common.CacheManagerForCodableUserDefaultsRepository.shared)
    }

    @Test(arguments: CodableCacheBackend.allCases)
    func test1_aSyncCRUD(backend: CodableCacheBackend) async {
        let cache = backend.manager
        let model = SampleCodableStruct.random
        let key = String.random(10)
        let params = [model.age.description, model.name]

        await cache.aSyncStore(model, key: key, params: params, timeToLiveMinutes: nil)

        let cached = await cache.aSyncRetrieve(SampleCodableStruct.self, key: key, params: params)
        #expect(cached?.model == model)

        await cache.aSyncClearAll()

        let afterClear = await cache.aSyncRetrieve(SampleCodableStruct.self, key: key, params: params)
        #expect(afterClear == nil)
    }

    @Test(arguments: CodableCacheBackend.allCases)
    func test2_syncCRUD(backend: CodableCacheBackend) {
        let cache = backend.manager
        let model = SampleCodableStruct.random
        let key = String.random(10)
        let params = [model.age.description, model.name]

        cache.syncStore(model, key: key, params: params, timeToLiveMinutes: nil)

        let cached = cache.syncRetrieve(SampleCodableStruct.self, key: key, params: params)
        #expect(cached?.model == model)

        cache.syncClearAll()

        #expect(cache.syncRetrieve(SampleCodableStruct.self, key: key, params: params) == nil)
    }

    @Test(arguments: CodableCacheBackend.allCases)
    func test3_cachePolicy_ignoringCache(backend: CodableCacheBackend) async {
        var counter = 0
        backend.manager.syncClearAll()
        sampleWebAPIUseCase.fetchEmployees(cachePolicy: .ignoringCache)
            .sinkToReceiveValue { some in
                switch some {
                case .success: counter += 1
                case .failure: ()
                }
            }.store(in: TestsGlobal.cancelBag)
        #expect(await eventually { counter == 1 })
    }

    @Test(arguments: CodableCacheBackend.allCases)
    func test4_cacheElseLoad(backend: CodableCacheBackend) async {
        var counter = 0
        backend.manager.syncClearAll()
        sampleWebAPIUseCase.fetchEmployees(cachePolicy: .cacheElseLoad)
            .sinkToReceiveValue { some in
                switch some {
                case .success: counter += 1
                case .failure: ()
                }
            }.store(in: TestsGlobal.cancelBag)
        #expect(await eventually { counter == 1 })
    }

    @Test(arguments: CodableCacheBackend.allCases)
    func test5_cacheDontLoad(backend: CodableCacheBackend) async {
        var counter = 0
        backend.manager.syncClearAll()
        sampleWebAPIUseCase.fetchEmployees(cachePolicy: .cacheDontLoad)
            .sinkToReceiveValue { some in
                switch some {
                case .success: counter += 1
                case .failure: ()
                }
            }.store(in: TestsGlobal.cancelBag)
        #expect(await eventually { counter == 0 })
    }

    @Test(arguments: CodableCacheBackend.allCases)
    func test6_cacheAndLoadT1(backend: CodableCacheBackend) async {
        var counter = 0
        backend.manager.syncClearAll()
        sampleWebAPIUseCase.fetchEmployees(cachePolicy: .cacheAndLoad)
            .sinkToReceiveValue { some in
                switch some {
                case .success: counter += 1
                case .failure: ()
                }
            }.store(in: TestsGlobal.cancelBag)
        #expect(await eventually { counter == 1 })
    }

    @Test(arguments: CodableCacheBackend.allCases)
    func test7_cacheAndLoadT2(backend: CodableCacheBackend) async {
        var counter = 0
        backend.manager.syncClearAll()
        sampleWebAPIUseCase.fetchEmployees(cachePolicy: .ignoringCache)
            .sinkToReceiveValue { some in
                switch some {
                case .success:
                    sampleWebAPIUseCase.fetchEmployees(cachePolicy: .cacheAndLoad)
                        .sinkToReceiveValue { some in
                            switch some {
                            case .success: counter += 1
                            case .failure: ()
                            }
                        }.store(in: TestsGlobal.cancelBag)
                case .failure: ()
                }
            }.store(in: TestsGlobal.cancelBag)
        #expect(await eventually { counter == 2 })
    }

    @Test(arguments: CodableCacheBackend.allCases)
    func test8_fetchingRecordFrom_10000Records(backend: CodableCacheBackend) {
        let cache = backend.manager
        cache.syncClearAll()
        for i in 0 ... 10000 {
            cache.syncStore(
                SampleCodableStruct.random,
                key: "cachedKey_\(i)",
                params: [],
                timeToLiveMinutes: nil
            )
        }

        // Was an XCTest `measure` block; Swift Testing has no baseline-backed
        // equivalent, so time it and assert the lookup stays sub-second rather
        // than silently recording a number nothing checks.
        let elapsed = Common_CronometerManager.measure {
            _ = cache.syncRetrieve(SampleCodableStruct.self, key: "cachedKey_0", params: [])
        }
        #expect(cache.syncRetrieve(SampleCodableStruct.self, key: "cachedKey_0", params: []) != nil)
        #expect(elapsed < 1.0, "first-record lookup took \(elapsed)s")
    }
}
