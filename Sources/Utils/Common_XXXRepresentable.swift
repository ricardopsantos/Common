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

    // MARK: - UIKit → SwiftUI: UIViewController

    @MainActor
    struct ViewControllerRepresentable: UIViewControllerRepresentable {

        private let builder: () -> UIViewController

        public init(_ builder: @escaping () -> UIViewController) {
            self.builder = builder
        }

        public func makeUIViewController(context: Context) -> UIViewController {
            builder()
        }

        public func updateUIViewController(_: UIViewController, context _: Context) {
            // No-op
        }
    }

    // MARK: - UIKit → SwiftUI: UIView

    @MainActor
    struct ViewRepresentable: UIViewRepresentable {

        private let builder: () -> UIView

        public init(_ builder: @escaping () -> UIView) {
            self.builder = builder
        }

        public init(view: UIView) {
            self.builder = { view }
        }

        public func makeUIView(context: Context) -> UIView {
            builder()
        }

        public func updateUIView(_: UIView, context _: Context) {
            // No-op
        }
    }
}

// MARK: - Preview


#if DEBUG && canImport(SwiftUI)

fileprivate class SampleVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemYellow
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "star.fill")
        imageView.tintColor = .orange
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 100),
            imageView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
}

@available(iOS 17.0, *)
#Preview("Controller Preview") {
    Common.ViewControllerRepresentable { SampleVC() }
}

@available(iOS 17.0, *)
#Preview("View Preview") {
    Common.ViewRepresentable { SampleVC().view }
}

#endif

