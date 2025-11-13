//
//  Created by Ricardo Santos on 12/08/2024.
//

import Foundation
import Testing
import Combine
@testable import Common

@Suite(.serialized)
struct CoreDataManagerSingersTests {
    var bd: DatabaseRepository { .shared }

    @Test
    func saveOneSingerOneSong() {
        bd.deleteAllSingers()
        saveRandomCDataSinger(songs: 1)
        #expect(bd.allSingers().count == 1)
        #expect(bd.allSongs().count == 1)
    }

    @Test
    func saveOneSingerTreeSong() {
        bd.deleteAllSingers()
        saveRandomCDataSinger(songs: 3)
        #expect(bd.allSingers().count == 1)
        #expect(bd.allSongs().count == 3)
    }
    
    @Test
    func deleteSinger() {
        bd.deleteAllSingers()
        let singer1 = saveRandomCDataSinger(songs: 1)
        let singer2 = saveRandomCDataSinger(songs: 2)
        bd.deleteSinger(singer: singer1)
        #expect(bd.allSingers().count == 1)
        #expect(bd.allSongs().count == 2)
        #expect(bd.allSingers().first == singer2)
    }

    @Test
    func deleteAllSingers() {
        bd.deleteAllSingers()
        saveRandomCDataSinger(songs: 1)
        #expect(bd.allSingers().count == 1)
        #expect(bd.allSongs().count == 1)
        bd.deleteAllSingers()
        #expect(bd.allSongs().isEmpty)
        #expect(bd.allSingers().isEmpty)
    }
        
    @Test
    func deleteAllSongs() {
        bd.deleteAllSingers()
        saveRandomCDataSinger(songs: 1)
        bd.deleteAllSongs()
        #expect(bd.allSingers().count == 1)
        #expect(bd.allSongs().isEmpty)
    }

    
    @Test
    func mapToModel() {
        bd.deleteAllSingers()
        let singer = saveRandomCDataSinger(songs: 1)
        let model = singer.mapToModel
        let cascadeSongsCount = model.cascadeSongs?.count ?? 0
        #expect(singer.songs?.count == 1)
        #expect(singer.songs?.count ?? 0 == cascadeSongsCount)
        #expect(bd.allSongs().count == 1)
    }

    @Test
    func mapToModelCascade() {
        bd.deleteAllSingers()
        let singer = saveRandomCDataSinger(songs: 1)
        let songModelWith = bd.allSongs().first?.mapToModel(cascade: true)
        let songModelWithout = bd.allSongs().first?.mapToModel(cascade: false)
        #expect(singer.songs?.count == 1)
        #expect(songModelWith?.cascadeSinger?.name == singer.name)
        #expect(songModelWithout?.cascadeSinger == nil)
    }

    @Test
    func emitEventOnDataBaseInsert() async throws {
        var didInserted = (value: false, id: "")
        var didChanged = 0
        var didFinished = 0
        let toStore = randomCDataSinger(songs: 0)
        bd.output().sink { event in
            if case .generic(let genericEvent) = event {
                switch genericEvent {
                case .databaseDidInsertedContentOn(_, let id):
                    didInserted = (true, id ?? "")
                case .databaseDidChangedContentItemOn:
                    didChanged += 1
                case .databaseDidFinishChangeContentItemsOn:
                    didFinished += 1
                default:
                    break
                }
            }
        }.store(in: TestsGlobal.cancelBag)
        Common_Utils.delay { bd.syncSave() }

        try await Task.sleep(nanoseconds: UInt64(TestsGlobal.timeout * 1_000_000_000))
        #expect(didInserted.value)
        #expect(didInserted.id == toStore.id)
        #expect(didChanged == 1)
        #expect(didFinished == 1)
    }

}

extension CoreDataManagerSingersTests {

    @discardableResult
    func randomCDataSinger(songs: Int = 0) -> CDataSinger {
        let singer = bd.newSingerInstance(name: "Singer \(String.random(10))")
        if songs > 0 {
            let songs = (0..<songs).map {
                bd.newSongInstance(title: "Song \($0)", releaseDate: Date.now)
            }
            songs.forEach { singer.addToSongs($0) }
        }
        return singer
    }

    @discardableResult
    func saveRandomCDataSinger(songs: Int = 0) -> CDataSinger {
        let singer = randomCDataSinger(songs: songs)
        bd.syncSave()
        return singer
    }
}

//
// MARK: - CommonCoreDataSongsPerformanceTests
//

import XCTest

class CommonCoreDataSongsPerformanceTests: XCTestCase {
    var bd: DatabaseRepository { .shared }

    
    // Test to check performance when saving a large number of songs
    func testPerformanceSaveMany() {
        bd.deleteAllSingers() // Clear all existing singers

        // Time: 0.010 sec
        measure {
            syncSaveRandomCDataSinger(songs: 1000)
        }

        XCTAssert(bd.allSingers().count == 1 * 10)
        XCTAssert(bd.allSongs().count == 1000 * 10)
    }
}

extension CommonCoreDataSongsPerformanceTests {
    
    // MARK: - Helpers
    @discardableResult
    func randomCDataSinger(songs: Int = 0) -> CDataSinger {
        let singer = bd.newSingerInstance(name: "Singer \(String.random(10))")
        if songs > 0 {
            let songs = (0..<songs).map {
                bd.newSongInstance(title: "Song \($0)", releaseDate: Date.now)
            }
            songs.forEach { singer.addToSongs($0) }
        }
        return singer
    }
    
    @discardableResult
    func syncSaveRandomCDataSinger(songs: Int = 0) -> CDataSinger {
        let singer = randomCDataSinger(songs: songs)
        bd.syncSave()
        return singer
    }
}

