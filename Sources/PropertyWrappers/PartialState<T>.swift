//
//  PartialState.swift
//  Common
//
//  Created by Ricardo Santos on 18/09/2024.
//

import Foundation
import SwiftUI

// https://medium.com/the-swift-cooperative/tips-and-considerations-for-using-lazy-containers-in-swiftui-550ac9291a2b

public extension Common_PropertyWrappers {
    @propertyWrapper
    struct PartialState<Value: Equatable> {
        public class Storage: ObservableObject {
            var value: Value {
                didSet {
                    if oldValue != value {
                        objectWillChange.send()
                    }
                }
            }

            init(value: Value) {
                self.value = value
            }
        }

        @ObservedObject var storage: Storage

        public var wrappedValue: Value {
            get { storage.value }
            nonmutating set { storage.value = newValue }
        }

        public var projectedValue: Binding<Value> {
            Binding(
                get: { storage.value },
                set: { storage.value = $0 }
            )
        }

        public init(wrappedValue: Value) {
            self._storage = ObservedObject(wrappedValue: Storage(value: wrappedValue))
        }

        // Key structure to help track the PartialState uniquely
        public struct Key: Hashable {
            let id: ObjectIdentifier
            let keyPath: AnyKeyPath
        }
    }
}

//
// MARK: - Preview
//

#if canImport(SwiftUI) && DEBUG
public extension Common_Preview {
    struct ComplexState: Equatable {
        var name: String
        var age: Int
    }

    struct PartialStateTestViewView: View {
        @PWPartialState var partialState: ComplexState = .init(name: "", age: 0)
        @State var state: ComplexState = .init(name: "", age: 0)
        public init() {}
        public var body: some View {
            VStack {
                // swiftlint:disable line_length
                Text(
                    "When changing @State, even if the that property (name) is not used on the view, will trigger a view reload. When using @PartialState, when we change the property, and its not used on the view, no reload is trigger"
                )
                // swiftlint:enable line_length
                Spacer()
                Divider()
                Text(state.age.description)
                Text(partialState.age.description)
                Button("Change State") {
                    state.name = String.randomWithSpaces(10)
                }
                Button("Change PartialState") {
                    partialState.name = String.randomWithSpaces(10)
                }
                Spacer()
            }
            .onChange(of: _partialState.projectedValue.wrappedValue.name, perform: { newValue in
                Common_Logs.debug("\(newValue)")
            })
            // Track changes to partialState.name without triggering a view reload
            .onPartialChange(of: _partialState, at: \.name) { newValue in
                Common_Logs.debug("\(newValue)")
            }
            .debugBackground()
        }
    }
}

#Preview {
    Common_Preview.PartialStateTestViewView()
}
#endif

public extension View {
    func onPartialChange<Value: Equatable>(
        of state: Common_PropertyWrappers.PartialState<Value>,
        at keyPath: KeyPath<Value, some Equatable>,
        perform action: @escaping (Value) -> Void
    ) -> some View {
        let key = Common_PropertyWrappers.PartialState<Value>.Key(
            id: ObjectIdentifier(state.storage),

            keyPath: keyPath
        )
        return onChange(of: state.wrappedValue[keyPath: keyPath]) { _ in
            action(state.wrappedValue)
        }
        .id(key)
    }
}
