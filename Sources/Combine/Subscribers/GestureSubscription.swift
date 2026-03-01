//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

// https://jllnmercier.medium.com/combine-handling-uikits-gestures-with-a-publisher-c9374de5a478

import Combine
import Foundation
import UIKit

open class GestureSubscription<S: Subscriber>: Subscription where S.Input == GestureType, S.Failure == Never {
    private var subscriber: S?
    private var gestureType: GestureType
    private weak var view: UIView?
    private weak var gesture: UIGestureRecognizer?

    init(subscriber: S, view: UIView, gestureType: GestureType) {
        self.subscriber = subscriber
        self.view = view
        self.gestureType = gestureType
        configureGesture(gestureType)
    }

    private func configureGesture(_ gestureType: GestureType) {
        let gesture = gestureType.makeGesture()
        self.gesture = gesture
        gesture.addTarget(self, action: #selector(handler))
        view?.addGestureRecognizer(gesture)
    }

    public func request(_: Subscribers.Demand) {
        // No back-pressure for gesture events.
    }

    public func cancel() {
        subscriber = nil

        // Clean Up: remove gesture recognizer to avoid leaks
        if let gesture, let view {
            view.removeGestureRecognizer(gesture)
        }
    }

    @objc
    private func handler() {
        _ = subscriber?.receive(gestureType)
    }
}

public struct GesturePublisher: Publisher {
    public typealias Output = GestureType
    public typealias Failure = Never

    private weak var view: UIView?
    private let gestureType: GestureType

    public init(view: UIView, gestureType: GestureType) {
        self.view = view
        self.gestureType = gestureType
    }

    public func receive<S>(subscriber: S) where S: Subscriber,
        GesturePublisher.Failure == S.Failure,
        GesturePublisher.Output == S.Input
    {
        guard let view else {
            // View was deallocated → complete immediately
            subscriber.receive(completion: .finished)
            return
        }

        let subscription = GestureSubscription(
            subscriber: subscriber,
            view: view,
            gestureType: gestureType
        )
        subscriber.receive(subscription: subscription)
    }
}

public enum GestureType {
    case tap(UITapGestureRecognizer = .init())
    case swipe(UISwipeGestureRecognizer = .init())
    case longPress(UILongPressGestureRecognizer = .init())
    case pan(UIPanGestureRecognizer = .init())
    case pinch(UIPinchGestureRecognizer = .init())
    case edge(UIScreenEdgePanGestureRecognizer = .init())

    // Modern: renamed from "get()" but still exposes original "get()" for backward compatibility
    public func makeGesture() -> UIGestureRecognizer {
        switch self {
        case let .tap(tapGesture):
            return tapGesture
        case let .swipe(swipeGesture):
            return swipeGesture
        case let .longPress(longPressGesture):
            return longPressGesture
        case let .pan(panGesture):
            return panGesture
        case let .pinch(pinchGesture):
            return pinchGesture
        case let .edge(edgePanGesture):
            return edgePanGesture
        }
    }

    // Backwards compatible API (do NOT delete)
    public func get() -> UIGestureRecognizer {
        makeGesture()
    }
}

public extension UIView {
    func gesture(_ gestureType: GestureType = .tap()) -> GesturePublisher {
        isUserInteractionEnabled = true
        /**
         ```
         view.gesture(.tap()).sink { _ in
             onTap()
         }.store(in: cancelBag)
         ```
         */
        return .init(view: self, gestureType: gestureType)
    }
}
