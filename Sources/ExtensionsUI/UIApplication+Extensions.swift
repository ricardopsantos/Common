//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import SwiftUI
import UIKit

public extension UIApplication {
    func dismissKeyboard() {
        endEditing(true)
    }

    func resignFirstResponder() {
        sendAction(#selector(UIResponder.resignFirstResponder),
                   to: nil, from: nil, for: nil)
    }

    func endEditing(_ force: Bool) {
        // Ensure called on main thread
        if Thread.isMainThread {
            UIApplication.keyWindow?.endEditing(force)
        } else {
            DispatchQueue.main.async {
                UIApplication.keyWindow?.endEditing(force)
            }
        }
    }

    /// Best attempt at discovering the active window.
    static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }

    var topViewController: UIViewController? {
        UIApplication.topViewController()
    }

    /// Recursively returns the top-most view controller in the key window.
    class func topViewController(base: UIViewController? = UIApplication.keyWindow?.rootViewController)
        -> UIViewController?
    {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }

        if let tab = base as? UITabBarController,
           let selected = tab.selectedViewController
        {
            return topViewController(base: selected)
        }

        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }

        return base
    }

    var isInBackgroundOrInactive: Bool {
        switch applicationState {
        case .background, .inactive:
            true
        case .active:
            false
        @unknown default:
            false
        }
    }

    static func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
