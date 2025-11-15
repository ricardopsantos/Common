//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Combine
import Foundation
import SwiftUI
import UIKit

//
// Simple MVVM with @StateObject
//

//

// MARK: View

//

public extension SampleCounterDomain {
    struct SampleCounterV2_View: View {
        public typealias ViewModel = SampleCounterDomain.SampleCounter_ViewModel
        @StateObject private var viewModel: ViewModel
        public init(viewModel: @autoclosure @escaping () -> ViewModel) {
            _viewModel = StateObject(wrappedValue: viewModel())
        }

        public var body: some View {
            VStack {
                SwiftUIUtils.RenderedView("\(Self.self).\(#function)", visible: true)
                SampleCounterShared.displayView(
                    title: "ViewModel with @StateObject",
                    counterValue: $viewModel.count,
                    onTap: viewModel.increment()
                )
            }
        }
    }
}

//

// MARK: - Preview

//

#if canImport(SwiftUI) && DEBUG
    #Preview {
        SampleCounterDomain.SampleCounterV2_View(
            viewModel:
            .init(count: SampleCounterDomain.startValue)
        )
    }
#endif
