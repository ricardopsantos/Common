//
//  Created by Ricardo Santos on 12/08/2024.
//

@testable import Common
import SwiftUI
import Testing

@Suite
struct AssetsTests {
    @Test
    func validImageLoadSwiftUI() {
        let validImageName = "back"
        let image: Image? = Image(validImageName, bundle: .module)
        #expect(image != nil)
    }

    // Stronger check: confirms the bitmap exists in the asset catalog
    @Test
    func validImageExistsUIKitBacked() {
        let validImageName = "back"
        let uiImage = UIImage(
            named: validImageName,
            in: .module,
            compatibleWith: nil
        )
        #expect(uiImage != nil, "Expected asset '\(validImageName)' to exist in Bundle.module")
    }
}
