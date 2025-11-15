//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

public extension UIView {
    func bringToFront() {
        superview?.bringSubviewToFront(self)
    }

    func sendToBack() {
        superview?.sendSubviewToBack(self)
    }

    var erased: AnyView {
        asAnyView
    }
}

public extension UIView {
    var screenHeightSafe: CGFloat {
        screenHeight - safeAreaInsets.bottom.magnitude - safeAreaInsets.top.magnitude
    }

    // Find super views of type
    func superview<T>(of type: T.Type) -> T? {
        superview as? T ?? superview?.superview(of: type)
    }

    var asAnyView: AnyView {
        Common_ViewRepresentable { self }.erased
    }

    var asImage: UIImage {
        // Prevent zero-size renderer crash
        let safeSize = CGSize(width: max(bounds.width, 1), height: max(bounds.height, 1))

        let renderer = UIGraphicsImageRenderer(size: safeSize)
        return renderer.image { _ in
            // Safer than drawHierarchy for offscreen content
            if layer.contents != nil {
                layer.render(in: UIGraphicsGetCurrentContext()!)
            } else {
                drawHierarchy(in: CGRect(origin: .zero, size: safeSize), afterScreenUpdates: true)
            }
        }
    }

    var width: CGFloat { frame.width }
    var height: CGFloat { frame.height }

    var viewController: UIViewController? {
        // Faster and safer responder-chain traversal
        sequence(first: next, next: { $0?.next })
            .compactMap { $0 as? UIViewController }
            .first
    }

    func disableUserInteractionFor(
        _ seconds: Double,
        disableAlpha: CGFloat = 1
    ) {
        guard isUserInteractionEnabled, seconds > 0 else {
            return
        }

        isUserInteractionEnabled = false
        alpha = disableAlpha

        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            self?.isUserInteractionEnabled = true
            self?.alpha = 1
        }
    }
}
