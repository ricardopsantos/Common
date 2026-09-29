//
//  Created by Ricardo Santos on 12/08/2024.
//

import Combine
import Foundation
import Testing
//
@testable import Common
/// Serialised: every test mutates the same shared store.
@Suite(.serialized)
struct CoreDataManager_CRUDTests {
    func enabled() -> Bool {
        true
    }

    var bd: DatabaseRepository = {
        .shared
    }()

    init() {
        TestsGlobal.loadedAny = nil
        TestsGlobal.cancelBag.cancel()
    }
}

//
// MARK: - CRUD
//
extension CoreDataManager_CRUDTests {
    @Test
    func testA1_syncCRUD() async {
        guard enabled() else { return }

        // Records count
        bd.syncClearAll()
        #expect(bd.syncRecordCount() == 0)

        // Batch Insert
        bd.syncClearAll()
        bd.syncStoreBatch([.random, .random, .random])
        #expect(bd.syncRecordCount() == 3)
        #expect(bd.syncRecordCount() == bd.syncAllIds().count)

        // Insert
        bd.syncClearAll()
        var toStore: CoreDataSampleUsageNamespace.CRUDEntity = .random
        bd.syncStore(toStore)
        #expect(bd.syncRecordCount() == 1)
        #expect(bd.syncRecordCount() == bd.syncAllIds().count)

        // Get
        var stored = bd.syncRetrieve(key: toStore.id)
        #expect(stored == toStore)

        // Update
        toStore.name = "NewName"
        bd.syncUpdate(toStore)

        stored = bd.syncRetrieve(key: toStore.id)
        #expect(stored?.name == "NewName")

        // Delete
        if let stored = stored {
            bd.syncDelete(stored)
            let some = bd.syncRetrieve(key: toStore.id)
            #expect(some == nil)
            let count1 = bd.syncRecordCount()
            let count2 = bd.syncAllIds().count
            #expect(count1 == 0)
            #expect(count1 == count2)
        } else {
            Issue.record("unexpected path")
        }
    }

    @Test
    func testA2_aSyncCRUD() async {
        guard enabled() else { return }

        // Records count
        await bd.aSyncClearAll()
        let count1 = await bd.aSyncRecordCount()
        let count2 = await bd.aSyncAllIds().count
        #expect(count1 == 0)
        #expect(count1 == count2)

        // Batch Insert
        await bd.aSyncClearAll()
        await bd.aSyncStoreBatch([.random, .random, .random])
        let count3 = await bd.aSyncRecordCount()
        #expect(count3 == 3)

        // Insert
        bd.syncClearAll()

        // Insert
        var toStore: CoreDataSampleUsageNamespace.CRUDEntity = .random
        await bd.aSyncStore(toStore)

        // Records count
        let count4 = await bd.aSyncRecordCount()
        #expect(count4 == 1)

        // Get
        var stored = await bd.aSyncRetrieve(key: toStore.id)
        #expect(stored == toStore)

        // Update
        toStore.name = "NewName"
        await bd.aSyncUpdate(toStore)

        stored = await bd.aSyncRetrieve(key: toStore.id)
        #expect(stored?.name == "NewName")

        // Delete
        if let stored = stored {
            await bd.aSyncDelete(stored)
            let some = await bd.aSyncRetrieve(key: toStore.id)
            #expect(some == nil)
            let count1 = await bd.aSyncRecordCount()
            let count2 = await bd.aSyncAllIds().count
            #expect(count1 == 0)
            #expect(count1 == count2)
        } else {
            Issue.record("unexpected path")
        }
    }

    @Test
    func testB1_syncDelete() async {
        guard enabled() else { return }
        bd.syncStore(.random)
        bd.syncClearAll()
        let stored = bd.syncRecordCount()
        #expect(stored == 0)
    }
}

//
// MARK: - Others
//
extension CoreDataManager_CRUDTests {
    @Test
    func testC1_mergeContext1() async {
        guard enabled() else { return }
        await bd.aSyncClearAll()
        // save async
        await bd.aSyncStore(.random)
        // get sync
        let stored = await bd.aSyncRecordCount()
        #expect(stored == 1)
    }

    @Test
    func testC2_mergeContext2() async {
        guard enabled() else { return }
        bd.syncClearAll()
        // save sync
        bd.syncStore(.random)
        // get sync
        let stored = await bd.aSyncRecordCount()
        #expect(stored == 1)
    }

    @Test
    func testC3_emitEventOnDataBaseInsert_test1() async {
        guard enabled() else { return }
        var didInsertedContent = (value: false, id: "")
        var didChangedContent = 0
        var didFinishChangeContent = 0
        let toStore = CoreDataSampleUsageNamespace.CRUDEntity.random
        bd.output()
            .sink { event in
                switch event {
                case .generic(let genericEvent):
                    switch genericEvent {
                    case .databaseDidInsertedContentOn(_, id: let id):
                        didInsertedContent = (true, id ?? "")
                    case .databaseDidChangedContentItemOn:
                        didChangedContent += 1
                    case .databaseDidUpdatedContentOn: ()
                    case .databaseDidDeletedContentOn: ()
                    case .databaseDidFinishChangeContentItemsOn:
                        didFinishChangeContent += 1
                    case .databaseReloaded: ()
                    }
                }
            }.store(in: TestsGlobal.cancelBag)

        Common_Utils.delay {
            bd.syncStore(toStore)
        }

        // Verify that the event is emitted
        #expect(await eventually { didFinishChangeContent == 1 })
        #expect(await eventually { didInsertedContent.value })
        #expect(await eventually { didInsertedContent.id == toStore.id })
        #expect(await eventually { didChangedContent == 1 })
    }

    @Test
    func testC4_emitEventOnDataBaseInsert_test2() async {
        var didInsertedContent = 0
        var didChangedContent = 0
        var didFinishChangeContent = 0
        let numberOfInserts = 3
        bd.output()
            .sink { event in
                switch event {
                case .generic(let genericEvent):
                    switch genericEvent {
                    case .databaseDidInsertedContentOn:
                        didInsertedContent += 1
                    case .databaseDidChangedContentItemOn:
                        didChangedContent += 1
                    case .databaseDidUpdatedContentOn: ()
                    case .databaseDidDeletedContentOn: ()
                    case .databaseDidFinishChangeContentItemsOn:
                        didFinishChangeContent += 1
                    case .databaseReloaded: ()
                    }
                }
            }.store(in: TestsGlobal.cancelBag)

        Common_Utils.delay {
            for _ in 1...numberOfInserts {
                bd.syncStore(.random)
            }
        }

        // Verify that the event is emitted
        #expect(await eventually { didInsertedContent == didInsertedContent })
        #expect(await eventually { didChangedContent == numberOfInserts })
        #expect(await eventually { didFinishChangeContent == numberOfInserts })
    }
}
