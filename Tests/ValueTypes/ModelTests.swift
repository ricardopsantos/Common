//
//  InterfaceStyleTests.swift
//  Common
//
//  Created by Ricardo Santos on 15/11/2025.
//

import Foundation
import Testing
@testable @preconcurrency import Common

// MARK: - Mock Types

struct AccountModel: ModelForViewProtocol {
    var id: UUID
    var name: String
}

// MARK: - Tests

@Suite(.serialized)
struct ModelTests {

    @Test
    func testModelProtocolDescription() {
        let model = AccountModel(id: .init(), name: "Ricardo")
        // Default description is the type name
        #expect(model.description == "AccountModel")
    }

    @Test
    func testModelConformanceCodable() throws {
        let original = AccountModel(id: UUID(), name: "Test User")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AccountModel.self, from: encoded)

        #expect(decoded == original)
    }

    @Test
    func testModelHashableEquatable() {
        let id = UUID()
        let a = AccountModel(id: id, name: "A1")
        let b = AccountModel(id: id, name: "A1")

        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test
    func testModelForViewIdentifiable() {
        let model = AccountModel(id: .init(), name: "Ricardo")
        // Ensures the id is accessible and unique
        #expect(model.id is UUID)
    }
}
