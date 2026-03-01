//
//  ModelDtoTests.swift
//  Common
//
//  Created by Ricardo Santos on 15/11/2025.
//

@testable @preconcurrency import Common
import Foundation
import Testing

@Suite(.serialized)
struct ModelDtoTests {
    // MARK: String

    @Test
    func testStringConformsToModelDtoProtocol() {
        let value = "Hello"
        #expect(value.description == "Hello")
        #expect(value == "Hello") // Equatable
    }

    // MARK: [String]

    @Test
    func testArrayDescription() {
        let value = ["A", "B", "C"]
        #expect(value.description == "[A, B, C]")
    }

    @Test
    func testArrayEquatable() {
        let a = ["one", "two"]
        let b = ["one", "two"]
        let c = ["two", "one"]

        #expect(a == b)
        #expect(a != c)
    }

    @Test
    func testArrayHashable() {
        let a = ["x", "y"]
        let b = ["x", "y"]

        var hasher1 = Hasher()
        var hasher2 = Hasher()

        a.hash(into: &hasher1)
        b.hash(into: &hasher2)

        #expect(hasher1.finalize() == hasher2.finalize())
    }

    @Test
    func testArrayCodable() throws {
        let original: [String] = ["Swift", "Framework"]
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode([String].self, from: encoded)

        #expect(decoded == original)
    }

    @Test
    func testSendableConformance() async {
        let value: [String] = ["a", "b"]
        await withCheckedContinuation { continuation in
            Task.detached {
                _ = value // must be Sendable
                continuation.resume()
            }
        }
    }
}
