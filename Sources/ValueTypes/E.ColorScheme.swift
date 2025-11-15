//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import UIKit

public extension Common {
    enum InterfaceStyle: String, CaseIterable {
        
        case light
        case dark
        
        // Case-insensitive initializer
        public init?(rawValue: String) {
            if let match = Self.allCases.first(where: { $0.rawValue.lowercased() == rawValue.lowercased() }) {
                self = match
            } else {
                return nil
            }
        }
        
        /// The interface style based on the system screen
        public static var current: InterfaceStyle {
            UIScreen.main.traitCollection.userInterfaceStyle == .dark ? .dark : .light
        }
        
        /// Integer mapping (kept for compatibility)
        public var intValue: Int {
            switch self {
            case .light: return 1
            case .dark: return 2
            }
        }
        
        /// Toggle between light/dark
        public var alternative: InterfaceStyle {
            self == .dark ? .light : .dark
        }
        
        /// Simple helper for testing
        public static func from(_ style: UIUserInterfaceStyle) -> InterfaceStyle {
            style == .dark ? .dark : .light
        }
    }
}
