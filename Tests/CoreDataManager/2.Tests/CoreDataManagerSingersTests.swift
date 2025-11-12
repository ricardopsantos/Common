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
    func saveRandomCDataSinger(songs: Int = 0) -> CDataSinger {
        let singer = randomCDataSinger(songs: songs)
        bd.save()
        return singer
    }

    // MARK: - Tests
    @Test("Cascade delete removes songs")
    func cascadeDelete() async throws {

        bd.deleteAllSingers()
        saveRandomCDataSinger(songs: 1)

        #expect(bd.allSingers().count == 1)
        #expect(bd.allSongs().count == 1)

        bd.deleteAllSingers()

        #expect(bd.allSongs().isEmpty)
        #expect(bd.allSingers().isEmpty)
    }

    @Test("Save singer with one song")
    func saveSingerWithOneSong() async throws {

        bd.deleteAllSingers()
        saveRandomCDataSinger(songs: 1)

        #expect(bd.allSingers().count == 1)
        #expect(bd.allSongs().count == 1)
    }

    @Test("Deleting one singer doesn't affect others")
    func deleteSpecificSinger() async throws {

        bd.deleteAllSingers()
        let singer1 = saveRandomCDataSinger(songs: 1)
        let singer2 = saveRandomCDataSinger(songs: 2)

        bd.deleteSinger(singer: singer1)

        #expect(bd.allSingers().count == 1)
        #expect(bd.allSongs().count == 2)
        #expect(bd.allSingers().first == singer2)
    }

    @Test("Map singer to model maintains song relation")
    func singerMapToModel() async throws {

        bd.deleteAllSingers()
        let singer = saveRandomCDataSinger(songs: 1)
        let model = singer.mapToModel
        let cascadeSongsCount = model.cascadeSongs?.count ?? 0

        #expect(singer.songs?.count == 1)
        #expect(singer.songs?.count ?? 0 == cascadeSongsCount)
        #expect(bd.allSongs().count == 1)
    }

    @Test("Map song to model with and without cascade singer")
    func songMapToModel() async throws {

        bd.deleteAllSingers()
        let singer = saveRandomCDataSinger(songs: 1)
        let songModelWith = bd.allSongs().first?.mapToModel(cascade: true)
        let songModelWithout = bd.allSongs().first?.mapToModel(cascade: false)

        #expect(singer.songs?.count == 1)
        #expect(songModelWith?.cascadeSinger?.name == singer.name)
        #expect(songModelWithout?.cascadeSinger == nil)
    }

    @Test("Save singer with 3 songs")
    func saveSingerWithThreeSongs() async throws {

        bd.deleteAllSingers()
        saveRandomCDataSinger(songs: 3)

        #expect(bd.allSingers().count == 1)
        #expect(bd.allSongs().count == 3)
    }

    @Test("Deleting all songs keeps singer intact")
    func deleteSong() async throws {

        bd.deleteAllSingers()
        saveRandomCDataSinger(songs: 1)
        bd.deleteAllSongs()

        #expect(bd.allSingers().count == 1)
        #expect(bd.allSongs().isEmpty)
    }

    @Test("Emit event on database insert")
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

        Common_Utils.delay { bd.save() }

        // Use old form for better iOS compatibility
        try await Task.sleep(nanoseconds: UInt64(TestsGlobal.timeout * 1_000_000_000))

        #expect(didInserted.value)
        #expect(didInserted.id == toStore.id)
        #expect(didChanged == 1)
        #expect(didFinished == 1)
    }

}

import XCTest

class CommonCoreDataSongsPerformanceTests: XCTestCase {
    var bd: DatabaseRepository { .shared }

    
    // Test to check performance when saving a large number of songs
    func testPerformanceSaveMany() {
        bd.deleteAllSingers() // Clear all existing singers

        // Time: 0.010 sec
        measure {
            saveRandomCDataSinger(songs: 1000)
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
    func saveRandomCDataSinger(songs: Int = 0) -> CDataSinger {
        let singer = randomCDataSinger(songs: songs)
        bd.save()
        return singer
    }
}
