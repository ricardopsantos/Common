//
//  Created by Santos, Ricardo Patricio dos  on 02/06/2021.
//

import Foundation
import UIKit

public extension UINavigationController {
    func setNavigationBarTitleAttributes(font: UIFont, color: UIColor) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
        ]
        navigationBar.titleTextAttributes = attributes

        if #available(iOS 15.0, *) {
            let appearance = navigationBar.standardAppearance
            appearance.titleTextAttributes = attributes
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
        }
    }

    func setNavigationBarColor(_ color: UIColor) {
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()

            if color.extractAlpha < 1.0 {
                appearance.configureWithTransparentBackground()
            } else {
                appearance.configureWithOpaqueBackground()
            }

            appearance.backgroundColor = color

            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.compactAppearance = appearance
        } else {
            // Fallback for iOS < 15
            if color.extractAlpha != 1.0 {
                navigationBar.setBackgroundImage(UIImage(), for: .default)
                navigationBar.isTranslucent = true
                navigationBar.backgroundColor = color
            } else {
                navigationBar.isTranslucent = false
            }
            navigationBar.barTintColor = color
        }
    }

    func removeShadowAndHairline() {
        if #available(iOS 15.0, *) {
            let appearance = navigationBar.standardAppearance
            appearance.shadowColor = .clear
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationBar.shadowImage = UIImage()
            hideHairline()
        }
        navigationBar.layoutIfNeeded()
    }

    func restoreShadowAndHairline() {
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationBar.setBackgroundImage(nil, for: .default)
            navigationBar.shadowImage = nil
            restoreHairline()
        }
        navigationBar.layoutIfNeeded()
    }

    func hideHairline() {
        findHairlineImageViewUnder(navigationBar)?.isHidden = true
    }

    func restoreHairline() {
        findHairlineImageViewUnder(navigationBar)?.isHidden = false
    }

    func findHairlineImageViewUnder(_ view: UIView) -> UIImageView? {
        if let imageView = view as? UIImageView,
           imageView.bounds.height <= 1.0
        {
            return imageView
        }
        for subview in view.subviews {
            if let found = findHairlineImageViewUnder(subview) {
                return found
            }
        }
        return nil
    }

    func pushViewController(
        _ viewController: UIViewController,
        animated: Bool = true,
        completion: @escaping () -> Void
    ) {
        CATransaction.begin()
        CATransaction.setCompletionBlock { DispatchQueue.main.async(execute: completion) }
        pushViewController(viewController, animated: animated)
        CATransaction.commit()
    }

    func popViewController(animated: Bool = true, completion: @escaping () -> Void) {
        CATransaction.begin()
        CATransaction.setCompletionBlock { DispatchQueue.main.async(execute: completion) }
        popViewController(animated: animated)
        CATransaction.commit()
    }

    func popToRootViewController(animated: Bool = true, completion: @escaping () -> Void) {
        CATransaction.begin()
        CATransaction.setCompletionBlock { DispatchQueue.main.async(execute: completion) }
        popToRootViewController(animated: animated)
        CATransaction.commit()
    }

    func popToViewController(ofClass: AnyClass, animated: Bool = true) {
        if let vc = viewControllers.last(where: { $0.isKind(of: ofClass) }) {
            popToViewController(vc, animated: animated)
        }
    }
}
