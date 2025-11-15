//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import UIKit

public extension UITextField {
    /// Adds left padding to the text field’s text.
    /// - Parameter left: Padding in points.
    func addTextPadding(left: CGFloat) {
        // Height will automatically adjust — using the textField bounds avoids layout issues.
        let paddingView = UIView(
            frame: CGRect(x: 0, y: 0, width: left, height: bounds.height)
        )
        leftView = paddingView
        leftViewMode = .always
    }

    /// Sets the placeholder font and optional color.
    /// - Parameters:
    ///   - font: New placeholder font.
    ///   - color: Optional placeholder color (default = system's secondaryLabel).
    func setPlaceholderFont(_ font: UIFont, color: UIColor? = nil) {
        let placeholderText = placeholder ?? ""

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color ?? UIColor.secondaryLabel,
        ]

        attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attributes)
    }
}
