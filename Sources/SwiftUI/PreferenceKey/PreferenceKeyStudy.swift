//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

public extension Common {
    struct ColorSchemePreferenceKey: PreferenceKey {
        public static var defaultValue: ColorScheme?
        public static func reduce(value: inout ColorScheme?, nextValue: () -> ColorScheme?) {
            value = value ?? nextValue()
        }
    }

    struct IntSumPreferenceKey: PreferenceKey {
        public static var defaultValue: Int = 0
        public static func reduce(value: inout Int, nextValue: () -> Int) {
            value += nextValue()
        }
    }

    /// https://medium.com/@daviddoswell/anchor-preferences-or-lets-have-some-fun-a30f693d44f9
    struct AnchorPreferenceKey: PreferenceKey {
        public static var defaultValue: Anchor<CGRect>?
        public static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
            value = nextValue()
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
    @State private var anchorBounds: CGRect = .zero

    var body: some View {
        ScrollView {
            VStack {
                Text("Hello, World!")
                    .preference(
                        key: Common.ColorSchemePreferenceKey.self,
                        value: .light
                    ) // SET Preference
                    .background(colorScheme == .light ? Color.green : Color.red)
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
                Divider()
                anchorPreferenceView
                Spacer()
            }
            .onPreferenceChange(Common.ColorSchemePreferenceKey.self) { value in
                colorScheme = value ?? .light
                Common_Logs.debug("\(Common.ColorSchemePreferenceKey.self): \(String(describing: value))")
            }
            .onPreferenceChange(Common.IntSumPreferenceKey.self) { value in
                Common_Logs.debug("\(Common.IntSumPreferenceKey.self): \(value)")
            }
        }
    }

    /*
     Anchor Preferences allow you to read and pass layout-related data,
     such as the position or size of a view, and propagate it up the view hierarchy
     */
    var anchorPreferenceView: some View {
        Group {
            VStack {
                Text("anchorBounds: \(anchorBounds.debugDescription)")
                    .font(.caption)
                Text("AnchorPreferenceKey")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(5)
                    .anchorPreference(
                        key: Common.AnchorPreferenceKey.self,
                        value: .bounds,
                        transform: { $0 }
                    )
                GeometryReader { geometry in
                    Color.clear
                        .onPreferenceChange(Common.AnchorPreferenceKey.self) { anchor in
                            if let anchor = anchor {
                                anchorBounds = geometry[anchor]
                            }
                        }
                }
            }
        }
    }
}

//
// MARK: - Preview
//

#if canImport(SwiftUI) && DEBUG

#Preview {
    PreferenceKeyStudyTestView()
}
#endif
