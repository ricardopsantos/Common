//
//  UtilsTests.swift
//  Common
//
//  Created by Ricardo Santos on 15/11/2025.
//

import Combine
@testable import Common
import Foundation
import Testing

@Suite(.serialized)
struct UtilsTests {
    // MARK: - Static boolean helpers

    @Test
    func testTrueFalse() {
        #expect(Common.Utils.true)
        #expect(!Common.Utils.false)
    }

    // MARK: - Environment flags

    @Test
    func testOnUnitTests() {
        // Running under the Testing framework → unit tests are active
        #expect(Common.Utils.onUnitTests == true)
    }

    @Test
    func testOnUITestsDefaultsToFalse() {
        // Unless you explicitly set UITest env vars, this should be false in unit tests
        #expect(Common.Utils.onUITests == false)
    }

    @Test
    func testDebugFlagIsBoolean() {
        // We can't reliably assert its value (depends on build config), but we can sanity check type
        #expect(type(of: Common.Utils.onDebug) == Bool.self)
    }

    // MARK: - senderCodeId

    @Test
    func testSenderCodeIdContainsFileAndFunctionAndLine() {
        let output = Common.Utils.senderCodeId(
            "myTestFunc",
            file: "/User/Projects/Source/MyFile.swift",
            line: 123,
            showLine: true
        )

        #expect(output.contains("MyFile.swift"))
        #expect(output.contains("myTestFunc"))
        #expect(output.contains("123"))
    }

    @Test
    func testSenderCodeIdHidesLineWhenRequested() {
        let output = Common.Utils.senderCodeId(
            "myTestFunc",
            file: "/User/Projects/Source/MyFile.swift",
            line: 123,
            showLine: false
        )

        #expect(output.contains("MyFile.swift"))
        #expect(output.contains("myTestFunc"))
        #expect(!output.contains("123"))
    }

    // MARK: - assert()

    @Test
    func testCustomAssertDoesNotCrash() {
        // This should never crash, even when the condition is false
        Common.Utils.assertionFailure(message: "should not crash in tests")
        #expect(true) // If we got here, we're good
    }

    // MARK: - Thread helpers

    @Test
    func testExecuteInMainThread() async {
        await withCheckedContinuation { continuation in
            Common.Utils.executeInMainTread {
                #expect(Thread.isMainThread)
                continuation.resume()
            }
        }
    }

    @Test
    func testExecuteInBackgroundThread() async {
        await withCheckedContinuation { continuation in
            Common.Utils.executeInBackgroundTread {
                #expect(!Thread.isMainThread)
                continuation.resume()
            }
        }
    }
}
