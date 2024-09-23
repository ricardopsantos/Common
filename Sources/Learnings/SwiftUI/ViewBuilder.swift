//
//  ViewBuilder.swift
//  Common
//
//  Created by Ricardo Santos on 23/09/2024.
//

import Foundation
import SwiftUI

/**
 ViewBuilder, a Swift function builder, empowers developers to create UIs with a declarative, intuitive syntax.
 It assembles multiple views into a readable structure, eliminating the need for verbose return statements. This section explores how ViewBuilder streamlines UI development, making it more efficient and user-friendly.
 */

extension CommonLearnings {
    struct ViewBuilderAsParam<Content: View>: View {
        let content: () -> Content
        public init(@ViewBuilder content: @escaping () -> Content) {
            self.content = content
        }

        public var body: some View {
            content()
        }
    }
}

//
// MARK: - Preview
//

#if canImport(SwiftUI) && DEBUG
#Preview {
    CommonLearnings.ViewBuilderAsParam {
        Text("Hi")
    }
}
#endif
