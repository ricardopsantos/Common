//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

public extension UIFont {
    static func registerFontWithFilenameString(_ filenameString: String, _ bundleIdentifier: String) {
        if let frameworkBundle = Bundle(identifier: bundleIdentifier) {
            guard let pathForResourceString = frameworkBundle.path(forResource: filenameString, ofType: nil) else {
                assertionFailure("Not found \(filenameString)")
                return
            }
            let fontData = NSData(contentsOfFile: pathForResourceString)
            let dataProvider = CGDataProvider(data: fontData!)
            let fontRef = CGFont(dataProvider!)
            var errorRef: Unmanaged<CFError>?
            if !CTFontManagerRegisterGraphicsFont(fontRef!, &errorRef) {
                assertionFailure(
                    "Failed to register font - register graphics font failed - this font may have already been registered in the main bundle."
                )
            }
        } else {
            assertionFailure("Failed to register font - bundle identifier invalid.")
        }
    }
}
