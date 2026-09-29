//
//  Created by Ricardo Santos on 12/08/2024.
//

import Combine
import Foundation
import Testing
@testable import Common

/// Serialised: every test mutates the same shared store.
@Suite(.serialized)
struct CommonCoreData_SongsTests {
    // Enable or disable tests (for debugging or conditional execution)
    func enabled() -> Bool {
        true
    }

    // Database repository instance, shared across tests
    var bd: DatabaseRepository = {
        .shared
    }()

    // Runs before each test
    init() {
        TestsGlobal.loadedAny = nil
        TestsGlobal.cancelBag.cancel() // Clears any subscriptions in the cancel bag
    }
}

extension CommonCoreData_SongsTests {
    // Creates a random CDataSinger instance with an optional number of songs
    @discardableResult
    func randomCDataSinger(songs: Int = 0) -> CDataSinger {
        let singer = bd.newSingerInstance(name: "Singer \(String.random(10))")
        if songs > 0 {
            // Create an array of songs and add them to the singer
            let songs = (0...(songs - 1)).map { bd.newSongInstance(title: "Song \($0)", releaseDate: Date.now) }
            songs.forEach { song in
                singer.addToSongs(song)
            }
        }
        return singer
    }

    // Creates and saves a random CDataSinger instance with an optional number of songs
    @discardableResult
    func saveRandomCDataSinger(songs: Int = 0) -> CDataSinger {
        let singer = randomCDataSinger(songs: songs)
        bd.syncSave() // Save the singer and its songs to the database
        return singer
    }
}

//
// MARK: - CRUD (Create, Read, Update, Delete) Tests
//
extension CommonCoreData_SongsTests {
    // Test to ensure that deleting a singer also deletes the associated songs (cascade delete)
    @Test
    func test_cascadeDelete() async {
        guard enabled() else { return }

        bd.deleteAllSingers() // Clear all existing singers

        saveRandomCDataSinger(songs: 1) // Save a singer with one song

        // Assert that the singer and song were saved
        #expect(bd.allSingers().count == 1)
        #expect(bd.allSongs().count == 1)

        bd.deleteAllSingers() // Delete all singers

        // Assert that deleting the singer also deletes the song
        #expect(bd.allSongs().isEmpty)
        #expect(bd.allSingers().isEmpty)
    }

    // Test to save a singer with one song and verify the correct saving
    @Test
    func test_saveSingerWith1Song() async {
        guard enabled() else { return }
        bd.deleteAllSingers() // Clear all existing singers
        saveRandomCDataSinger(songs: 1) // Save a singer with one song

        // Assert that one singer and one song exist in the database
        #expect(bd.allSingers().count == 1)
        #expect(bd.allSongs().count == 1)
    }

    // Test to verify that deleting a specific singer does not affect other singers
    @Test
    func test_deleteSpecificSinger() async {
        guard enabled() else { return }
        bd.deleteAllSingers() // Clear all existing singers
        let singer1 = saveRandomCDataSinger(songs: 1) // Save the first singer
        let singer2 = saveRandomCDataSinger(songs: 2) // Save the second singer

        // Delete the first singer
        bd.deleteSinger(singer: singer1)

        // Assert that the second singer and their songs still exist
        #expect(bd.allSingers().count == 1)
        #expect(bd.allSongs().count == 2)
        #expect(bd.allSingers().first == singer2)
    }

    // Test to map a singer to a model and verify the integrity of related data
    @Test
    func test_singerMapToModel() async {
        guard enabled() else { return }
        bd.deleteAllSingers() // Clear all existing singers
        let singer: CDataSinger = saveRandomCDataSinger(songs: 1) // Save a singer with one song
        let singerModel: CoreDataSampleUsageNamespace.Singer = singer.mapToModel // Map singer to model
        let cascadeSongsCount: Int = singerModel.cascadeSongs?.count ?? 0
        // Assert the singer has one song and the mapping to model retains that relation
        #expect(singer.songs?.count == 1)
        #expect(singer.songs?.count ?? 0 == cascadeSongsCount)
        #expect(bd.allSongs().count == 1) // Assert the song exists in the database
    }

    // Test to map a song to a model and verify the inclusion or exclusion of related singer
    @Test
    func test_songMapToModel() async {
        guard enabled() else { return }
        bd.deleteAllSingers() // Clear all existing singers
        let singer: CDataSinger = saveRandomCDataSinger(songs: 1) // Save a singer with one song
        let songModelWithSinger: CoreDataSampleUsageNamespace.Song? = bd.allSongs().first?.mapToModel(cascade: true)
        let songModelWithoutSinger: CoreDataSampleUsageNamespace.Song? = bd.allSongs().first?.mapToModel(cascade: false)

        // Assert the song is correctly mapped with or without the singer relation
        #expect(singer.songs?.count == 1)
        #expect(songModelWithSinger?.cascadeSinger?.name == singer.name)
        #expect(songModelWithoutSinger?.cascadeSinger == nil)
    }

    // Test to save a singer with three songs and verify the correct saving
    @Test
    func test_saveSingerWith3Song() async {
        guard enabled() else { return }
        bd.deleteAllSingers() // Clear all existing singers
        saveRandomCDataSinger(songs: 3) // Save a singer with three songs

        // Assert that one singer and three songs exist in the database
        #expect(bd.allSingers().count == 1)
        #expect(bd.allSongs().count == 3)
    }

    // Test to delete all songs and verify that the singer still exists
    @Test
    func test_deleteSong() async {
        guard enabled() else { return }
        bd.deleteAllSingers() // Clear all existing singers
        saveRandomCDataSinger(songs: 1) // Save a singer with one song
        bd.deleteAllSongs() // Delete all songs

        // Assert that the singer exists but the song does not
        #expect(bd.allSingers().count == 1)
        #expect(bd.allSongs().isEmpty)
    }

    // Test to check performance when saving a large number of songs
    @Test
    func test_performanceSaveManySongs() async {
        guard enabled() else { return }
        bd.deleteAllSingers() // Clear all existing singers

        // `measure` (XCTest) has no Swift Testing equivalent; the assertions below
        // depend on running 10 times (measure's default iteration count), so that's
        // replicated explicitly here rather than timed.
        for _ in 0 ..< 10 {
            saveRandomCDataSinger(songs: 1000) // Save a singer with 1000 songs
        }

        #expect(bd.allSingers().count == 1 * 10)
        #expect(bd.allSongs().count == 1000 * 10)
    }

    @Test
    func test_emitEventOnDataBaseInsert() async {
        guard enabled() else { return }

        var didInsertedContent = (value: false, id: "")
        var didChangedContent = 0
        var didFinishChangeContent = 0
        let toStore = randomCDataSinger(songs: 0)
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
            bd.syncSave()
        }

        // Verify that the event is emitted
        #expect(await eventually { didFinishChangeContent == 1 })
        #expect(await eventually { didInsertedContent.value })
        #expect(await eventually { didInsertedContent.id == toStore.id })
        #expect(await eventually { didChangedContent == 1 })
    }
}
