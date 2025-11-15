//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import UIKit

public typealias RJS_PresentedController = (UIViewController?, NSError?) -> Void
public typealias RJS_LoadedController = (UIViewController?, NSError?) -> Void

public extension UIViewController {
    //
    // UTILS
    //

    func disableSwipeDownToClose() {
        // https://www.hackingwithswift.com/example-code/uikit/how-to-disable-interactive-swipe-to-dismiss-for-view-controllers
        isModalInPresentation = true
    }

    var isDarkMode: Bool {
        traitCollection.userInterfaceStyle == .dark
    }

    func embeddedInNavigationController() -> UINavigationController {
        assert(
            parent == nil,
            "Cannot embed in a Navigation Controller. \(String(describing: self)) already has a parent controller."
        )
        return UINavigationController(rootViewController: self)
    }

    func dismissMe() { dismiss(options: 2) }
    func dismissAll() { dismiss(options: 1) }

    func destroy() {
        // Destroy children recursively
        for some in children {
            some.destroy()
        }

        // Proper removal sequence
        willMove(toParent: nil)

        if isViewLoaded {
            view.removeFromSuperview()
        }

        removeFromParent()

        // Remove from all notifications being observed
        NotificationCenter.default.removeObserver(self)
    }

    /// Param options = 1 : all view controllers
    /// Param options = 2 : self view controller
    func dismiss(options: Int, animated: Bool = true, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            if options == 1 {
                // Dismiss from the root presenting controller
                var presentingVC = self.presentingViewController
                while presentingVC?.presentingViewController != nil {
                    presentingVC = presentingVC?.presentingViewController
                }
                presentingVC?.dismiss(animated: animated, completion: completion)
            } else {
                // Dismiss only this VC
                if let nav = self.navigationController {
                    if nav.viewControllers.first != self {
                        nav.popViewController(animated: animated)
                        completion?()
                        return
                    }
                }

                self.dismiss(animated: animated, completion: completion)
            }
        }
    }

    func showAlert(
        title: String = "Alert",
        message: String
    ) {
        DispatchQueue.executeInMainTread {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    static func present(
        controller: UIViewController,
        sender: UIViewController,
        modalTransitionStyle: UIModalTransitionStyle = .coverVertical,
        loadedController: @escaping RJS_LoadedController = { _, _ in },
        completion: @escaping RJS_PresentedController = { _, _ in }
    ) {
        controller.modalTransitionStyle = modalTransitionStyle

        loadedController(controller, nil)

        DispatchQueue.main.async {
            sender.present(controller, animated: true) {
                completion(controller, nil)
            }
        }
    }

    static func loadViewControllerInContainedView(
        sender: UIViewController,
        senderContainedView: UIView,
        controller: UIViewController,
        adjustFrame: Bool,
        completion: RJS_PresentedController
    ) {
        senderContainedView.removeAllSubviewsRecursive()

        controller.willMove(toParent: sender)
        sender.addChild(controller)

        // Add view
        senderContainedView.addSubview(controller.view)

        if adjustFrame {
            controller.view.frame = senderContainedView.bounds
            controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }

        controller.didMove(toParent: sender)
        completion(controller, nil)
    }

    static func openAppSettings() {
        UIApplication.openAppSettings()
    }
}
