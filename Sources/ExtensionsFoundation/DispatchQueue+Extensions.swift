//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

public extension DispatchQueue {
    /// Default delay (usually animation time)
    static let defaultDelay: Double = Common.Constants.defaultAnimationsTime

    /// Creates a synchronized queue with a unique label.
    static func synchronizedQueue(
        label: String = "\(Common.self)_\(UUID().uuidString)"
    ) -> DispatchQueue {
        DispatchQueue(
            label: label,
            qos: .unspecified,
            attributes: .concurrent
        )
    }

    /// Execution thread: main or background.
    enum Tread {
        case main
        case background
    }

    /// Executes a block after a delay on the selected thread.
    static func executeWithDelay(
        tread: Tread = .main,
        delay: Double = defaultDelay,
        block: @escaping () -> Void
    ) {
        let queue: DispatchQueue = (tread == .main) ? .main : .global(qos: .background)

        if delay > 0 {
            queue.asyncAfter(deadline: .now() + delay, execute: block)
        } else {
            executeIn(tread: tread, block: block)
        }
    }

    /// Executes a block immediately in the selected thread.
    static func executeIn(tread: Tread, block: @escaping () -> Void) {
        switch tread {
        case .main:
            executeInMainTread(block)
        case .background:
            executeInBackgroundTread(block)
        }
    }

    /// Executes on main thread, switching if needed.
    static func executeInMainTread(_ block: @escaping () -> Void) {
        Thread.isMainThread ? block() : DispatchQueue.main.async(execute: block)
    }

    /// Executes on a background thread.
    static func executeInBackgroundTread(_ block: @escaping () -> Void) {
        DispatchQueue.global(qos: .background).async(execute: block)
    }

    /// Executes on user-interactive priority background thread.
    static func executeInUserInteractiveTread(_ block: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInteractive).async(execute: block)
    }
}
