//
//  ViewModifier.swift
//  Common
//
//  Created by Ricardo Santos on 23/09/2024.
//

import Foundation
import SwiftUI

// https://medium.com/@alessandromanilii/swiftui-custom-modifier-84ce498b0112

/**
 In SwiftUI, a `ViewModifier`  is a method that returns a new version of the view it is called on,
 with additional behaviour or appearance. View modifiers are represented by functions that have the
 `modifier` suffix, and they can be chained together to create complex and reusable views.
 */
public extension CommonLearnings {
    struct CustomModifier: ViewModifier {
        public func body(content: Content) -> some View {
            content
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
                .shadow(radius: 5)
        }
    }
}

extension View {
    func customStyle() -> some View {
        modifier(CommonLearnings.CustomModifier())
    }
}

//
// MARK: - Preview
//

#if canImport(SwiftUI) && DEBUG
#Preview {
    Text("Hello, SwiftUI!")
        .customStyle()
}
#endif
