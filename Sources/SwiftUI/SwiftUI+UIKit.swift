//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

// MARK: - UIView Auto-size Helpers

public extension UIView {
    /// Forces UIKit to recalculate intrinsicContentSize of a view and its parent.
    /// Useful when hosting dynamic SwiftUI content inside UIKit.
    func setNeedsUpdateSize(animated: Bool = false,
                            duration: TimeInterval = Common.Constants.defaultAnimationsTime)
    {
        let updateBlock = {
            self.invalidateIntrinsicContentSize()
            self.superview?.invalidateIntrinsicContentSize()
            self.layoutIfNeeded()
            self.superview?.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: duration, animations: updateBlock)
        } else {
            updateBlock()
            // Safety: run once more on next runloop to catch async SwiftUI changes.
            Common_Utils.delay { updateBlock() }
        }
    }
}

// MARK: - Hosting Controller that auto-resizes

public class SelfSizingHostingController<Content: View>: UIHostingController<Content> {
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.setNeedsUpdateSize()
    }
}

// MARK: - SwiftUI → UIView & UIViewController

public extension View {
    /// Converts a SwiftUI view to a UIViewController.
    var asViewController: UIViewController {
        if #available(iOS 16.0, *) {
            let host = UIHostingController(rootView: self)
            host.sizingOptions = [.intrinsicContentSize]
            return host
        } else {
            return SelfSizingHostingController(rootView: self)
        }
    }

    /// Converts a SwiftUI View directly into a UIView.
    var uiView: UIView {
        let controller = asViewController
        controller.view.backgroundColor = .clear
        return controller.view
    }

    /// Loads this SwiftUI view inside a UIKit view.
    func loadInside(view: UIView) {
        view.embedSwiftUIView(self)
    }

    /// Loads this SwiftUI view inside a UIViewController.
    func loadInside(viewController: UIViewController) {
        viewController.addChildSwiftUIView(self)
    }
}

// MARK: - UIView helpers for injecting SwiftUI content

public extension UIView {
    /// Embeds a SwiftUI view into this UIView using a HostingController.
    func embedSwiftUIView(_ swiftUIView: some View) {
        let controller = swiftUIView.asViewController
        guard let hostedView = controller.view else { return }

        // Important: prevent adding hosting view twice
        subviews.forEach { if $0 === hostedView { return } }

        addSubview(hostedView)
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostedView.topAnchor.constraint(equalTo: topAnchor),
            hostedView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostedView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}

// MARK: - UIViewController helpers

public extension UIViewController {
    /// Internal function — adds a child HostingController into a target view.
    private func addSwiftUIView(_ swiftUIView: some View, to container: UIView) {
        let host = swiftUIView.asViewController

        addChild(host)

        guard let hostedView = host.view else { return }
        hostedView.backgroundColor = .clear

        container.addSubview(hostedView)
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostedView.topAnchor.constraint(equalTo: container.topAnchor),
            hostedView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hostedView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        host.didMove(toParent: self)
    }

    /// Adds a SwiftUI view to a specific container UIView.
    func addChildSwiftUIView(_ swiftUIView: some View, into container: UIView) {
        addSwiftUIView(swiftUIView, to: container)
    }

    /// Adds a SwiftUI view into this controller's view.
    func addChildSwiftUIView(_ swiftUIView: some View) {
        addSwiftUIView(swiftUIView, to: view)
    }

    /// Presents a SwiftUI view modally.
    func presentSwiftUIView(
        _ swiftUIView: some View,
        modalPresentationStyle: UIModalPresentationStyle = .fullScreen,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        let host = swiftUIView.asViewController
        host.modalPresentationStyle = modalPresentationStyle
        present(host, animated: animated, completion: completion)
    }
}
