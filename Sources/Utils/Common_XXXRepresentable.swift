//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

//
// https://finsi-ennes.medium.com/how-to-use-live-previews-in-uikit-204f028df3a9
// https://swiftwithmajid.com/2021/03/10/mastering-swiftui-previews/
//

public extension Common {
    struct ViewControllerRepresentable: UIViewControllerRepresentable {
        let viewControllerBuilder: () -> UIViewController

        public init(_ viewControllerBuilder: @escaping () -> UIViewController) {
            self.viewControllerBuilder = viewControllerBuilder
        }

        public func makeUIViewController(context _: Context) -> some UIViewController {
            let vc = viewControllerBuilder()
            // vc.modalPresentationStyle = .overCurrentContext
            return vc
        }

        public func updateUIViewController(_: UIViewControllerType, context _: Context) {
            // Not needed
        }
    }

    struct ViewRepresentable1: UIViewRepresentable {
        let view: UIView
        public init(view: UIView) {
            self.view = view
        }

        public init(closure: () -> (UIView)) {
            view = closure()
        }

        public func makeUIView(context _: Context) -> UIView {
            view
        }

        public func updateUIView(_: UIView, context _: Context) {}
    }

    struct ViewRepresentable2: UIViewRepresentable {
        let viewBuilder: () -> UIView
        public init(_ viewBuilder: @escaping () -> UIView) {
            self.viewBuilder = viewBuilder
        }

        public func makeUIView(context _: Context) -> some UIView {
            viewBuilder()
        }

        public func updateUIView(_: UIViewType, context _: Context) {
            // Not needed
        }
    }
}

//

// MARK: - Preview

//

enum Commom_Previews_ViewControllerRepresentable {
    class SampleVC: UIViewController {
        override func viewDidLoad() {
            super.viewDidLoad()
            let imageView = UIImageView()
            view.addSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                imageView.widthAnchor.constraint(equalTo: view.widthAnchor),
                imageView.heightAnchor.constraint(equalTo: view.widthAnchor),
            ])
        }
    }

    #if canImport(SwiftUI) && DEBUG
        // ViewController Preview
        #Preview("Common_ViewControllerRepresentable") {
            Common_ViewControllerRepresentable { SampleVC() }
        }

        #Preview("Common_ViewRepresentable") {
            Common_ViewRepresentable { SampleVC().view }
        }
    #endif
}
