//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import UIKit

public extension UISwitch {
    /// Simulates a real user tap on the switch.
    /// - Parameters:
    ///   - animated: Whether to animate the toggle.
    func doTouchUpInside(animated: Bool = true) {
        // 1. Toggle the value (what the user actually does)
        setOn(!isOn, animated: animated)

        // 2. Send the UIControl events normally dispatched during UI interaction
        sendActions(for: .valueChanged)
        sendActions(for: .touchUpInside)
    }
}
