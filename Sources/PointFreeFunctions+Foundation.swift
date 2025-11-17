//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

// MARK: - Weak Reference Wrapper

public final class Weak<T: AnyObject> {
    public weak var value: T?
    public init(_ value: T?) { self.value = value }
}
