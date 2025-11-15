//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import UIKit

public extension UILabel {
    /// Smoothly animates text changes using a fade animation
    var textAnimated: String? {
        get { text }
        set {
            if text != newValue {
                fadeTransition()
                text = newValue ?? ""
            }
        }
    }

    /// Calculates label height using its current width, font, and text/attributedText
    var getHeight: CGFloat {
        // Use a label clone for correct calculation
        let measuring = UILabel(frame: CGRect(
            x: 0,
            y: 0,
            width: frame.width,
            height: .greatestFiniteMagnitude
        ))

        measuring.numberOfLines = numberOfLines
        measuring.lineBreakMode = lineBreakMode
        // swiftlint:disable random_rule_2
        measuring.font = font
        // swiftlint:enable random_rule_2
        measuring.textAlignment = textAlignment

        // Prefer attributedText when available
        if let attributedText {
            measuring.attributedText = attributedText
        } else {
            measuring.text = text
        }

        measuring.sizeToFit()
        return measuring.frame.height
    }
}

private extension UILabel {
    /// A simple fade animation to transition text changes
    func fadeTransition(_ duration: CFTimeInterval = 0.35) {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.type = .fade
        animation.duration = duration
        layer.add(animation, forKey: CATransitionType.fade.rawValue)
    }
}
