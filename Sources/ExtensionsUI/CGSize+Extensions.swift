//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import UIKit

public extension CGSize {
    /// Returns a new size expanded by the specified padding.
    func addPadding(width: CGFloat, height: CGFloat) -> CGSize {
        CGSize(width: self.width + width, height: self.height + height)
    }

    /// Convenience: adds equal padding to both width and height.
    func addPadding(_ value: CGFloat) -> CGSize {
        CGSize(width: width + value, height: height + value)
    }

    /// Convenience: returns the largest side of the size.
    var maxSide: CGFloat { max(width, height) }

    /// Convenience: returns the smallest side of the size.
    var minSide: CGFloat { min(width, height) }

    /// Returns the size scaled by a factor.
    func scaled(_ factor: CGFloat) -> CGSize {
        CGSize(width: width * factor, height: height * factor)
    }
}
