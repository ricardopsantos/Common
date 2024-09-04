//
//  Binding+Examples.swift
//  Common
//
//  Created by Ricardo Santos on 04/09/2024.
//

import Foundation
import SwiftUI

private extension View {
    func sample1(_ action: @escaping () -> Void) -> some View {
        let isActive = Binding(
            get: { false },
            set: { newValue in if newValue {
                action()
            } }
        )
        return Group {
            if isActive.wrappedValue {
                self
            } else {
                EmptyView()
            }
        }
    }
    
    func sample2<Item>(viewModel: Binding<Item?>, @ViewBuilder destination: (Item) -> some View) -> some View {
        let isActive = Binding(
            get: {
                if let bool = viewModel.wrappedValue as? Bool {
                    return bool
                }
                return viewModel.wrappedValue != nil
            },
            set: { value in if !value {
                viewModel.wrappedValue = nil
            } }
        )
        return Group {
            if isActive.wrappedValue {
                viewModel.wrappedValue.map(destination)
            } else {
                EmptyView()
            }
        }
    }
}

private struct BindingSampleView: View {
    enum SomeEnum: String {
        case value1
        case value2
        case value3
    }
    @Binding var selected: String
    init(selected: Binding<SomeEnum?>) {
        _selected = Binding(
            get: { selected.wrappedValue?.rawValue ?? SomeEnum.value1.rawValue },
            set: { newValue in
                selected.wrappedValue = SomeEnum(rawValue: newValue)
            })
    }
    
    var body: some View {
        HStack {
            Picker("SomeEnum", selection: $selected) {
                Text("\(SomeEnum.value1.rawValue)").tag(SomeEnum.value1.rawValue)
                Text("\(SomeEnum.value2.rawValue)").tag(SomeEnum.value2.rawValue)
                Text("\(SomeEnum.value3.rawValue)").tag(SomeEnum.value3.rawValue)
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selected) { value in
                Common_Logs.debug(value)
            }
        }
    }
}
