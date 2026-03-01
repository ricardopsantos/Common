//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import SwiftUI

public extension UIScreen {
    static var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }

    static var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }

    static var screenSize: CGSize {
        UIScreen.main.bounds.size
    }

    // MARK: - Safe Area Insets Helpers

    private static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }

    static var safeAreaTopInset: CGFloat {
        if let inset = keyWindow?.safeAreaInsets.top {
            inset
        } else {
            // Fallback for extremely old devices or test environments
            UIDevice.isLargeOrXLarge ? 48 : 20
        }
    }

    static var safeAreaBottomInset: CGFloat {
        keyWindow?.safeAreaInsets.bottom ?? 0
    }
}
