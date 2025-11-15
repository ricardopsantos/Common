//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import UIKit

public extension UIView {
    static var defaultShadowColor: UIColor {
        let r: CGFloat = 80
        let g: CGFloat = 80
        let b: CGFloat = 80

        if Common.InterfaceStyle.current == .light {
            return UIColor(
                red: r / 255.0,
                green: g / 255.0,
                blue: b / 255.0,
                alpha: 1
            )
        } else {
            // Reverse color for dark mode
            return UIColor(
                red: (255 - r) / 255.0,
                green: (255 - g) / 255.0,
                blue: (255 - b) / 255.0,
                alpha: 1
            )
        }
    }

    static let defaultShadowOffset = CGSize(width: 1, height: 5) // Shadow below

    //
    // More about shadows :
    // https://medium.com/swlh/how-to-create-advanced-shadows-in-swift-ios-swift-guide-9d2844b653f8
    //

    func addShadow(
        color: UIColor = defaultShadowColor,
        offset: CGSize = defaultShadowOffset,
        radius: CGFloat = defaultShadowOffset.height,
        strength: CGFloat? = 0.95 // [0 ... 1] - The bigger, the lighter
    ) {
        let clampedRadius = max(0, radius)
        let clampedStrength = max(0, min(strength ?? 0.95, 1))

        layer.shadowColor = color.cgColor
        layer.shadowOffset = offset
        layer.shadowRadius = clampedRadius

        // Keep your original logic (1 - strength)
        layer.shadowOpacity = Float(1 - clampedStrength)

        layer.masksToBounds = false
        layer.shouldRasterize = false
    }
}

public extension CALayer {
    // Extension from:
    // https://stackoverflow.com/questions/34269399/how-to-control-shadow-spread-and-blur
    func addShadowSketch(
        color: UIColor = UIView.defaultShadowColor,
        alpha: Float = 0.5,
        x: CGFloat = 0,
        y: CGFloat = 2,
        radius: CGFloat = 4,
        spread: CGFloat = 0
    ) {
        // Ensure values are valid
        let clampedAlpha = max(0, min(alpha, 1))
        let clampedRadius = max(0, radius)
        let clampedSpread = spread

        // Optimize 1: rasterize to cache output
        shouldRasterize = true
        rasterizationScale = UIScreen.main.scale

        // Optimize 2: Avoid dynamic shadow calculation
        // Only apply shadowPath if bounds are valid (not zero)
        if bounds.width > 0, bounds.height > 0 {
            if clampedSpread == 0 {
                shadowPath = UIBezierPath(rect: bounds).cgPath
            } else {
                let dx = -clampedSpread
                let rect = bounds.insetBy(dx: dx, dy: dx)
                shadowPath = UIBezierPath(rect: rect).cgPath
            }
        }

        // Add Shadow
        shadowColor = color.cgColor
        shadowOpacity = clampedAlpha
        shadowOffset = CGSize(width: x, height: y)
        shadowRadius = clampedRadius
    }
}
