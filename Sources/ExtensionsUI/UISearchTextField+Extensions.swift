//
//  UISearchTextField+Extensions.swift
//  MinimalApp
//
//  Created by Ricardo Santos on 04/09/2024.
//

import UIKit

public extension UISearchTextField {
    var textAnimated: String? {
        get { text }
        set {
            guard text != newValue else { return }
            fadeTransition()
            text = newValue ?? ""
        }
    }

    private func fadeTransition(_ duration: CFTimeInterval = 0.5) {
        let animation = CATransition()
        animation.type = .fade
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(animation, forKey: CATransitionType.fade.rawValue)
    }
}
