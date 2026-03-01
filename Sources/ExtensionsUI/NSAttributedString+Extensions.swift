//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import UIKit

//
// NSAttributedString Unveiled
// https://medium.com/swlh/nsattributedstring-unveiled-6c8fb5dce86a
//

//
// Rendering Attributed Strings in SwiftUI
// https://medium.com/makingtuenti/rendering-attributed-strings-in-swiftui-8a49f6cf2315
//

public extension NSMutableAttributedString {
    /// Replaces all font faces in the attributed string with the given font family,
    /// preserving symbolic traits (bold, italic, etc.) and optionally recoloring.
    func setFontFace(font: UIFont, color: UIColor? = nil) {
        beginEditing()

        enumerateAttribute(.font, in: NSRange(location: 0, length: length)) { value, range, _ in
            guard
                let existingFont = value as? UIFont,
                let newDescriptor = existingFont.fontDescriptor
                .withFamily(font.familyName)
                .withSymbolicTraits(existingFont.fontDescriptor.symbolicTraits)
            else {
                return
            }

            let newFont = UIFont(descriptor: newDescriptor, size: font.pointSize)

            removeAttribute(.font, range: range)
            addAttribute(.font, value: newFont, range: range)

            if let color {
                removeAttribute(.foregroundColor, range: range)
                addAttribute(.foregroundColor, value: color, range: range)
            }
        }

        endEditing()
    }
}

public extension NSAttributedString {
    /// Returns a copy of the attributed string with a specific substring recolored.
    /// If the substring doesn't exist, returns the original string unchanged.
    func setColor(_ color: UIColor, on substring: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(attributedString: self)

        let nsString = string as NSString
        let range = nsString.range(of: substring)

        guard range.location != NSNotFound else {
            return self // substring not found → return original
        }

        attributedString.addAttribute(.foregroundColor, value: color, range: range)
        return attributedString
    }
}
