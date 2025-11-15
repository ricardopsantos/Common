//
//  Result+Extensions.swift
//  Common
//
//  Created by Ricardo Santos on 15/11/2025.
//

import Combine
@testable import Common
import Testing

@Suite(.serialized)
struct ResultExtensionsTests {
    @Test
    func testIsSuccessAndIsFailure() {
        let ok: Result<Int, TestError> = .success(10)
        let fail: Result<Int, TestError> = .failure(TestError())

        #expect(ok.isSuccess == true)
        #expect(ok.isFailure == false)

        #expect(fail.isSuccess == false)
        #expect(fail.isFailure == true)
    }

    @Test
    func testValueExtraction() {
        let ok: Result<String, TestError> = .success("hello")
        let fail: Result<String, TestError> = .failure(TestError())

        #expect(ok.value == "hello")
        #expect(fail.value == nil)
    }

    @Test
    func testErrorExtraction() {
        let ok: Result<Int, TestError> = .success(1)
        let err = TestError()
        let fail: Result<Int, TestError> = .failure(err)

        #expect(ok.error == nil)
        #expect(fail.error != nil)
        #expect(fail.error as? TestError == err)
    }

    @Test
    func testErrorMessage() {
        struct MyErr: Error, CustomStringConvertible {
            let description: String
        }

        let ok: Result<Int, MyErr> = .success(1)
        let fail: Result<Int, MyErr> = .failure(MyErr(description: "boom"))

        #expect(ok.errorMessage == "")
        #expect(fail.errorMessage.contains("boom"))
    }
}
