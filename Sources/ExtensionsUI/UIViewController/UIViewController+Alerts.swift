//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

public struct AlertAction {
    public let title: String
    public let style: UIAlertAction.Style
    public let action: (() -> Void)?
}

public extension UIViewController {
    var swiftUIView: AnyView { asAnyView }
    var asAnyView: AnyView { Common_ViewControllerRepresentable { self }.erased }

    /// Safe presentation helper to ensure alerts present on the topmost VC
    private func presentSafely(_ controller: UIViewController, animated: Bool) {
        DispatchQueue.main.async {
            (Self.topViewController ?? self).present(controller, animated: animated)
        }
    }

    func alert(
        title: String?,
        message: String?,
        preferredStyle: UIAlertController.Style = .alert,
        actions: [AlertAction]
    ) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)

        for item in actions {
            let action = UIAlertAction(title: item.title, style: item.style) { _ in
                item.action?()
            }
            alertController.addAction(action)
        }

        if actions.isEmpty {
            alertController.addAction(.ok)
        }

        presentSafely(alertController, animated: true)
    }

    func showOkAlert(
        title: String = "",
        message: String,
        actionTitle: String = "OK",
        completion: (() -> Void)? = nil,
        animated: Bool = true
    ) {
        let okAction = UIAlertAction.ok(title: actionTitle) { completion?() }
        showAlertWithActions(title: title, message: message, actions: [okAction], animated: animated)
    }

    func showAlertWithActions(
        title: String,
        message: String,
        actions: [UIAlertAction],
        animated: Bool = true
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions.forEach(alert.addAction)
        presentSafely(alert, animated: animated)
    }

    static func make(
        title: String = "",
        description: String,
        action1Text: String,
        action1ButtonStyle: UIAlertAction.Style,
        action2Text: String = "Cancel",
        action2ButtonStyle: UIAlertAction.Style,
        onAction1: @escaping () -> Void,
        onAction2: @escaping () -> Void = {}
    ) -> UIAlertController {
        let alert = UIAlertController(
            title: title.isEmpty ? "Alert" : title,
            message: description,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: action1Text, style: action1ButtonStyle) { _ in onAction1() })
        alert.addAction(UIAlertAction(title: action2Text, style: action2ButtonStyle) { _ in onAction2() })

        return alert
    }
}

public extension UIAlertAction {
    static var ok: UIAlertAction {
        ok {}
    }

    static func ok(title: String = "OK", completion: @escaping () -> Void) -> UIAlertAction {
        UIAlertAction(title: title, style: .default) { _ in completion() }
    }
}
