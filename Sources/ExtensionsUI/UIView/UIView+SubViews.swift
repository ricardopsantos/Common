//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import UIKit

public extension UIView {
    /// Convenience: returns all subviews recursively (any type)
    var allSubviews: [UIView] { allSubviewsRecursive() }

    func removeAllSubviewsRecursive() {
        let allViews = UIView.allSubviewsRecursive(from: self) as [UIView]

        for some in allViews {
            if let viewController = some.viewController {
                viewController.destroy()
            }
            some.removeFromSuperview()
        }
    }

    func allSubviewsWith(type: AnyClass) -> [UIView] {
        allSubviews.filter { $0.isKind(of: type) }
    }

    func allSubviewsWith(tag: Int, recursive: Bool) -> [UIView] {
        if recursive {
            UIView.allSubviewsRecursive(from: self).filter { $0.tag == tag }
        } else {
            subviews.filter { $0.tag == tag }
        }
    }

    // MARK: - Recursive Search (Generic)

    /// Recursively retrieves all subviews of type T
    class func allSubviewsRecursive<T: UIView>(from view: UIView) -> [T] {
        var result: [T] = []

        // Iterative DFS: faster and avoids deep recursion stack on large hierarchies
        var stack = view.subviews

        while !stack.isEmpty {
            let sub = stack.removeLast()

            if let match = sub as? T {
                result.append(match)
            }

            if !sub.subviews.isEmpty {
                stack.append(contentsOf: sub.subviews)
            }
        }

        return result
    }

    /// Recursively retrieves all subviews of type T (starting from self)
    func allSubviewsRecursive<T: UIView>() -> [T] {
        UIView.allSubviewsRecursive(from: self) as [T]
    }
}
