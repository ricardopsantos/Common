//
//  Created by Ricardo Santos on 12/08/2024.
//

import XCTest
import Foundation
import Combine
import SwiftUI
//
import Nimble
//
@testable import Common
class Assets_Tests: XCTestCase {
    func enabled() -> Bool {
        true
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        TestsGlobal.loadedAny = nil
        TestsGlobal.cancelBag.cancel()
    }

    func test_validImageLoad() {
        let validImageName = "back"
        let image: Image? = Image(validImageName, bundle: Bundle.module)
        XCTAssert(image != nil)
    }
}
