//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Combine
import Foundation
import UIKit

// MARK: - UIBarButtonItem

public extension UIBarButtonItem {
    final class Subscription<SubscriberType: Subscriber, Input: UIBarButtonItem>: Combine.Subscription
        where SubscriberType.Input == Input
    {
        private var subscriber: SubscriberType?
        private weak var input: Input?

        public init(subscriber: SubscriberType, input: Input) {
            self.subscriber = subscriber
            self.input = input

            // Must use a proxy target because UIBarButtonItem does NOT retain target
            // Using self is fine because UIKit stores weak references.
            input.target = self
            input.action = #selector(eventHandler)
        }

        public func request(_: Subscribers.Demand) {
            // Backpressure is meaningless for UI events
        }

        public func cancel() {
            subscriber = nil

            // Clean up
            if let input {
                input.target = nil
                input.action = nil
            }
        }

        @objc private func eventHandler() {
            guard let input else { return }
            _ = subscriber?.receive(input)
        }
    }

    struct Publisher<Output: UIBarButtonItem>: Combine.Publisher {
        public typealias Output = Output
        public typealias Failure = Never

        private weak var output: Output?

        public init(output: Output) {
            self.output = output
        }

        public func receive<S>(subscriber: S)
            where S: Subscriber, S.Input == Output, S.Failure == Never
        {
            guard let output else {
                subscriber.receive(completion: .finished)
                return
            }
            let subscription = Subscription(subscriber: subscriber, input: output)
            subscriber.receive(subscription: subscription)
        }
    }
}
