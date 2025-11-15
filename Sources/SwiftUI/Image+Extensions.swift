//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import SwiftUI
import UIKit

// MARK: - Convenience modifiers

public extension Image {
    /// Applies `.resizable()` and a content mode.
    @inlinable
    func contentMode(_ mode: ContentMode) -> some View {
        resizable().aspectRatio(contentMode: mode)
    }

    /// Tints a template image with a SwiftUI Color.
    @inlinable
    func tint(color: Color) -> some View {
        renderingMode(.template).foregroundColor(color)
    }

    /// Resizes an image to a specific width/height.
    @inlinable
    func resize(width: CGFloat, height: CGFloat, alignment: Alignment = .center) -> some View {
        resizable()
            .frame(width: width, height: height, alignment: alignment)
    }

    /// Resizes an image to a CGSize.
    @inlinable
    func resize(size: CGSize, alignment: Alignment = .center) -> some View {
        resizable()
            .frame(width: size.width, height: size.height, alignment: alignment)
    }
}

// MARK: - System images shortcuts

public extension Image {
    /// Filled heart – consistent with iOS design.
    static var systemHeart: Image {
        Image(systemName: "heart.fill")
    }

    /// Asia/Australia globe icon.
    static var globe: Image {
        Image(systemName: "globe.asia.australia.fill")
    }
}
