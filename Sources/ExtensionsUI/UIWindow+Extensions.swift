//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import UIKit

public extension UIWindow {
    /// Returns the first key window in the active foreground scene.
    /// This is safer on iOS 13+ where multiple scenes may exist.
    static var firstWindow: UIWindow? {
        UIApplication.keyWindow
    }

    /// Creates a new transparent window using a blank UIViewController.
    static var new: UIWindow {
        UIWindow.newWith(viewController: UIViewController())
    }

    /// Creates a new UIWindow using the app's main screen bounds.
    /// The window is transparent and made key & visible.
    ///
    /// - Parameter viewController: Root view controller to use.
    /// - Returns: A fully configured UIWindow instance.
    static func newWith(viewController: UIViewController) -> UIWindow {
        let window = UIWindow(frame: UIScreen.main.bounds)

        // Using `.statusBar + 1` to keep it above normal content
        // while avoiding alert-window misuse that can cause conflicts
        // with system alerts or keyboard windows.
        window.windowLevel = UIWindow.Level.statusBar + 1

        window.rootViewController = viewController
        viewController.view.backgroundColor = .clear
        window.backgroundColor = .clear

        window.makeKeyAndVisible()
        return window
    }
}
