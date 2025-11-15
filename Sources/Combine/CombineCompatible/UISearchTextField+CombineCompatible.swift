//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Combine
import Foundation
import UIKit

public extension CombineCompatible {
    var editingChangedPublisher: AnyPublisher<String?, Never> {
        if let target = target as? UISearchTextField {
            target.valueChangedPublisher
        } else {
            AnyPublisher.never()
        }
    }

    var textDidChangePublisher: AnyPublisher<String?, Never> {
        if let target = target as? UISearchTextField {
            target.textDidChangePublisher
        } else {
            AnyPublisher.never()
        }
    }
}

public extension UISearchTextField {
    var textDidChangeNotificationPublisher: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(
            for: UISearchTextField.textDidChangeNotification,
            object: self
        )
    }

    var textDidChangePublisher: AnyPublisher<String?, Never> {
        textDidChangePublisherRegularDebounce
    }

    var textDidChangePublisherSmallDebounce: AnyPublisher<String?, Never> {
        textDidChangeNotificationPublisher
            .compactMap { ($0.object as? UISearchTextField)?.text }
            .map { Optional($0) }
            .debounce(for: .milliseconds(Self.smallDebounce), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }

    var textDidChangePublisherRegularDebounce: AnyPublisher<String?, Never> {
        textDidChangeNotificationPublisher
            .compactMap { ($0.object as? UISearchTextField)?.text }
            .map { Optional($0) }
            .debounce(for: .milliseconds(Self.regularDebounce), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }

    var textDidChangePublisherBigDebounce: AnyPublisher<String?, Never> {
        textDidChangeNotificationPublisher
            .compactMap { ($0.object as? UISearchTextField)?.text }
            .map { Optional($0) }
            .debounce(for: .milliseconds(Self.bigDebounce), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
}

public extension CombineCompatibleProtocol where Self: UISearchTextField {
    var valueChangedPublisher: AnyPublisher<String?, Never> {
        editingChangedPublisherRegularDebounce
    }

    var editingChangedPublisherSmallDebounce: AnyPublisher<String?, Never> {
        Common.UIControlPublisher(control: self, events: [.editingChanged])
            .map(\.text)
            .debounce(for: .milliseconds(Self.smallDebounce), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }

    var editingChangedPublisherRegularDebounce: AnyPublisher<String?, Never> {
        Common.UIControlPublisher(control: self, events: [.editingChanged])
            .map(\.text)
            .debounce(for: .milliseconds(Self.regularDebounce), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }

    var editingChangedPublisherBigDebounce: AnyPublisher<String?, Never> {
        Common.UIControlPublisher(control: self, events: [.editingChanged])
            .map(\.text)
            .debounce(for: .milliseconds(Self.bigDebounce), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
}

private extension UISearchTextField {
    static var smallDebounce = 250
    static var regularDebounce = smallDebounce * 2
    static var bigDebounce = smallDebounce * 4 // FIXED (was *2)
}

private extension Common {
    func sample() {
        let search = UISearchTextField()

        _ = search.textDidChangePublisher.sinkToReceiveValue { _ in }
        _ = search.combine.editingChangedPublisher.sinkToReceiveValue { _ in }

        _ = search.textDidChangePublisher.sinkToReceiveValue { _ in }
        _ = search.combine.textDidChangePublisher.sinkToReceiveValue { _ in }

        search.sendActions(for: .editingChanged)
    }
}
