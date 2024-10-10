//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

/**
 `PreferenceKey` is a protocol in SwiftUI that allows views to communicate data up the view hierarchy.
  It’s especially useful for situations where you need to pass data from a child view to a parent view.

  To use a `PreferenceKey`, you need to define a custom type that conforms to the protocol.
  You then use this type to define a preference value in a view hierarchy.

  Any views that are descendants of this view can then access the preference value using the @Environment property wrapper.
 */

extension CommonLearnings {
    struct PreferenceKeyStudy {}
}

//
// MARK: - Sample 1 - ChildViewWidthPreferenceKey
//
extension CommonLearnings.PreferenceKeyStudy {
    struct ChildViewWidthPreferenceKey: PreferenceKey {
        public static var defaultValue: CGFloat?
        public static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
            value = nextValue()
        }
    }

    struct Sample1_ChildView: View {
        @State var text = "Hello, SwiftUI!"
        var body: some View {
            VStack {
                Text(text)
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .preference(key: ChildViewWidthPreferenceKey.self, value: geometry.size.width)
                        }
                    )
                Button("Change Text") {
                    text = String.randomWithSpaces(Int.random(in: 10...15))
                }
            }
            .padding()
            .background(Color.yellow)
        }
    }

    struct Sample1_ParentView: View {
        @State private var childViewWidth: CGFloat = 0
        var body: some View {
            VStack {
                Sample1_ChildView()
                Text("Child Width: \(childViewWidth)")
            }
            .onPreferenceChange(ChildViewWidthPreferenceKey.self) { value in
                childViewWidth = value ?? 0
            }
            .padding()
            .background(Color.green)
        }
    }
}

//
// MARK: - Other examples
//

public extension Common {
    struct IntSumPreferenceKey: PreferenceKey {
        public static var defaultValue: Int = 0
        public static func reduce(value: inout Int, nextValue: () -> Int) {
            value += nextValue()
        }
    }

    struct MaxHeightPreferenceKey: PreferenceKey {
        public static var defaultValue: CGFloat = 0

        public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
}

//
// MARK: - Test/Usage View
//

struct PreferenceKeyStudyTestView: View {
    @State private var colorScheme: ColorScheme = .light
    @State private var myPreferenceValue: String = "123"
    @State private var frameHeight: CGFloat = 20

    var body: some View {
        ScrollView {
            VStack {
                CommonLearnings.PreferenceKeyStudy.Sample1_ParentView()
                Divider()
                Button("Increment frameHeight") {
                    frameHeight += 5
                }
                Text("Counter value: \(frameHeight)")
                    .padding()
                    .frame(height: frameHeight)
                    .background(GeometryReader { _ in
                        Color.blue.preference(
                            key: Common.IntSumPreferenceKey.self,
                            value: Int(frameHeight)
                        ) // SET Preference
                    })
                    .background(Color.red)
                Spacer()
            }
            .onPreferenceChange(Common.IntSumPreferenceKey.self) { value in
                Common_Logs.debug("\(Common.IntSumPreferenceKey.self): \(value)")
            }
        }
    }
}

//
// MARK: - Preview
//

#if canImport(SwiftUI) && DEBUG
#Preview("Examples") {
    PreferenceKeyStudyTestView()
}
#endif
