//
//  UISearchTextField.swift
//  MinimalApp
//
//  Created by Ricardo Santos on 04/09/2024.
//

import UIKit

public extension UISearchTextField {
    var textAnimated: String? {
        get { text }
        set { if text != newValue {
            fadeTransition(); text = newValue ?? ""
        } }
    }

    private func fadeTransition(_ duration: CFTimeInterval = 0.5) {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.type = .fade
        animation.duration = duration
        layer.add(animation, forKey: CATransitionType.fade.rawValue)
    }
}
