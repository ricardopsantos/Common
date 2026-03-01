//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Combine
import Foundation
import UIKit

public extension CombineCompatible {
    var touchUpInsidePublisher: AnyPublisher<UIControl, Never> {
        target.touchUpInsidePublisher
    }

    var touchDownRepeatPublisher: AnyPublisher<UIControl, Never> {
        target.touchDownRepeatPublisher
    }
}

public extension CombineCompatibleProtocol where Self: UIControl {
    // MARK: - touchUpInside

    var touchUpInsidePublisher: AnyPublisher<Self, Never> {
        Common.UIControlPublisher(
            control: self,
            events: .touchUpInside
        )
        .map { $0 } // Guaranteed safe because control == self
        .eraseToAnyPublisher()
    }

    // MARK: - touchDownRepeat

    var touchDownRepeatPublisher: AnyPublisher<Self, Never> {
        Common.UIControlPublisher(
            control: self,
            events: .touchDownRepeat
        )
        .eraseToAnyPublisher()
    }
}

// swiftlint:disable no_UIKitAdhocConstruction
private extension Common {
    func sample() {
        let btn = UIButton()

        // Built-in Combine extension style
        _ = btn.publisher(for: .touchUpInside).sinkToReceiveValue { _ in }

        // Your combine proxy
        _ = btn.combine.touchUpInsidePublisher.sinkToReceiveValue { _ in }

        // Direct extension
        _ = btn.touchUpInsidePublisher.sinkToReceiveValue { _ in }

        btn.sendActions(for: .touchUpInside)
    }
}

// swiftlint:enable no_UIKitAdhocConstruction
