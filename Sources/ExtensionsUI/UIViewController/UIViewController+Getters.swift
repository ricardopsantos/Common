//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import UIKit

public extension UIViewController {
    // MARK: - Top View Controller

    var topViewController: UIViewController? {
        Self.topViewController
    }

    /// The visible top-most UIViewController across all active scenes/windows.
    static var topViewController: UIViewController? {
        UIApplication.topViewController()
    }

    // MARK: - Visibility

    /// Whether the view is loaded AND actually visible on screen.
    var isVisible: Bool {
        isViewLoaded && view.window != nil
    }

    // MARK: - Accessibility

    /// Future-proof generic identifier for automated testing / accessibility tooling.
    var genericAccessibilityIdentifier: String {
        let name = String(describing: type(of: self))
        return "accessibilityIdentifierPrefix.\(name)"
    }

    // MARK: - Application Loaded Controllers (Flat)

    static var applicationLoadedViewControllers: (
        tabBarControllers: [UITabBarController],
        navigationControllers: [UINavigationController],
        viewControllers: [UIViewController]
    ) {
        let all = applicationLoadedViewControllersAndLevels
        return (
            all.tabBarControllers.map(\.controller),
            all.navigationControllers.map(\.controller),
            all.viewControllers.map(\.controller)
        )
    }

    // MARK: - Application Loaded Controllers (With Levels)

    /// Returns all view controllers loaded into the active UIWindow hierarchy.
    ///
    /// Fully updated to support:
    /// - Multiple scenes
    /// - Multiple windows
    /// - Correct recursion order
    /// - Presented controllers + embedded hierarchies
    static var applicationLoadedViewControllersAndLevels: (
        tabBarControllers: [(controller: UITabBarController, level: Int)],
        navigationControllers: [(controller: UINavigationController, level: Int)],
        viewControllers: [(controller: UIViewController, level: Int)]
    ) {
        // Use *all* key windows in case app uses multiple scenes.
        let rootViewControllers = UIApplication
            .shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .filter(\.isKeyWindow)
            .compactMap(\.rootViewController)

        var all: [(vc: UIViewController, level: Int)] = []
        var tabs: [(UITabBarController, Int)] = []
        var navs: [(UINavigationController, Int)] = []
        var vcs: [(UIViewController, Int)] = []

        // Recursively collect all view controllers in the hierarchy
        func traverse(_ viewController: UIViewController, level: Int) {
            all.append((viewController, level))

            // UINavigationController
            if let nav = viewController as? UINavigationController {
                for vc in nav.viewControllers {
                    traverse(vc, level: level + 1)
                }
            }

            // UITabBarController
            else if let tab = viewController as? UITabBarController {
                for vc in tab.viewControllers ?? [] {
                    traverse(vc, level: level + 1)
                }
            }

            // Presented controller
            if let presented = viewController.presentedViewController {
                traverse(presented, level: level + 1)
            }

            // Child view controllers (contained)
            for child in viewController.children {
                traverse(child, level: level + 1)
            }
        }

        // Handle all scene windows
        for root in rootViewControllers {
            traverse(root, level: 0)
        }

        // Classify
        for (vc, level) in all {
            switch vc {
            case let t as UITabBarController:
                tabs.append((t, level))
            case let n as UINavigationController:
                navs.append((n, level))
            default:
                vcs.append((vc, level))
            }
        }

        // Sort by depth
        tabs.sort { $0.1 < $1.1 }
        navs.sort { $0.1 < $1.1 }
        vcs.sort { $0.1 < $1.1 }

        return (tabs, navs, vcs)
    }
}
