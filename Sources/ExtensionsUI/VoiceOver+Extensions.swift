//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import UIKit

public extension UIView {
    func enableVoiceOver() {
        accessibilityElementsHidden = false
    }

    func disableVoiceOver() {
        accessibilityElementsHidden = true
    }

    var voiceOver: String {
        get { accessibilityLabel ?? "" }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                accessibilityLabel = trimmed
            }
        }
    }

    var voiceOverHint: String {
        get { accessibilityHint ?? "" }
        set {
            accessibilityHint = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    var voiceOverIsEnabled: Bool {
        get { isAccessibilityElement }
        set { isAccessibilityElement = newValue }
    }

    func setupAccessibilityWith(voiceOver: String, voiceOverHint: String = "") {
        let trimmedLabel = voiceOver.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedHint = voiceOverHint.trimmingCharacters(in: .whitespacesAndNewlines)

        self.voiceOver = trimmedLabel
        self.voiceOverHint = trimmedHint

        // Mark the view as an accessibility element only if it should be interacted with
        if self is UIControl || self is UILabel || self is UIImageView {
            isAccessibilityElement = true
        }

        if let btn = self as? UIButton {
            btn.accessibilityTraits = .button
        }

        if let lbl = self as? UILabel {
            lbl.accessibilityTraits = .staticText
        }
    }
}

public extension UIBarButtonItem {
    var voiceOver: String {
        get { accessibilityLabel ?? "" }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                accessibilityLabel = trimmed
            }
        }
    }

    var voiceOverHint: String {
        get { accessibilityHint ?? "" }
        set {
            accessibilityHint = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    var voiceOverIsEnabled: Bool {
        get { isAccessibilityElement }
        set { isAccessibilityElement = newValue }
    }
}
