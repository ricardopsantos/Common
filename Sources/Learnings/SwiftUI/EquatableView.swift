//
//  EquatableView.swift
//  Common
//
//  Created by Ricardo Santos on 23/09/2024.
//

import Foundation
import SwiftUI

/**
 EquatableView in SwiftUI allows you to optimize view updates by ensuring that the view only re-renders when its data changes.

 This can be useful when you have complex views where unnecessary re-rendering can impact performance. The EquatableView requires the view's underlying data to conform to Equatable.
 */

extension CommonLearnings {
    /// This is a simple Equatable model, which holds name and age.
    struct UserProfileModel: Equatable {
        let name: String
        let age: Int
    }

    /// The view shows the user’s name and age and conforms to Equatable. This ensures the view only re-renders when the user data actually changes.
    struct UserProfileView: View, Equatable {
        let user: UserProfileModel

        static func == (lhs: UserProfileView, rhs: UserProfileView) -> Bool {
            lhs.user == rhs.user
        }

        var body: some View {
            VStack {
                Text("Name: \(user.name)")
                Text("Age: \(user.age)")
            }
            .debugBackground()
            .padding()
            .cornerRadius(10)
        }
    }

    struct EquatableViewSampleUsage: View {
        @State private var user = UserProfileModel(name: "John Doe", age: 25)
        @State private var someInt = 0
        var body: some View {
            VStack {
                /// Wraps UserProfileView in EquatableView to prevent unnecessary re-renders unless the user changes.
                EquatableView(content: UserProfileView(user: user))
                UserProfileView(user: user)
                Divider()
                Button("Update User") {
                    user = UserProfileModel(name: "John Doe", age: user.age + 1)
                }
                Divider()
                Text("\(someInt)")
                Button("Update state") {
                    someInt += 1
                }
                Divider()
            }.debugBackground()
                .padding()
        }
    }
}

//
// MARK: - Preview
//

#if canImport(SwiftUI) && DEBUG
#Preview {
    CommonLearnings.EquatableViewSampleUsage()
}
#endif
