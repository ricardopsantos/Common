//
//  Created by Ricardo Santos on 12/08/2024.
//

import Foundation
import Combine
import Testing
@testable import Common

@Suite(.serialized)
struct CoreDataManagerCRUDTests {

    // MARK: - Config / State

    private func enabled() -> Bool { true }

    var bd: DatabaseRepository { .shared }

    // MARK: - CRUD

    @Test
    func syncCRUD() {
        guard enabled() else { #expect(true); return }

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
        if let stored {
            bd.syncDelete(stored)
            let some = bd.syncRetrieve(key: toStore.id)
            #expect(some == nil)
            let count1 = bd.syncRecordCount()
            let count2 = bd.syncAllIds().count
            #expect(count1 == 0)
            #expect(count1 == count2)
        } else {
            #expect(Bool(false))
        }
    }

    @Test
    func syncDelete() {
        guard enabled() else { #expect(true); return }

        bd.syncStore(.random)
        bd.syncClearAll()
        let stored = bd.syncRecordCount()
        #expect(stored == 0)
    }

    // MARK: - Others



    @Test
    func syncRecordCount() async {
        guard enabled() else { #expect(true); return }

        bd.syncClearAll()
        // save sync
        bd.syncStore(.random)
        // get async
        let stored = bd.syncRecordCount()
        #expect(stored == 1)
    }

    @Test
    func emitEventOnDataBaseInsert_test1() async {
        guard enabled() else { #expect(true); return }

        var didInsertedContent: (value: Bool, id: String) = (false, "")
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
                    case .databaseDidUpdatedContentOn: break
                    case .databaseDidDeletedContentOn: break
                    case .databaseDidFinishChangeContentItemsOn:
                        didFinishChangeContent += 1
                    case .databaseReloaded: break
                    }
                }
            }
            .store(in: TestsGlobal.cancelBag)

        Common_Utils.delay { [weak bd] in
            bd?.syncStore(toStore)
        }

        let okFinish = await eventually { didFinishChangeContent == 1 }
        let okInserted = await eventually { didInsertedContent.value }
        let okId = await eventually { didInsertedContent.id == toStore.id }
        let okChanged = await eventually { didChangedContent == 1 }

        #expect(okFinish, "Expected finish-change event once")
        #expect(okInserted, "Expected insert event")
        #expect(okId, "Expected inserted id to match")
        #expect(okChanged, "Expected one change-item event")
    }

    @Test
    func emitEventOnDataBaseInsert_test2() async {
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
                    case .databaseDidUpdatedContentOn: break
                    case .databaseDidDeletedContentOn: break
                    case .databaseDidFinishChangeContentItemsOn:
                        didFinishChangeContent += 1
                    case .databaseReloaded: break
                    }
                }
            }
            .store(in: TestsGlobal.cancelBag)

        Common_Utils.delay { [weak bd] in
            for _ in 1...numberOfInserts {
                bd?.syncStore(.random)
            }
        }

        let okInserted = await eventually { didInsertedContent == numberOfInserts }
        let okChanged = await eventually { didChangedContent == numberOfInserts }
        let okFinished = await eventually { didFinishChangeContent == numberOfInserts }

        #expect(okInserted, "Expected \(numberOfInserts) insert events")
        #expect(okChanged, "Expected \(numberOfInserts) change-item events")
        #expect(okFinished, "Expected \(numberOfInserts) finish-change events")
    }
    
    // MARK: - Async
    
    @Test
    func aSyncCRUD() async {
        guard enabled() else { #expect(true); return }

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
        if let stored {
            await bd.aSyncDelete(stored)
            let some = await bd.aSyncRetrieve(key: toStore.id)
            #expect(some == nil)
            let c1 = await bd.aSyncRecordCount()
            let c2 = await bd.aSyncAllIds().count
            #expect(c1 == 0)
            #expect(c1 == c2)
        } else {
            #expect(Bool(false))
        }
    }

    @Test
    func aSyncRecordCount() async {
        guard enabled() else { #expect(true); return }

        await bd.aSyncClearAll()
        // save async
        await bd.aSyncStore(.random)
        // get async
        let stored = await bd.aSyncRecordCount()
        #expect(stored == 1)
    }
}

