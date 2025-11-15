//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Combine
import Foundation
import UIKit

public extension CombineCompatible {
    var onTurnedOnPublisher: AnyPublisher<Bool, Never> {
        if let target = target as? UISwitch {
            target.onTurnedOnPublisher
        } else {
            AnyPublisher.never()
        }
    }

    var onChangedPublisher: AnyPublisher<Bool, Never> {
        if let target = target as? UISwitch {
            target.onChangedPublisher
        } else {
            AnyPublisher.never()
        }
    }
}

public extension CombineCompatibleProtocol where Self: UISwitch {
    /// Emits the switch `.isOn` value anytime it changes.
    var onChangedPublisher: AnyPublisher<Bool, Never> {
        Common.UIControlPublisher(control: self, events: [.valueChanged])
            .map(\.isOn)
            .eraseToAnyPublisher()
    }

    /// Emits only **when the switch turns ON** (ignores OFF).
    var onTurnedOnPublisher: AnyPublisher<Bool, Never> {
        Common.UIControlPublisher(control: self, events: [.valueChanged])
            .map(\.isOn)
            .filter { $0 == true }
            .eraseToAnyPublisher()
    }
}

// swiftlint:disable no_UIKitAdhocConstruction
private extension Common {
    func sample() {
        let switcher = UISwitch()
        switcher.isOn = false

        let submitButton = UIButton()
        submitButton.isEnabled = false

        // Enabled only when switch turns ON
        _ = switcher.onTurnedOnPublisher.assign(to: \.isEnabled, on: submitButton)

        // Same but via .combine wrapper
        _ = switcher.combine.onTurnedOnPublisher.assign(to: \.isEnabled, on: submitButton)

        switcher.isOn = true
        switcher.sendActions(for: .valueChanged)

        LogsManager.debug(submitButton.isEnabled.description, "\(Self.self)")
    }
}

// swiftlint:enable no_UIKitAdhocConstruction
