//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

public extension DispatchQueue {
    static let defaultDelay: Double = Common.Constants.defaultAnimationsTime

    static func synchronizedQueue(label: String = "\(Common.self)_\(UUID().uuidString)") -> DispatchQueue {
        DispatchQueue(
            label: label,
            qos: .unspecified,
            attributes: .concurrent
        )
    }

    enum Tread {
        case main
        case background
    }

    static func executeWithDelay(tread: Tread = Tread.main, delay: Double = defaultDelay, block: @escaping () -> Void) {
        if tread == .main {
            if delay > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { block() }
            } else {
                executeInMainTread(block)
            }
        } else {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay) { block() }
        }
    }

    static func executeIn(tread: Tread, block: @escaping () -> Void) {
        if tread == .main {
            executeInMainTread(block)
        } else {
            executeInBackgroundTread(block)
        }
    }

    static func executeInMainTread(_ block: @escaping () -> Void) {
        if Thread.isMain {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }

    static func executeInBackgroundTread(_ block: @escaping () -> Void) {
        DispatchQueue.global(qos: .background).async {
            block()
        }
    }

    static func executeInUserInteractiveTread(_ block: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            block()
        }
    }
}
