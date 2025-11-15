//
//  RequestDtoTests.swift
//  Common
//
//  Created by Ricardo Santos on 15/11/2025.
//

@testable @preconcurrency import Common
import Foundation
import Testing

// MARK: - Mock DTO

struct LoginRequestDto: RequestDtoProtocol {
    let username: String
    let password: String
}

// MARK: - Tests

@Suite(.serialized)
struct RequestDtoTests {
    @Test
    func testDefaultDescription() {
        let dto = LoginRequestDto(username: "ricardo", password: "123")
        #expect(dto.description == "LoginRequestDto")
    }

    @Test
    func testCodable() throws {
        let original = LoginRequestDto(username: "john", password: "secret")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LoginRequestDto.self, from: data)

        #expect(decoded == original)
    }

    @Test
    func testHashableAndEquatable() {
        let a = LoginRequestDto(username: "a", password: "b")
        let b = LoginRequestDto(username: "a", password: "b")
        let c = LoginRequestDto(username: "x", password: "y")

        #expect(a == b)
        #expect(a != c)

        var hasher1 = Hasher()
        var hasher2 = Hasher()
        a.hash(into: &hasher1)
        b.hash(into: &hasher2)

        #expect(hasher1.finalize() == hasher2.finalize())
    }
}
