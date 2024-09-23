//
//  ScreenRotateHandingView.swift
//  Common
//
//  Created by Ricardo Santos on 23/09/2024.
//

import Foundation
import SwiftUI

/**
 https://paigeshin1991.medium.com/simplifying-swiftui-layout-switching-hstack-vs-vstack-3bf056cc1b76

 HStack and VStack are fundamental for arranging views horizontally and vertically, respectively.

 However, sometimes you need to switch between them dynamically

 */
public extension CommonLearnings {
    struct LoginActionsView: View {
        public var body: some View {
            Group {
                Button("Login") {}
                Button("Reset password") {}
                Button("Create account") {}
            }
        }
    }
}

//
// MARK: - Approach 1: GeometryReader
//
public extension CommonLearnings {
    struct DynamicStackV1<Content: View>: View {
        let content: () -> Content
        public init(@ViewBuilder content: @escaping () -> Content) {
            self.content = content
        }

        public var body: some View {
            GeometryReader { proxy in
                Group {
                    if proxy.size.width > proxy.size.height {
                        HStack {
                            content()
                        }.background(Color.red)
                    } else {
                        VStack {
                            content()
                        }.background(Color.green)
                    }
                }
            }
        }
    }
}

//
// MARK: - Approach 2: Size Classes
//

public extension CommonLearnings {
    struct DynamicStackV2<Content: View>: View {
        let content: () -> Content
        public init(@ViewBuilder content: @escaping () -> Content) {
            self.content = content
        }

        @Environment(\.horizontalSizeClass) private var sizeClass
        public var body: some View {
            switch sizeClass {
            case .regular:
                HStack {
                    content()
                }.background(Color.red)
            case .compact, .none:
                VStack {
                    content()
                }.background(Color.green)
            @unknown default:
                VStack {
                    content()
                }.background(Color.green)
            }
        }
    }
}

//
// MARK: - Approach 3: ViewThatFits (iOS 16)
//

struct DynamicStackV3<Content: View>: View {
    let content: () -> Content
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    /// `ViewThatFits` view type to automatically pick the best layout. By providing both HStack and
    /// VStack as candidates, it will select the one that fits the context.
    var body: some View {
        ViewThatFits {
            HStack { content() }
            VStack { content() }
        }
    }
}

//
// MARK: - Preview
//

#if canImport(SwiftUI) && DEBUG

#Preview("DynamicStackV1") {
    CommonLearnings.DynamicStackV1 {
        CommonLearnings.LoginActionsView()
    }
}

#Preview("DynamicStackV2") {
    CommonLearnings.DynamicStackV2 {
        CommonLearnings.LoginActionsView()
    }
}

#Preview("DynamicStackV3") {
    CommonLearnings.DynamicStackV2 {
        CommonLearnings.LoginActionsView()
    }
}
#endif
