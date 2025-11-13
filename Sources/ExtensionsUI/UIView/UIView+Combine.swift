//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Combine
import Foundation
import UIKit

public extension UIView {
    class func animatePublisher(
        withDuration duration: TimeInterval,
        animations: @escaping () -> Void
    ) -> Future<Bool, Never> {
        Future { promise in
            UIView.animate(withDuration: duration, animations: animations) {
                promise(.success($0))
            }
        }
    }
}
