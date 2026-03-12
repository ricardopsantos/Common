//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import UIKit
import Foundation
import SwiftUI
import Combine

// https://benlmyers.medium.com/9-swiftui-hacks-for-beautiful-views-cd9682fbe2ec

/**
 Embedding a view with lots of modifiers, repeated subviews, or animations can cause some lag. Luckily, one modifer can help fix your speed issues: .drawingGroup().

 This view modifier turns the view’s content into an image before rendering. There’s also another modifier you can use, compositingGroup().
 This modifier takes the effects of modifiers like opacity() or blendMode() and applies them after rendering the contents of a view.
 This is a neat modifier that you can use when you want to render several opaque views without overlap:
 */
public extension CommonLearnings {
    struct UseDrawingGroupToSpeedUpView: View {
        let useCompositingGroup: Bool
        let useDrawingGroup: Bool

        public var body: some View {
            content
                .doIf(useDrawingGroup, transform: {
                    $0.drawingGroup()
                })
        }

        var content: some View {
            VStack {
                ZStack {
                    Text("DrawingGroup")
                        .foregroundColor(.black)
                        .padding(20)
                        .background(Color.red)
                    Text("DrawingGroup")
                        .blur(radius: 2)
                }
                .font(.title)
                .doIf(useCompositingGroup, transform: {
                    $0.compositingGroup()
                })
                .opacity(1.0)
            }
            .background(Color.white)
        }
    }
}

//
// MARK: - Preview
//

#if canImport(SwiftUI) && DEBUG

#Preview {
    VStack {
        CommonLearnings.UseDrawingGroupToSpeedUpView(
            useCompositingGroup: false,
            useDrawingGroup: false
        ).renderTimeTracker()
        CommonLearnings.UseDrawingGroupToSpeedUpView(
            useCompositingGroup: true,
            useDrawingGroup: true
        ).renderTimeTracker()
    }
}
#endif
